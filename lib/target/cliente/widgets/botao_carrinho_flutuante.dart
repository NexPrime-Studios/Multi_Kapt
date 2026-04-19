import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/carrinho_service.dart';

class BotaoCarrinhoFlutuante extends StatelessWidget {
  final VoidCallback aoPressionar;
  final bool selecionado;

  const BotaoCarrinhoFlutuante({
    super.key,
    required this.aoPressionar,
    this.selecionado = false,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;

    return Consumer<CarrinhoService>(
      builder: (context, carrinho, child) {
        int totalProdutos = carrinho.itens.length;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Botão Principal
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (selecionado ? cores.primary : cores.secondary)
                        .withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: aoPressionar,
                backgroundColor: selecionado ? cores.primary : cores.secondary,
                elevation: 0,
                shape: const CircleBorder(),
                child: const Icon(Icons.shopping_cart,
                    color: Colors.white, size: 24),
              ),
            ),

            // Badge de contagem
            if (totalProdutos > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: selecionado ? cores.secondary : cores.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  child: Text(
                    totalProdutos > 99 ? "99+" : "$totalProdutos",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
