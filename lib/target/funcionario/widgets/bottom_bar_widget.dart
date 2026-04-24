// lib/target/funcionario/widgets/bottom_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/funcionario/funcionario_provider.dart';

class BottomBarFuncionario extends StatelessWidget {
  final int indiceAtual;
  final Function(int) aoMudarDeAba;

  const BottomBarFuncionario({
    super.key,
    required this.indiceAtual,
    required this.aoMudarDeAba,
  });

  @override
  Widget build(BuildContext context) {
    final funcProv = context.watch<FuncionarioProvider>();
    final Color primaryColor = Theme.of(context).colorScheme.secondary;

    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, -2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BottomAppBar(
          color: const Color(0xFF1A1A1A),
          elevation: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabItem(context, 0, Icons.dashboard_outlined,
                  Icons.dashboard_rounded, "Inicial"),
              _buildTabItem(
                context,
                1,
                Icons.assignment_outlined,
                Icons.assignment_rounded,
                "Pedidos",
                badge: funcProv.quantidadePedidosAtivos, //
              ),
              _buildTabItem(
                context,
                2,
                Icons.shopping_cart_checkout_outlined,
                Icons.shopping_cart_checkout_rounded,
                "Coleta",
                // Mostra o ponto apenas se houver um pedido sendo coletado
                mostrarPonto: funcProv.pedidoEmColeta != null,
              ),
              _buildTabItem(
                context,
                3,
                Icons.local_shipping_outlined,
                Icons.local_shipping_rounded,
                "Entrega",
                // Mostra o ponto apenas se houver um pedido em rota de entrega
                mostrarPonto: funcProv.pedidoEmEntrega != null,
              ),
              _buildTabItem(
                context,
                4,
                Icons.inventory_2_outlined,
                Icons.inventory_2_rounded,
                "Itens",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, IconData icon,
      IconData activeIcon, String label,
      {int? badge, bool mostrarPonto = false}) {
    final bool selecionado = indiceAtual == index;
    final Color primaryColor = Theme.of(context).colorScheme.secondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => aoMudarDeAba(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    selecionado ? activeIcon : icon,
                    color: selecionado ? primaryColor : Colors.grey[600],
                    size: 22,
                  ),
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ),
                  ),
                if (mostrarPonto)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF1A1A1A), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                  color: selecionado ? primaryColor : Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
