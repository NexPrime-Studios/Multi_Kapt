import 'package:flutter/material.dart';

class SecaoTituloWidget extends StatelessWidget {
  final String titulo;

  const SecaoTituloWidget({
    super.key,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),

        // Título da Seção
        Text(
          titulo.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Divider(
            thickness: 1, // Espessura da linha
            color: colorScheme.outlineVariant,
          ),
        ),
      ],
    );
  }
}
