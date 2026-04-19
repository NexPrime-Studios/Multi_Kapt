import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DialogSubstituicaoWidget extends StatelessWidget {
  final dynamic item;
  final VoidCallback onApenasFalta;
  final VoidCallback onBiparNovo;

  const DialogSubstituicaoWidget({
    super.key,
    required this.item,
    required this.onApenasFalta,
    required this.onBiparNovo,
  });

  @override
  Widget build(BuildContext context) {
    // Formatador de moeda
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final double precoOriginal =
        double.tryParse(item['preco']?.toString() ?? '0.0') ?? 0.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.swap_horiz_rounded,
                color: Colors.orange, size: 28),
          ),
          const SizedBox(width: 14),
          const Text(
            "Substituir Item",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Este cliente permite a troca por um produto semelhante em caso de falta.",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Painel de Referência de Preço
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueGrey[100]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Preço do original:",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    Text(
                      currencyFormat.format(precoOriginal),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
                const Divider(height: 20),
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Evite grandes diferenças de valor.",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Column(
          children: [
            // Botão Bipar Novo
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onBiparNovo();
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(
                  "BIPAR NOVO PRODUTO",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Botão Apenas Falta
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onApenasFalta();
                },
                icon: const Icon(Icons.close_rounded),
                label: const Text(
                  "MARCAR APENAS FALTA",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
