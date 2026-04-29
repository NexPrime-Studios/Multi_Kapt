import 'package:flutter/material.dart';
import '../../../enums/produto_enums.dart';
import '../../../enums/tags_helper.dart';

class SecaoTagsWidget extends StatelessWidget {
  final CategoriaProduto categoria;
  final List<String> tagsSelecionadas;
  final bool exibirErro;
  final Function(String, bool) onTagChanged;

  const SecaoTagsWidget({
    super.key,
    required this.categoria,
    required this.tagsSelecionadas,
    required this.onTagChanged,
    this.exibirErro = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final sugestoes = TagsHelper.sugestoesPorCategoria[categoria.label] ?? [];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: exibirErro ? colorScheme.error : colorScheme.outlineVariant,
          width: exibirErro ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sell_outlined, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Tags: ${categoria.label}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sugestoes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Selecione uma categoria válida para ver as sugestões.",
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: sugestoes.map((tag) {
                  final isSelected = tagsSelecionadas.contains(tag);
                  return FilterChip(
                    // --- AJUSTES DE TAMANHO ---
                    label: Text(tag),
                    labelStyle: TextStyle(
                      fontSize: 12, // Fonte menor (padrão é ~14)
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurface,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2), // Espaço interno menor
                    visualDensity: VisualDensity
                        .compact, // Compacta o widget vertical e horizontalmente
                    materialTapTargetSize: MaterialTapTargetSize
                        .shrinkWrap, // Remove o padding extra de toque (48dp)
                    // --------------------------
                    selected: isSelected,
                    onSelected: (selected) => onTagChanged(tag, selected),
                    selectedColor: colorScheme.secondaryContainer,
                    checkmarkColor: colorScheme.onSecondaryContainer,
                    showCheckmark:
                        false, // Opcional: remover o ícone de check ganha mais espaço
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }).toList(),
              ),
            if (exibirErro)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Selecione ao menos uma tag informativa",
                  style: TextStyle(color: colorScheme.error, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
