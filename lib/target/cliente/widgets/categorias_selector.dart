import 'package:flutter/material.dart';
import '../../../models/produto_enums.dart';

class CategoriasSelector extends StatelessWidget {
  final List<CategoriaProduto> categorias;
  final CategoriaProduto? selecionada;
  final Function(CategoriaProduto?) onSelect;

  const CategoriasSelector({
    super.key,
    required this.categorias,
    required this.selecionada,
    required this.onSelect,
  });

  IconData _getIcone(CategoriaProduto? categoria) {
    if (categoria == null) return Icons.grid_view_rounded;
    switch (categoria) {
      case CategoriaProduto.mercearia:
        return Icons.shopping_basket_rounded;
      case CategoriaProduto.bebidas:
        return Icons.local_drink_rounded;
      case CategoriaProduto.hortifruti:
        return Icons.eco_rounded;
      case CategoriaProduto.acougue:
        return Icons.kebab_dining_rounded;
      case CategoriaProduto.padaria:
        return Icons.bakery_dining_rounded;
      case CategoriaProduto.doces:
        return Icons.icecream_outlined;
      case CategoriaProduto.limpeza:
        return Icons.cleaning_services_rounded;
      case CategoriaProduto.higiene:
        return Icons.sanitizer_rounded;
      case CategoriaProduto.frios:
        return Icons.kitchen_rounded;
      case CategoriaProduto.petshop:
        return Icons.pets_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _formatarNome(String nome) {
    if (nome.isEmpty) return "";
    return nome[0].toUpperCase() + nome.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return SizedBox(
      height: 55,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categorias.length + 1,
        itemBuilder: (context, index) {
          final isTodos = index == 0;
          final cat = isTodos ? null : categorias[index - 1];
          final isSelected = selecionada == cat;

          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 55, // Reduzido de 70 para 55 (mais estreito)
              margin: const EdgeInsets.only(right: 8, bottom: 5, top: 2),
              decoration: BoxDecoration(
                color: isSelected ? cores.secondary : Colors.white,
                borderRadius:
                    BorderRadius.circular(12), // Bordas ligeiramente menores
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIcone(cat),
                    color: isSelected ? Colors.white : Colors.black,
                    size: 20, // Ícone reduzido de 24 para 20
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTodos ? "Tudo" : _formatarNome(cat!.name),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8, // Texto reduzido de 10 para 8
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
