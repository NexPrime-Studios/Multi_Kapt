import 'package:flutter/material.dart';
import '../../../models/unidade_medida_enums.dart';

class DropdownUnidadeWidget extends StatelessWidget {
  final UnidadeMedida value;
  final ValueChanged<UnidadeMedida?> onChanged;
  final bool mostrarLabel;

  const DropdownUnidadeWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.mostrarLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mostrarLabel)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              "Unidade",
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        DropdownButtonFormField<UnidadeMedida>(
          initialValue: value,
          isExpanded: true,
          icon: Icon(Icons.unfold_more, color: theme.colorScheme.secondary),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
          items: UnidadeMedida.values.map((u) {
            return DropdownMenuItem(
              value: u,
              child: Text(
                "${u.name} (${u.sigla})",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
