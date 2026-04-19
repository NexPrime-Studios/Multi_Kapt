import 'package:flutter/material.dart';
import 'botao_carrinho_flutuante.dart';

class BottomBarCliente extends StatelessWidget {
  final int indiceAtual;
  final Function(int) aoMudarDeAba;

  const BottomBarCliente({
    super.key,
    required this.indiceAtual,
    required this.aoMudarDeAba,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Container(
      height: 95,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D), // Preto profundo
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.4), // Sombra mais forte para o fundo escuro
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        child: BottomAppBar(
          color: const Color(0xFF0D0D0D), // Fundo preto
          elevation: 0,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _itemBarra(context, 0, Icons.home_outlined, Icons.home_rounded,
                  "Início"),
              _itemBarra(context, 1, Icons.search_rounded, Icons.search_rounded,
                  "Busca"),
              BotaoCarrinhoFlutuante(
                aoPressionar: () => aoMudarDeAba(2),
                selecionado: indiceAtual == 2,
              ),
              _itemBarra(context, 3, Icons.history_rounded,
                  Icons.history_rounded, "Pedidos"),
              _itemBarra(context, 4, Icons.person_outline_rounded,
                  Icons.person_rounded, "Perfil"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemBarra(BuildContext context, int index, IconData iconeOff,
      IconData iconeOn, String rotulo) {
    bool selecionado = indiceAtual == index;
    final ColorScheme cores = Theme.of(context).colorScheme;

    return MaterialButton(
      minWidth: 40,
      padding: EdgeInsets.zero,
      onPressed: () => aoMudarDeAba(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              // Destaque em azul neon sobre o fundo preto
              color: selecionado
                  ? cores.secondary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              selecionado ? iconeOn : iconeOff,
              color: selecionado
                  ? cores.secondary
                  : Colors.grey[600], // Ícones inativos mais discretos
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rotulo,
            style: TextStyle(
              fontSize: 10,
              color: selecionado ? cores.secondary : Colors.grey[600],
              fontWeight: selecionado ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
