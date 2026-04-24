import 'package:flutter/material.dart';
import '../../../models/produto_enums.dart';

class DropdownCategoriaWidget extends StatelessWidget {
  final CategoriaProduto value;
  final ValueChanged<CategoriaProduto?> onChanged;

  const DropdownCategoriaWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
            "Categoria",
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        DropdownButtonFormField<CategoriaProduto>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              color: theme.colorScheme.secondary),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          items: CategoriaProduto.values.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(
                c.name.toUpperCase(),
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
