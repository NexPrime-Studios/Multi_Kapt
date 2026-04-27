import 'package:flutter/material.dart';
import '../../../../models/produto_enums.dart';

class DropdownCategoriaWidget extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final bool temErro;

  const DropdownCategoriaWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.temErro = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    List<String> itensSensiveis =
        CategoriaProduto.values.map((e) => e.label).toList();

    if (!itensSensiveis.contains("Selecione uma categoria")) {
      itensSensiveis.insert(0, "Selecione uma categoria");
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: temErro ? Colors.red : colorScheme.outlineVariant,
          width: temErro ? 2.0 : 1.5,
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: colorScheme.primary),
          borderRadius: BorderRadius.circular(15),
          dropdownColor: Colors.white,
          elevation: 8,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          items: itensSensiveis.map((String label) {
            final categoriaOriginal =
                CategoriaProduto.values.cast<CategoriaProduto?>().firstWhere(
                      (cat) => cat?.label == label,
                      orElse: () => null,
                    );

            return DropdownMenuItem<String>(
              value: label,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (categoriaOriginal == null
                              ? Colors.grey
                              : colorScheme.secondary)
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categoriaOriginal?.icon ?? Icons.help_outline,
                      size: 20,
                      color: categoriaOriginal == null
                          ? Colors.grey
                          : colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: label == "Selecione uma categoria"
                            ? Colors.grey.shade500
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
