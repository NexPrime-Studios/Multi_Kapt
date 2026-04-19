// lib/target/cliente/widgets/seletor_quantidade_widget.dart
import 'package:flutter/material.dart';

class SeletorQuantidade extends StatelessWidget {
  final double quantidade;
  final String sigla;
  final double passo;
  final TextEditingController controller;
  final Function(double) onUpdate;

  const SeletorQuantidade({
    super.key,
    required this.quantidade,
    required this.sigla,
    required this.passo,
    required this.controller,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min, // Ocupa apenas a altura necessária
      children: [
        const Text(
          "Ajuste a quantidade",
          style: TextStyle(
              fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          // Retiramos o padding horizontal fixo para os ícones encostarem mais se necessário
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Estica os itens
            children: [
              IconButton(
                onPressed: () => onUpdate(quantidade - passo),
                icon: const Icon(Icons.remove_circle_outline, size: 30),
                color: cores.primary,
              ),

              // O centro (input + sigla) agora é flexível
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IntrinsicWidth(
                      // Faz o campo de texto ter apenas o tamanho do conteúdo
                      child: TextField(
                        controller: controller,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900),
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero),
                        onChanged: (val) {
                          double? novo =
                              double.tryParse(val.replaceAll(',', '.'));
                          if (novo != null && novo > 0) onUpdate(novo);
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sigla,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () => onUpdate(quantidade + passo),
                icon: const Icon(Icons.add_circle_outline, size: 30),
                color: cores.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
