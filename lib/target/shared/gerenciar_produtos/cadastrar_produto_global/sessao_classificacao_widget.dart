import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../enums/produto_enums.dart';
import 'dropdown_categoria_widget.dart';
import 'providers/categoria_provider.dart';

class SessaoClassificacaoWidget extends StatelessWidget {
  const SessaoClassificacaoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CategoriaProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Usando outlineVariant para manter o padrão do seu dropdown
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. CATEGORIA
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Categoria",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownCategoriaWidget(
                  value: prov.categoriaSelecionada?.label ??
                      "Selecione uma categoria",
                  onChanged: (val) {
                    if (val != null) {
                      prov.setCategoria(CategoriaProduto.fromLabel(val));
                    }
                  },
                ),
              ],
            ),

            // 2. PRODUTO BASE
            if (prov.categoriaSelecionada != null) ...[
              const SizedBox(height: 20),
              _buildCampoSelecao(
                context,
                label: "Produto",
                value: prov.produtoBaseSelecionado,
                items: prov.listaProdutosBase,
                isLoading: prov.carregando,
                onSelect: (val) => prov.setProdutoBase(val),
                onAdicionarNovo: (novo) => prov.setProdutoBase(novo),
              ),
            ],

            // 3. VARIAÇÃO
            if (prov.produtoBaseSelecionado != null) ...[
              const SizedBox(height: 20),
              _buildCampoSelecao(
                context,
                label: "Variação / Sabor",
                value: prov.variacaoSelecionada,
                items: prov.listaVariacoes,
                isLoading: false,
                onSelect: (val) => prov.setVariacao(val),
                onAdicionarNovo: (novo) => prov.setVariacao(novo),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCampoSelecao(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> items,
    required bool isLoading,
    required Function(String) onSelect,
    required Function(String) onAdicionarNovo,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: isLoading
              ? null
              : () => _mostrarDialogBusca(
                  context, label, items, onSelect, onAdicionarNovo),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Ícone usando a cor secundária do tema, como no seu dropdown
                Icon(Icons.ads_click, size: 20, color: colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? "Selecionar...",
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          value == null ? Colors.grey.shade500 : Colors.black87,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: colorScheme.primary))
                else
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarDialogBusca(
      BuildContext context,
      String titulo,
      List<String> items,
      Function(String) onSelect,
      Function(String) onAdicionarNovo) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        String filtro = "";
        return StatefulBuilder(builder: (context, setState) {
          final filtrados = items
              .where((i) => i.toLowerCase().contains(filtro.toLowerCase()))
              .toList();

          return Dialog(
            backgroundColor: Colors.grey[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxHeight: 550),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Selecionar $titulo",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Procurar...",
                      prefixIcon:
                          Icon(Icons.search, color: colorScheme.primary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    onChanged: (val) => setState(() => filtro = val),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              tileColor:
                                  colorScheme.primaryContainer.withOpacity(0.3),
                              leading: CircleAvatar(
                                radius: 15,
                                backgroundColor: colorScheme.primary,
                                child: const Icon(Icons.add,
                                    color: Colors.white, size: 18),
                              ),
                              title: Text("Cadastrar novo",
                                  style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold)),
                              onTap: () {
                                Navigator.pop(context);
                                _mostrarDialogNovo(
                                    context, titulo, onAdicionarNovo);
                              },
                            ),
                            const Divider(height: 1),
                            ...filtrados.map((item) => Column(
                                  children: [
                                    ListTile(
                                      title: Text(item),
                                      trailing: Icon(Icons.chevron_right,
                                          size: 18, color: colorScheme.outline),
                                      onTap: () {
                                        onSelect(item);
                                        Navigator.pop(context);
                                      },
                                    ),
                                    const Divider(
                                        height: 1, indent: 16, endIndent: 16),
                                  ],
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _mostrarDialogNovo(
      BuildContext context, String titulo, Function(String) onConfirmar) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Novo $titulo",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Nome do item",
                  labelStyle: TextStyle(color: colorScheme.primary),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      onConfirmar(controller.text.trim());
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("SALVAR ITEM",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
