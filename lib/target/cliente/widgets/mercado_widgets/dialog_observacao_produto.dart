// lib/target/cliente/widgets/dialog_observacao_produto.dart
import 'package:flutter/material.dart';

class DialogObservacaoProduto extends StatefulWidget {
  final String observacaoInicial;

  const DialogObservacaoProduto({super.key, required this.observacaoInicial});

  @override
  State<DialogObservacaoProduto> createState() =>
      _DialogObservacaoProdutoState();
}

class _DialogObservacaoProdutoState extends State<DialogObservacaoProduto> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.observacaoInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Removemos o padding padrão do título para encostar o "X" no canto
      titlePadding: EdgeInsets.zero,
      title: Stack(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 24, left: 24, right: 48),
            child: Text(
              "Recado para o separador",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () =>
                  Navigator.pop(context), // Fecha sem retornar valor
            ),
          ),
        ],
      ),
      content: TextField(
        controller: _controller,
        maxLength: 70,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(
          hintText: "Ex: Bananas bem maduras, pão bem assado...",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange, // Para manter o padrão visual
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text("Salvar"),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
