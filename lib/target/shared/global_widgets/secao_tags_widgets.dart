import 'package:flutter/material.dart';
import '../../../../models/produto_enums.dart';
import '../../../../models/tags_helper.dart';

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

    // IMPORTANTE: Buscamos no mapa usando o 'label' da categoria,
    // que é o que corresponde às chaves do seu TagsHelper (ex: 'Mercearia Doce')
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
                Icon(Icons.sell_outlined, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Tags: ${categoria.label}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sugestoes.map((tag) {
                  final isSelected = tagsSelecionadas.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) => onTagChanged(tag, selected),
                    selectedColor: colorScheme.secondaryContainer,
                    checkmarkColor: colorScheme.onSecondaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
            if (exibirErro)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Selecione ao menos uma tag informativa",
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
