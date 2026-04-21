import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../models/usuario.dart';
import '../../../services/usuario_provider.dart';
import '../../../services/funcionario_provider.dart';
import '../../funcionario/pages/selecao_modo_page.dart';
import '../../shared/pages/mapa_selecao_page.dart';
import '../../shared/pages/login_page.dart';
import 'vinculo_funcionario_page.dart';

class PerfilPageCliente extends StatefulWidget {
  const PerfilPageCliente({super.key});

  @override
  State<PerfilPageCliente> createState() => _PerfilPageClienteState();
}

class _PerfilPageClienteState extends State<PerfilPageCliente> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  bool _editando = false;
  bool _salvando = false;

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    // Dispara o carregamento inicial se o Provider estiver vazio e houver um usuário logado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<UsuarioProvider>();
      if (!p.temPerfil && _supabase.auth.currentUser != null) {
        p.carregarPerfil();
      }
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  void _sincronizarControllers(Usuario cliente) {
    _nomeController.text = cliente.nome;
    _telefoneController.text = cliente.telefone;
    _enderecoController.text = cliente.endereco;
    _cidadeController.text = cliente.cidade;
    _estadoController.text = cliente.estado;
    _lat = cliente.latitude;
    _lng = cliente.longitude;
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⚠️ Marque o PIN no mapa!"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final user = _supabase.auth.currentUser;
      final clienteAtu = Usuario(
        uid: user!.id,
        email: user.email!,
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim(),
        cidade: _cidadeController.text,
        estado: _estadoController.text,
        latitude: _lat,
        longitude: _lng,
      );

      await context.read<UsuarioProvider>().salvarEAtualizarPerfil(clienteAtu);
      setState(() => _editando = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final cores = Theme.of(context).colorScheme;
    final clienteProvider = context.watch<UsuarioProvider>();
    final cliente = clienteProvider.usuario;
    final funcionarioProvider = context.watch<FuncionarioProvider>();

    if (user == null) return _buildTelaNaoLogado(cores);

    if (!_editando && cliente != null) {
      _sincronizarControllers(cliente);
    }

    if (cliente == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Dados da Conta",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: cores.secondary,
        actions: [
          IconButton(
            onPressed: () => setState(() => _editando = !_editando),
            icon:
                Icon(_editando ? Icons.close : Icons.edit, color: Colors.white),
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildCampo(cores, "NOME", _nomeController, Icons.person),
                  const SizedBox(height: 16),
                  _buildCampo(
                      cores, "TELEFONE", _telefoneController, Icons.phone,
                      isNumero: true),
                  const SizedBox(height: 16),
                  _buildCampo(
                      cores, "ENDEREÇO", _enderecoController, Icons.home),
                  const SizedBox(height: 24),
                  _buildInfoMapa(cores),
                  const SizedBox(height: 32),
                  if (_editando)
                    ElevatedButton(
                      onPressed: _salvando ? null : _salvarAlteracoes,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: cores.secondary,
                          minimumSize: const Size(double.infinity, 55)),
                      child: const Text("SALVAR ALTERAÇÕES",
                          style: TextStyle(color: Colors.white)),
                    )
                  else
                    _buildBotoesAcao(user, funcionarioProvider, cores),
                ],
              ),
            ),
          ),
          if (_salvando)
            Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildBotoesAcao(
      User user, FuncionarioProvider fp, ColorScheme cores) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            // Trava de segurança: só permite prosseguir se houver um usuário autenticado no Supabase
            if (_supabase.auth.currentUser == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        "Você precisa estar logado para realizar esta ação.")),
              );
              return;
            }

            if (fp.isFuncionario) {
              fp.irParaSelecao();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SelecaoModoPage()),
                (route) => false,
              );
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const VinculoFuncionarioPage()));
            }
          },
          icon: Icon(fp.isFuncionario ? Icons.swap_horiz : Icons.badge,
              color: cores.secondary),
          label: Text(
              fp.isFuncionario
                  ? "MODO FUNCIONÁRIO"
                  : "ADICIONAR CONTA FUNCIONÁRIO",
              style: TextStyle(
                  color: cores.secondary, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              side: BorderSide(color: cores.secondary)),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            context.read<UsuarioProvider>().limparUsuario();
            await _supabase.auth.signOut();
          },
          icon: const Icon(Icons.logout, color: Colors.grey),
          label:
              const Text("Sair da conta", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  // Métodos auxiliares de UI (_buildCampo, _buildInfoMapa, _buildTelaNaoLogado) seguem o mesmo padrão visual anterior.
  Widget _buildCampo(ColorScheme cores, String label,
      TextEditingController controller, IconData icone,
      {bool isNumero = false}) {
    return TextFormField(
      controller: controller,
      enabled: _editando,
      keyboardType: isNumero ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icone, color: _editando ? cores.primary : Colors.grey),
        filled: true,
        fillColor: _editando ? Colors.white : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildInfoMapa(ColorScheme cores) {
    bool selecionado = (_lat != null && _lng != null);
    return InkWell(
      onTap: _editando
          ? () async {
              final LatLng? res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TelaMapaSelecao(
                          posicaoInicial:
                              LatLng(_lat ?? -23.5, _lng ?? -46.6))));
              if (res != null) {
                setState(() {
                  _lat = res.latitude;
                  _lng = res.longitude;
                });
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.location_on,
                color: selecionado ? cores.secondary : Colors.grey),
            const SizedBox(width: 12),
            Text(selecionado
                ? "Localização Fixada"
                : "Toque para marcar no mapa"),
          ],
        ),
      ),
    );
  }

  Widget _buildTelaNaoLogado(ColorScheme cores) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Acesse sua conta para ver o perfil",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginPage())),
                child: const Text("FAZER LOGIN")),
          ],
        ),
      ),
    );
  }
}
