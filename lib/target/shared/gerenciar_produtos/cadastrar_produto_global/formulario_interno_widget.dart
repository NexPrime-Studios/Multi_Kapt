import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../global_widgets/campo_texto_widget.dart';
import '../../global_widgets/dropdown_unidade_widget.dart';
import '../../global_widgets/secao_titulo_widget.dart';
import 'providers/novo_produto_provider.dart';

class FormInternoWidget extends StatelessWidget {
  const FormInternoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NovoProdutoProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SecaoTituloWidget(titulo: "Produção Interna"),
        const SizedBox(height: 16),

        // Campo de Marca (Opcional)
        CampoTextoWidget(
          label: "Marca / Fabricante (Opcional)",
          controller: provider.marcaController,
          icon: Icons.factory_outlined,
          capitalization: TextCapitalization.characters,
          helperText: "Coloque a marca do mercado que produz",
          validator: (value) => null,
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: CampoTextoWidget(
                label: "Qtd. Conteúdo",
                controller: provider.quantidadeConteudoController,
                type: const TextInputType.numberWithOptions(decimal: true),
                icon: Icons.summarize_outlined,
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: DropdownUnidadeWidget(
                  mostrarLabel: false,
                  value: provider.unidadeMedida,
                  onChanged: (val) => provider.updateEstado(() {
                    if (val != null) provider.unidadeMedida = val;
                  }),
                ),
              ),
            ),
          ],
        ),

        const Padding(
          padding: EdgeInsets.zero,
          child: Text(
            "Se o produto tiver 300 gramas, coloque (0.300g).",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
