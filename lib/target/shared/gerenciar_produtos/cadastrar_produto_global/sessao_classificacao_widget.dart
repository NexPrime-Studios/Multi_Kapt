import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/produto_enums.dart';
import '../../global_widgets/secao_titulo_widget.dart';
import 'dropdown_categoria_widget.dart';
import 'providers/novo_produto_provider.dart';
import 'providers/categoria_provider.dart';

class SessaoClassificacaoWidget extends StatelessWidget {
  const SessaoClassificacaoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final produtoProvider = context.watch<NovoProdutoProvider>();
    final catProvider = context.watch<CategoriaProvider>();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SecaoTituloWidget(titulo: "Classificação do Produto"),
            const SizedBox(height: 8),
            const Text(
              "Selecione a categoria e os detalhes para organizar seu estoque.",
              style:
                  TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 20),

            // 1. DROPDOWN CATEGORIA (BASE ENUM)
            DropdownCategoriaWidget(
              value: catProvider.categoriaSelecionada?.label ??
                  "Selecione uma categoria",
              temErro: catProvider.categoriaSelecionada == null &&
                  produtoProvider.tagErro,
              onChanged: (val) {
                if (val != null) {
                  final enumVal = CategoriaProduto.fromLabel(val);
                  catProvider.setCategoria(enumVal);
                }
              },
            ),

            // 2. SEÇÃO SUBCATEGORIA
            if (catProvider.categoriaSelecionada != null) ...[
              const SizedBox(height: 16),
              if (catProvider.subcategoriaSelecionada != "ADICIONAR_NOVA")
                _buildDropdownDinamico(
                  label: "Subcategoria",
                  value: catProvider.subcategoriaSelecionada,
                  items: catProvider.listaSubcategorias,
                  onChanged: (val) => catProvider.setSubcategoria(val),
                  permitirNovo: true,
                )
              else
                _buildCampoManual(
                  label: "Nova Subcategoria",
                  onCancel: () => catProvider.setSubcategoria(null),
                  onChanged: (val) => catProvider.subcategoriaManual = val,
                ),
            ],

            // 3. SEÇÃO PRODUTO BASE
            if (catProvider.subcategoriaSelecionada != null) ...[
              const SizedBox(height: 16),
              if (catProvider.produtoBaseSelecionado != "ADICIONAR_NOVA")
                _buildDropdownDinamico(
                  label: "Produto Base",
                  value: catProvider.produtoBaseSelecionado,
                  items: catProvider.listaProdutosBase,
                  onChanged: (val) => catProvider.setProdutoBase(val),
                  permitirNovo: true,
                )
              else
                _buildCampoManual(
                  label: "Novo Produto Base",
                  onCancel: () => catProvider.setProdutoBase(null),
                  onChanged: (val) => catProvider.produtoBaseManual = val,
                ),
            ],

            // 4. SEÇÃO VARIAÇÃO
            if (catProvider.produtoBaseSelecionado != null) ...[
              const SizedBox(height: 16),
              if (catProvider.variacaoSelecionada != "ADICIONAR_NOVA")
                _buildDropdownDinamico(
                  label: "Variação/Sabor/Tamanho",
                  value: catProvider.variacaoSelecionada,
                  items: catProvider.listaVariacoes,
                  onChanged: (val) => catProvider.setVariacao(val),
                  permitirNovo: true,
                )
              else
                _buildCampoManual(
                  label: "Nova Variação",
                  onCancel: () => catProvider.setVariacao(null),
                  onChanged: (val) => catProvider.variacaoManual = val,
                ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para criar os Dropdowns repetitivos
  Widget _buildDropdownDinamico({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool permitirNovo = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: [
        ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
        if (permitirNovo)
          const DropdownMenuItem(
            value: "ADICIONAR_NOVA",
            child: Text("+ Outro (Cadastrar Novo)",
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildCampoManual({
    required String label,
    required VoidCallback onCancel,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      autofocus: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: "Digite o nome aqui...",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red),
          onPressed: onCancel,
        ),
      ),
      onChanged: onChanged,
    );
  }
}
