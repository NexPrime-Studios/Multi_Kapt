import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../global_widgets/campo_texto_widget.dart';
import '../../global_widgets/secao_titulo_widget.dart';
import 'providers/novo_produto_provider.dart';

class FormInternoWidget extends StatelessWidget {
  const FormInternoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NovoProdutoProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SecaoTituloWidget(titulo: "Produção Interna"),
        const SizedBox(height: 16),
        CampoTextoWidget(
          label: "Variação / Tipo (Opcional)",
          controller: provider.variacaoController,
          icon: Icons.tune_rounded,
        ),
        const SizedBox(height: 8),
        const Text(
          "Ex: 'Fatiado', 'Com cobertura', 'Artesanal'.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
