import 'dart:typed_data';
import 'package:flutter/material.dart';

class SelecaoImagemWidget extends StatelessWidget {
  final Uint8List? novaImagemBytes;
  final String urlImagemExistente;
  final VoidCallback onTap;

  const SelecaoImagemWidget({
    super.key,
    required this.novaImagemBytes,
    required this.urlImagemExistente,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: colorScheme.secondary.withOpacity(0.5), width: 2),
        ),
        child: _buildConteudo(colorScheme),
      ),
    );
  }

  Widget _buildConteudo(ColorScheme colorScheme) {
    if (novaImagemBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(novaImagemBytes!, fit: BoxFit.cover),
      );
    }
    if (urlImagemExistente.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          urlImagemExistente,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_outlined,
            size: 40, color: colorScheme.secondary),
        Text(
          "Clique para selecionar foto",
          style: TextStyle(
              color: colorScheme.secondary, fontWeight: FontWeight.bold),
        )
      ],
    );
  }
}
