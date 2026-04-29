// lib/target/lojista/widgets/sidebar_lojista.dart

import 'package:flutter/material.dart';
import 'package:mercado_app/target/shared/pages/login_page.dart';
import 'package:provider/provider.dart';
import '../../../services/lojista/lojista_provider.dart';
import '../../../services/shared/user_service.dart';

class SidebarLojista extends StatelessWidget {
  final int indiceSelecionado;
  final Function(int) aoSelecionar;

  const SidebarLojista({
    super.key,
    required this.indiceSelecionado,
    required this.aoSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    final lojistaProvider = context.watch<LojistaProvider>();
    final mercado = lojistaProvider.mercado;

    if (mercado == null) return const SizedBox.shrink();

    final totalPendentes = lojistaProvider.totalPendentes;

    return Container(
      width: 260,
      color: const Color(0xFF121212),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/iconw.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.amber,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 12), // Espaço vertical agora
                const Text(
                  'MULTI KAPT',
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 20, // Aumentei levemente a fonte
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // ITENS DO MENU
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _itemMenu(
                  context,
                  index: 0,
                  icone: Icons.shopping_basket,
                  rotulo: 'Pedidos',
                  badge: totalPendentes > 0 ? totalPendentes : null,
                ),
                _itemMenu(context,
                    index: 1, icone: Icons.store, rotulo: 'Perfil'),
                _itemMenu(context,
                    index: 2, icone: Icons.insights, rotulo: 'Métricas'),
                _itemMenu(context,
                    index: 3, icone: Icons.inventory_2, rotulo: 'Produtos'),
                _itemMenu(
                  context,
                  index: 6,
                  icone: Icons.campaign_rounded,
                  rotulo: 'Promoções',
                ),
                _itemMenu(context,
                    index: 5,
                    icone: Icons.people_alt_rounded,
                    rotulo: 'Equipe'),
                _itemMenu(context,
                    index: 4, icone: Icons.receipt_long, rotulo: 'Histórico'),
              ],
            ),
          ),

          // RODAPÉ COM STATUS E SAIR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _construirStatusLojaQuadrado(context, lojistaProvider),
                ),
                const SizedBox(width: 8),
                Expanded(child: _construirBotaoSairQuadrado(context)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _itemMenu(BuildContext context,
      {required int index,
      required IconData icone,
      required String rotulo,
      int? badge}) {
    final cores = Theme.of(context).colorScheme;
    bool selecionado = indiceSelecionado == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color:
            selecionado ? cores.secondary.withOpacity(0.1) : Colors.transparent,
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        onTap: () => aoSelecionar(index),
        leading: Icon(
          icone,
          color: selecionado ? cores.secondary : Colors.grey[500],
          size: 20,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              rotulo,
              style: TextStyle(
                color: selecionado ? Colors.white : Colors.grey[500],
                fontSize: 13,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirStatusLojaQuadrado(
      BuildContext context, LojistaProvider provider) {
    final cores = Theme.of(context).colorScheme;
    final mercado = provider.mercado!;
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: mercado.estaAberto
              ? cores.secondary.withOpacity(0.5)
              : Colors.white10,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            mercado.estaAberto ? "ONLINE" : "OFFLINE",
            style: TextStyle(
              color: mercado.estaAberto ? cores.secondary : Colors.redAccent,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 20,
            child: Transform.scale(
              scale: 0.7,
              child: Switch(
                value: mercado.estaAberto,
                activeThumbColor: cores.secondary,
                onChanged: (novoValor) => provider.alternarStatusLoja(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBotaoSairQuadrado(BuildContext context) {
    return InkWell(
      onTap: () async {
        try {
          final authService = UserService();
          await authService.signOut();

          if (context.mounted) {
            context.read<LojistaProvider>().limpar();

            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        } catch (e) {
          debugPrint("Erro ao sair: $e");
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.red[400], size: 20),
            const SizedBox(height: 4),
            const Text(
              "SAIR",
              style: TextStyle(
                color: Colors.red,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
