import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/lojista/lojista_service.dart';
import '../../../services/shared/auth_service.dart';
import '../../../services/shared/usuario_provider.dart';
import '../../../models/funcionario.dart';
import '../../lojista/login/widgets/card_mercado_vinculo.dart';
import 'tela_cadastro_mercado.dart';
import '../pages/tela_homepage_lojista.dart';
import '../../shared/pages/login_page.dart';
import '../../../services/lojista/lojista_provider.dart';

class TelaSelecaoMercado extends StatefulWidget {
  const TelaSelecaoMercado({super.key});

  @override
  State<TelaSelecaoMercado> createState() => _TelaSelecaoMercadoState();
}

class _TelaSelecaoMercadoState extends State<TelaSelecaoMercado> {
  final LojistaService _lojistaService = LojistaService();
  final AuthService _authService = AuthService();
  final _supabase = Supabase.instance.client;

  bool _carregando = true;
  List<Map<String, dynamic>> _vinculos = [];

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    final p = context.read<UsuarioProvider>();
    if (!p.temPerfil && _supabase.auth.currentUser != null) {
      await p.carregarPerfil();
    }
    await _carregarMercadosVinculados();
  }

  Future<void> _carregarMercadosVinculados() async {
    if (!mounted) return;
    setState(() => _carregando = true);
    try {
      final resultados = await _lojistaService.buscarMercadosPorEmail();
      if (mounted) {
        setState(() {
          _vinculos = resultados;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _fazerLogout() async {
    context.read<UsuarioProvider>().limparUsuario();
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  CargoAcesso _converterStringParaCargo(String? cargo) {
    if (cargo == null) return CargoAcesso.coletorEntregador;
    switch (cargo.toLowerCase()) {
      case 'dono':
        return CargoAcesso.dono;
      case 'gerente':
        return CargoAcesso.gerente;
      default:
        return CargoAcesso.coletorEntregador;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioProvider = context.watch<UsuarioProvider>();
    final usuario = usuarioProvider.usuario;

    // Extrai o primeiro nome do provider
    String nomeExibicao = "Lojista";
    if (usuario != null && usuario.nome.isNotEmpty) {
      nomeExibicao = usuario.nome.split(' ').first;
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
          ),
        ),
        child: Column(
          children: [
            // Header Superior com Nome e Ícone do App
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // ÍCONE DO APP
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/iconw.png',
                        width: 60, // Defina a largura
                        height: 60, // Defina a altura
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Text(
                      "MULTI KAPT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _fazerLogout,
                      icon: const Icon(Icons.logout_rounded,
                          color: Colors.redAccent, size: 18),
                      label: const Text(
                        "SAIR",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            Colors.white.withOpacity(0.05), // Fundo sutil
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Olá, $nomeExibicao!",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Selecione a unidade que deseja gerenciar hoje.",
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 18),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Área de Mercados
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "MINHAS UNIDADES",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                        letterSpacing: 1.1),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const CadastroMercadoPage()))
                                        .then((_) =>
                                            _carregarMercadosVinculados()),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text("NOVO MERCADO"),
                                    style: FilledButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 20),
                              if (_carregando)
                                const Center(
                                    child: Padding(
                                        padding: EdgeInsets.all(50),
                                        child: CircularProgressIndicator(
                                            color: Colors.black)))
                              else if (_vinculos.isEmpty)
                                _buildAvisoVazio()
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 400,
                                    mainAxisExtent: 100,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _vinculos.length,
                                  itemBuilder: (context, index) {
                                    final item = _vinculos[index];
                                    final mercadoMap = item['mercados'] as Map?;

                                    final String mercadoId =
                                        item['mercado_id']?.toString() ?? '';
                                    final String nome =
                                        mercadoMap?['nome']?.toString() ??
                                            'Mercado';
                                    final cargo = _converterStringParaCargo(
                                        item['funcao']?.toString());

                                    return CardMercadoVinculo(
                                      nomeMercado: nome,
                                      cargo: cargo,
                                      onTap: () {
                                        context
                                            .read<LojistaProvider>()
                                            .selecionarMercadoAtivo(
                                              mercadoId: mercadoId,
                                              cargo: cargo,
                                            );

                                        final user = Supabase
                                            .instance.client.auth.currentUser;
                                        if (user != null) {
                                          context
                                              .read<LojistaProvider>()
                                              .inicializar(user.id);
                                        }

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const HomePageLojista()),
                                        );
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvisoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.storefront_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("Nenhuma unidade encontrada",
                style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const Text("Cadastre seu primeiro mercado para começar.",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
