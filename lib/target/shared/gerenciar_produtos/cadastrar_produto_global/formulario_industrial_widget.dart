import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../global_widgets/campo_texto_widget.dart';
import '../../global_widgets/dropdown_unidade_widget.dart';
import '../../global_widgets/secao_titulo_widget.dart';
import 'providers/novo_produto_provider.dart';

class FormIndustrialWidget extends StatelessWidget {
  const FormIndustrialWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NovoProdutoProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SecaoTituloWidget(titulo: "Dados Industriais"),
        const SizedBox(height: 16),
        CampoTextoWidget(
          label: "Código de Barras (EAN/GTIN)",
          controller: provider.codigoBarrasController,
          icon: Icons.qr_code_2_rounded,
          enabled: false,
        ),
        const SizedBox(height: 16),
        CampoTextoWidget(
          label: "Marca / Fabricante",
          controller: provider.marcaController,
          icon: Icons.factory_outlined,
          capitalization: TextCapitalization.characters,
          formatters: [UpperCaseTextFormatter()],
          validator: (val) =>
              (val == null || val.isEmpty) ? "Obrigatório" : null,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
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
              flex: 2,
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
        const SizedBox(height: 16),
        const SecaoTituloWidget(titulo: "Características Técnicas"),
        const SizedBox(height: 8),
        _buildSwitch(
          label: "Perecível",
          value: provider.isPerecivel,
          onChanged: (val) =>
              provider.updateEstado(() => provider.isPerecivel = val),
          colorScheme: colorScheme,
        ),
        _buildSwitch(
          label: "Sem Açúcar / Diet",
          value: provider.isSemAcucar,
          onChanged: (val) =>
              provider.updateEstado(() => provider.isSemAcucar = val),
          colorScheme: colorScheme,
        ),
        _buildSwitch(
          label: "Vegano",
          value: provider.isVegano,
          onChanged: (val) =>
              provider.updateEstado(() => provider.isVegano = val),
          colorScheme: colorScheme,
        ),
        _buildSwitch(
          label: "Sem Glúten",
          value: provider.isSemGluten,
          onChanged: (val) =>
              provider.updateEstado(() => provider.isSemGluten = val),
          colorScheme: colorScheme,
        ),
        _buildSwitch(
          label: "Zero Lactose",
          value: provider.isZeroLactose,
          onChanged: (val) =>
              provider.updateEstado(() => provider.isZeroLactose = val),
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Switch(
                value: value,
                activeThumbColor: colorScheme.secondary,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
