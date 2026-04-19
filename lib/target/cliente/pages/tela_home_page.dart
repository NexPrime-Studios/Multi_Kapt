import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/mercado.dart';
import '../../../services/cliente_service.dart';
import '../../../services/cliente_provider.dart';
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
  final ClienteService _service = ClienteService();

  void _abrirSeletorLocalizacao() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: const SeletorCidadeDashboard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final cliente = context.watch<ClienteProvider>().cliente;
    final String cidade = cliente?.cidade ?? "Edéia";
    final String estado = cliente?.estado ?? "GO";

    final double alturaDegrade = MediaQuery.of(context).size.height * 0.45;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
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
                    cores.secondary, // Azul Neon vibrante
                    cores.secondary.withOpacity(0.6),
                    Theme.of(context)
                        .scaffoldBackgroundColor, // Fundo cinza claríssimo
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),

          // 2. CONTEÚDO PRINCIPAL
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Transparente Dinâmico
              SliverAppBar(
                floating: true,
                pinned: true,
                // Aumentamos a altura para "empurrar" o conteúdo para baixo
                expandedHeight: 140,
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0, // Mantém transparente ao rolar

                // --- TOPO ESQUERDO: LOGO + NOME DO APLICATIVO ---
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/iconw.png', // Verifique se não há um espaço aqui como 'assets/ iconw.png'
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image,
                            color: Colors.white);
                      },
                    ),
                    const SizedBox(
                        width: 8), // Espaçamento entre a imagem e o texto
                    const Text(
                      "MULTI KAPT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),

                // --- TOPO DIREITO: BOTÃO DE LOCALIZAÇÃO (Glassmorphism) ---
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
                          color:
                              Colors.white.withOpacity(0.2), // Efeito de vidro
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "$cidade, $estado",
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

                // --- ABAIXO (DESCIDA): BARRA DE PESQUISA ---
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

              // LISTA DE MERCADOS REGIONAIS
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: StreamBuilder<List<Mercado>>(
                  stream: _service.buscarMercadosPorLocalizacao(
                    cidade: cidade,
                    estado: estado,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    final mercados = snapshot.data ?? [];

                    if (mercados.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront_outlined,
                                  size: 60,
                                  color: cores.primary.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text("Nenhum mercado em $cidade",
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CardMercadoPesquisa(mercado: mercados[index]),
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
