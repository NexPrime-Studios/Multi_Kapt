import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../models/cliente.dart';
import '../../../services/cliente_provider.dart';
import '../../../services/funcionario_provider.dart'; // Importação necessária
import '../../funcionario/pages/selecao_modo_page.dart'; // Importação necessária
import 'mapa_selecao_page.dart';
import 'login_page_cliente.dart';
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
  bool _carregando = true;

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
    _inicializarDados();

    _supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) _inicializarDados();
    });
  }

  Future<void> _inicializarDados() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _carregando = false);
      return;
    }

    final p = context.read<ClienteProvider>();

    if (p.temPerfil) {
      _sincronizarControllers(p.cliente!);
    } else {
      await _buscarDoBanco(user.id);
    }
  }

  Future<void> _buscarDoBanco(String uid) async {
    try {
      final dados =
          await _supabase.from('clientes').select().eq('uid', uid).single();
      final cliente = Cliente.fromMap(dados);

      if (mounted) context.read<ClienteProvider>().atualizarCliente(cliente);
      _sincronizarControllers(cliente);
    } catch (e) {
      debugPrint("Erro ao carregar: $e");
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _sincronizarControllers(Cliente cliente) {
    setState(() {
      _nomeController.text = cliente.nome;
      _telefoneController.text = cliente.telefone;
      _enderecoController.text = cliente.endereco;
      _cidadeController.text = cliente.cidade;
      _estadoController.text = cliente.estado;
      _lat = cliente.latitude;
      _lng = cliente.longitude;
      _carregando = false;
    });
  }

  Future<void> _selecionarNoMapa() async {
    final LatLng? resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaMapaSelecao(
          posicaoInicial: (_lat != null && _lng != null)
              ? LatLng(_lat!, _lng!)
              : const LatLng(-23.5505, -46.6333),
        ),
      ),
    );

    if (resultado != null) {
      setState(() {
        _lat = resultado.latitude;
        _lng = resultado.longitude;
      });
    }
  }

  // lib/target/cliente/pages/tela_perfil.dart

  Future<void> _salvarAlteracoes() async {
    final cores = Theme.of(context).colorScheme;
    if (!_formKey.currentState!.validate()) return;

    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⚠️ Marque o PIN no mapa!"),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _carregando = true);
    final user = _supabase.auth.currentUser;

    try {
      // Cria o objeto com os novos dados
      final clienteAtu = Cliente(
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

      await context.read<ClienteProvider>().salvarEAtualizarPerfil(clienteAtu);

      setState(() => _editando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("Perfil atualizado!"),
            backgroundColor: cores.secondary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erro ao salvar: $e"), backgroundColor: cores.error));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final cores = Theme.of(context).colorScheme;

    final clienteProvider = context.watch<ClienteProvider>();
    final cliente = clienteProvider.cliente;

    // Monitora o status do funcionário para alternar o botão
    final funcionarioProvider = context.watch<FuncionarioProvider>();
    final bool jaEhFuncionario = funcionarioProvider.isFuncionario;

    if (!_editando && cliente != null && !_carregando) {
      bool houveMudanca = _nomeController.text != cliente.nome ||
          _cidadeController.text != cliente.cidade ||
          _enderecoController.text != cliente.endereco ||
          _telefoneController.text != cliente.telefone ||
          _lat != cliente.latitude;

      if (houveMudanca) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _sincronizarControllers(cliente);
        });
      }
    }

    if (user == null) return _buildTelaNaoLogado(cores);
    if (_carregando) {
      return Scaffold(
          body:
              Center(child: CircularProgressIndicator(color: cores.secondary)));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Dados da Conta",
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white)),
        centerTitle: true,
        backgroundColor: cores.secondary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _editando = !_editando),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(_editando ? Icons.close : Icons.edit,
                color: Colors.white, size: 16),
            label: Text(
              _editando ? "SAIR" : "EDITAR",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildSecaoTitulo(cores, "Informações Pessoais"),
              const Divider(),
              const SizedBox(height: 16),
              _buildCampo(cores, "NOME COMPLETO *", _nomeController,
                  Icons.person_outline),
              const SizedBox(height: 20),
              _buildCampo(cores, "TELEFONE *", _telefoneController,
                  Icons.phone_android_outlined,
                  isNumero: true),
              const SizedBox(height: 20),
              _buildCampo(
                cores,
                "ENDEREÇO POR EXTENSO *",
                _enderecoController,
                Icons.home_outlined,
              ),
              const SizedBox(height: 30),
              const Text("LOCALIZAÇÃO PRECISA (PIN) *",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              _buildInfoMapa(cores),
              const SizedBox(height: 40),
              if (_editando)
                ElevatedButton(
                  onPressed: _salvarAlteracoes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cores.secondary,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("SALVAR ALTERAÇÕES",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                )
              else
                Column(
                  children: [
                    // BOTÃO DINÂMICO DE FUNCIONÁRIO
                    OutlinedButton.icon(
                      onPressed: () {
                        if (jaEhFuncionario) {
                          funcionarioProvider.irParaSelecao();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const SelecaoModoPage()),
                            (route) => false,
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VinculoFuncionarioPage()),
                          );
                        }
                      },
                      icon: Icon(
                          jaEhFuncionario
                              ? Icons.swap_horiz
                              : Icons.badge_outlined,
                          color: cores.secondary),
                      label: Text(
                        jaEhFuncionario
                            ? "MUDAR PARA CONTA DE FUNCIONÁRIO"
                            : "ADICIONAR CONTA DE FUNCIONÁRIO",
                        style: TextStyle(
                          color: cores.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        side: BorderSide(color: cores.secondary, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // BOTÃO SAIR DA CONTA
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          context.read<ClienteProvider>().limparCliente();
                          _supabase.auth.signOut();
                        },
                        icon: const Icon(Icons.logout, color: Colors.grey),
                        label: const Text("Sair da conta",
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecaoTitulo(ColorScheme cores, String titulo) {
    return Row(
      children: [
        Icon(Icons.person_pin, color: cores.primary, size: 28),
        const SizedBox(width: 8),
        Text(titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCampo(ColorScheme cores, String label,
      TextEditingController controller, IconData icone,
      {bool isNumero = false, int maxLines = 1, bool habilitado = true}) {
    bool realmenteHabilitado = _editando && habilitado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: realmenteHabilitado,
          maxLines: maxLines,
          keyboardType: isNumero ? TextInputType.phone : TextInputType.text,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? "Campo obrigatório" : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icone,
                color: realmenteHabilitado ? cores.primary : Colors.grey,
                size: 20),
            filled: true,
            fillColor: realmenteHabilitado ? Colors.white : Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!)),
          ),
        ),
      ],
    );
  }

  Widget _buildTelaNaoLogado(ColorScheme cores) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_outlined,
                  size: 100, color: Colors.grey),
              const SizedBox(height: 24),
              const Text("Você não está logado",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: cores.secondary,
                    minimumSize: const Size(double.infinity, 55)),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginPageCliente())),
                child: const Text("FAZER LOGIN / CADASTRAR",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoMapa(ColorScheme cores) {
    bool selecionado = (_lat != null && _lng != null);
    return InkWell(
      onTap: _editando ? _selecionarNoMapa : null,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: _editando
              ? (selecionado
                  ? cores.secondary.withOpacity(0.05)
                  : cores.primary.withOpacity(0.05))
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: _editando
                  ? (selecionado ? cores.secondary : cores.primary)
                  : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(selecionado ? Icons.location_on : Icons.map_rounded,
                color: _editando
                    ? (selecionado ? cores.secondary : cores.primary)
                    : Colors.grey[600],
                size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selecionado ? "Localização Fixada" : "PIN não marcado",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _editando
                              ? (selecionado ? cores.secondary : cores.primary)
                              : Colors.grey[700])),
                  Text(
                      selecionado
                          ? "Coordenadas: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}"
                          : "Toque para abrir o mapa",
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
