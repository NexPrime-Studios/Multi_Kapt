import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/mercado.dart';
import '../../../services/shared/usuario_service.dart';
import '../../../services/shared/user_provider.dart';
import '../widgets/card_mercado_pesquisa.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/seletor_localizacao_widget.dart';

class HomePageCliente extends StatefulWidget {
  final VoidCallback aoClicarNaBusca;

  const HomePageCliente({super.key, required this.aoClicarNaBusca});

  @override
  State<HomePageCliente> createState() => _HomePageClienteState();
}

class _HomePageClienteState extends State<HomePageCliente> {
  final UsuarioService _service = UsuarioService();

  @override
  void initState() {
    super.initState();

    // Verifica a necessidade de localização após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarLocalizacaoObrigatoria();
    });
  }

  void _verificarLocalizacaoObrigatoria() {
    final clienteProv = context.read<UserProvider>();
    if (!clienteProv.temLocalizacao) {
      _mostrarPopupSelecaoCidade();
    }
  }

  void _mostrarPopupSelecaoCidade() {
    showDialog(
      context: context,
      barrierDismissible: false, // Força a escolha para navegar
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Seja bem-vindo!"),
        content: const Text(
            "Para visualizarmos os mercados disponíveis, por favor, selecione sua cidade."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _abrirSeletorLocalizacao();
            },
            child: const Text("SELECIONAR CIDADE",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _abrirSeletorLocalizacao() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: const SeletorLocalizacaoWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final cliente = context.watch<UserProvider>().usuario;
    final localizacaoProv = context.watch<UserProvider>();

    final String cidade = cliente?.cidade ?? localizacaoProv.cidade;
    final String estado = cliente?.estado ?? localizacaoProv.estado;
    final bool temLocalizacao = cidade.isNotEmpty;

    final double alturaDegrade = MediaQuery.of(context).size.height * 0.45;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. FUNDO COM DEGRADÊ
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: alturaDegrade,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cores.secondary,
                    cores.secondary.withOpacity(0.6),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                expandedHeight: 140,
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/iconw.png',
                        height: 50, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    const Text(
                      "MULTI KAPT",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -1),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: _abrirSeletorLocalizacao,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              temLocalizacao
                                  ? "$cidade, $estado"
                                  : "Selecionar local",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 25),
                    child: SearchBarWidget(
                      readOnly: true,
                      onTap: widget.aoClicarNaBusca,
                    ),
                  ),
                ),
              ),

              // 3. LISTA DE MERCADOS
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: !temLocalizacao
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                              "Selecione uma cidade para ver os mercados.",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                        ),
                      )
                    : StreamBuilder<List<Mercado>>(
                        stream: _service.buscarMercadosPorLocalizacao(
                            cidade: cidade, estado: estado),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SliverToBoxAdapter(
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final mercados = snapshot.data ?? [];
                          if (mercados.isEmpty) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                    "Nenhum mercado encontrado em $cidade"),
                              ),
                            );
                          }

                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CardMercadoPesquisa(
                                    mercado: mercados[index]),
                              ),
                              childCount: mercados.length,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
