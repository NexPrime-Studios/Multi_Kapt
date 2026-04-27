import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../global_widgets/campo_texto_widget.dart';
import '../../global_widgets/secao_titulo_widget.dart';
import 'providers/novo_produto_provider.dart';

class FormPesavelWidget extends StatelessWidget {
  const FormPesavelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NovoProdutoProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SecaoTituloWidget(titulo: "Configuração de Peso (Balança)"),
        const SizedBox(height: 16),
        CampoTextoWidget(
          label: "Peso Médio por Unidade (kg)",
          controller: provider.pesoEstimadoController,
          icon: Icons.scale_rounded,
          type: const TextInputType.numberWithOptions(decimal: true),
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        ),
        const Text(
          "Ex: Se uma maçã pesa em média 150g, coloque 0.150. Isso ajuda o cliente a estimar o preço no carrinho.",
          style: TextStyle(
              fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
