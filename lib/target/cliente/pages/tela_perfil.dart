import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// Modelos e Providers
import '../../../models/usuario.dart';
import '../../../services/shared/usuario_provider.dart';
import '../../../services/funcionario/funcionario_provider.dart';

// Navegação
import '../../funcionario/pages/tela_selecao_modo.dart';
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

  // Controllers Dados Pessoais
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();

  // NOVOS: Controllers baseados na classe Endereco
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _complementoController = TextEditingController();

  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
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
    _cepController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _complementoController.dispose();
    super.dispose();
  }

  /// Sincroniza os controllers com os dados vindos do Provider (Objeto Usuario + Endereco)
  void _sincronizarControllers(Usuario usuario) {
    _nomeController.text = usuario.nome;
    _telefoneController.text = usuario.telefone;

    // Mapeando sub-classe Endereco para os controllers
    _cepController.text = usuario.endereco.cep;
    _ruaController.text = usuario.endereco.rua;
    _numeroController.text = usuario.endereco.numero;
    _bairroController.text = usuario.endereco.bairro;
    _cidadeController.text = usuario.endereco.cidade;
    _estadoController.text = usuario.endereco.estado;
    _complementoController.text = usuario.endereco.complemento;

    _lat = usuario.latitude;
    _lng = usuario.longitude;
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lat == null || _lng == null) {
      _mostrarMensagem("⚠️ Marque a localização no mapa!", Colors.orange);
      return;
    }

    setState(() => _salvando = true);
    try {
      final userAuth = _supabase.auth.currentUser;

      // 1. Criar o objeto de Endereço
      final novoEndereco = Endereco(
        cep: _cepController.text.trim(),
        rua: _ruaController.text.trim(),
        numero: _numeroController.text.trim(),
        bairro: _bairroController.text.trim(),
        cidade: _cidadeController.text.trim(),
        estado: _estadoController.text.trim(),
        complemento: _complementoController.text.trim(),
      );

      // 2. Criar o objeto Usuario com a nova lógica
      final usuarioAtualizado = Usuario(
        uid: userAuth!.id,
        email: userAuth.email!,
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        endereco: novoEndereco, // Objeto complexo
        cidade: _cidadeController.text
            .trim(), // Mantido por redundância se sua classe pede
        estado: _estadoController.text.trim(),
        latitude: _lat,
        longitude: _lng,
      );

      await context
          .read<UsuarioProvider>()
          .salvarEAtualizarPerfil(usuarioAtualizado);

      _mostrarMensagem("Perfil atualizado com sucesso!", Colors.green);
      setState(() => _editando = false);
    } catch (e) {
      _mostrarMensagem("Erro ao salvar: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarMensagem(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: cor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final cores = Theme.of(context).colorScheme;
    final clienteProvider = context.watch<UsuarioProvider>();
    final usuario = clienteProvider.usuario;
    final funcionarioProvider = context.watch<FuncionarioProvider>();

    if (user == null) return _buildTelaNaoLogado(cores);

    // Sincroniza campos se não estiver em modo de edição
    if (!_editando && usuario != null) {
      _sincronizarControllers(usuario);
    }

    if (usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Meu Perfil",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: cores.secondary,
        elevation: 0,
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
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTituloSecao("DADOS PESSOAIS"),
                  _buildCampo(
                      cores, "Nome Completo", _nomeController, Icons.person),
                  const SizedBox(height: 12),
                  _buildCampo(
                      cores, "WhatsApp", _telefoneController, Icons.phone,
                      isNumero: true),
                  const SizedBox(height: 24),
                  _buildTituloSecao("ENDEREÇO"),
                  Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: _buildCampo(
                              cores, "CEP", _cepController, Icons.location_on)),
                      const SizedBox(width: 8),
                      Expanded(
                          flex: 1,
                          child: _buildCampo(
                              cores, "UF", _estadoController, null)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCampo(
                      cores, "Cidade", _cidadeController, Icons.location_city),
                  const SizedBox(height: 12),
                  _buildCampo(cores, "Rua", _ruaController, Icons.map),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildCampo(
                              cores, "Número", _numeroController, null)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildCampo(
                              cores, "Bairro", _bairroController, null)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCampo(cores, "Complemento", _complementoController,
                      Icons.info_outline),
                  const SizedBox(height: 24),
                  _buildInfoMapa(cores),
                  const SizedBox(height: 32),
                  if (_editando)
                    ElevatedButton(
                      onPressed: _salvando ? null : _salvarAlteracoes,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: cores.secondary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 55)),
                      child: const Text("SALVAR ALTERAÇÕES",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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

  Widget _buildTituloSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(titulo,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildCampo(ColorScheme cores, String label,
      TextEditingController controller, IconData? icone,
      {bool isNumero = false}) {
    return TextFormField(
      controller: controller,
      enabled: _editando,
      keyboardType: isNumero ? TextInputType.phone : TextInputType.text,
      style: TextStyle(color: _editando ? Colors.black87 : Colors.black54),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icone != null
            ? Icon(icone,
                size: 20, color: _editando ? cores.secondary : Colors.grey)
            : null,
        filled: true,
        fillColor: _editando ? Colors.white : Colors.grey[200],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            color: _editando ? Colors.white : Colors.grey[200],
            border: Border.all(
                color: selecionado && _editando
                    ? cores.secondary
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.map_outlined,
                color: selecionado ? Colors.green : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selecionado
                    ? "Localização Geográfica Fixada ✓"
                    : "Toque para marcar no mapa *",
                style: TextStyle(
                    color: selecionado ? Colors.green[700] : Colors.black54,
                    fontWeight: FontWeight.w500),
              ),
            ),
            if (_editando) const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesAcao(
      User user, FuncionarioProvider fp, ColorScheme cores) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () {
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
              side: BorderSide(color: cores.secondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            context.read<UsuarioProvider>().limparUsuario();
            await context.read<FuncionarioProvider>().desvincular();
            await _supabase.auth.signOut();
          },
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text("Sair da conta",
              style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  Widget _buildTelaNaoLogado(ColorScheme cores) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle_outlined,
                  size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text("Ops! Você não está logado.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text("Acesse sua conta para gerenciar seus dados.",
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginPage())),
                child: const Text("ENTRAR AGORA"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
