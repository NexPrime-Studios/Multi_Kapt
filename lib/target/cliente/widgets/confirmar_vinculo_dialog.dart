// lib/target/cliente/widgets/confirmar_vinculo_dialog.dart
import 'package:flutter/material.dart';

class ConfirmarVinculoDialog extends StatelessWidget {
  final String nomeMercado;
  final String nomeFuncionario;
  final VoidCallback onConfirmar;

  const ConfirmarVinculoDialog({
    super.key,
    required this.nomeMercado,
    required this.nomeFuncionario,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          // Conteúdo Principal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Confirmar Vínculo",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                const Text("Deseja vincular-se a este estabelecimento?"),
                const SizedBox(height: 20),
                _infoItem("🏪 Mercado", nomeMercado),
                const SizedBox(height: 12),
                _infoItem("👤 Funcionário", nomeFuncionario),
                const SizedBox(height: 25),

                // Botão Confirmar (Largura total)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirmar();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("CONFIRMAR VÍNCULO",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Botão Cancelar (X) no topo direito
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text(valor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
