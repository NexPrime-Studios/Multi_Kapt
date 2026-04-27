import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../models/produto.dart';
import '../../../../models/produto_enums.dart';
import '../../global_widgets/campo_texto_widget.dart';
import '../../global_widgets/secao_tags_widgets.dart';
import '../../global_widgets/secao_titulo_widget.dart';
import 'providers/categoria_provider.dart';
import 'providers/novo_produto_provider.dart';
import 'sessao_classificacao_widget.dart';
import 'sessao_imagem_widget.dart';
import 'formulario_industrial_widget.dart';
import 'formulario_interno_widget.dart';
import 'formulario_pesavel_widget.dart';

class NovoProdutoPage extends StatelessWidget {
  final String codigoBarrasInicial;
  final TipoProduto tipoDefinido;

  static final _formKey = GlobalKey<FormState>();

  const NovoProdutoPage({
    super.key,
    required this.codigoBarrasInicial,
    this.tipoDefinido = TipoProduto.industrial,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NovoProdutoProvider()
            ..codigoBarrasController.text = codigoBarrasInicial
            ..tipoSelecionado = tipoDefinido,
        ),
        ChangeNotifierProvider(
          create: (_) => CategoriaProvider(),
        ),
      ],
      child: Consumer2<NovoProdutoProvider, CategoriaProvider>(
        builder: (context, provider, catProvider, _) {
          // Sincronização de dados entre os providers
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.updateEstado(() {
              // Sincroniza a Classe/Categoria
              provider.classeController.text =
                  catProvider.categoriaSelecionada?.label ?? "";

              // Sincroniza Subclasse (Verifica se é manual ou vindo do banco)
              provider.subclasseController.text =
                  catProvider.subcategoriaSelecionada == "ADICIONAR_NOVA"
                      ? catProvider.subcategoriaManual
                      : (catProvider.subcategoriaSelecionada ?? "");

              // Sincroniza Produto Base (Verifica se é manual ou vindo do banco)
              provider.produtoBaseController.text =
                  catProvider.produtoBaseSelecionado == "ADICIONAR_NOVA"
                      ? catProvider.produtoBaseManual
                      : (catProvider.produtoBaseSelecionado ?? "");

              // Sincroniza Variação (Verifica se é manual ou vindo do banco)
              provider.variacaoController.text =
                  catProvider.variacaoSelecionada == "ADICIONAR_NOVA"
                      ? catProvider.variacaoManual
                      : (catProvider.variacaoSelecionada ?? "");

              // Atualiza a categoria interna para atualizar as Tags de busca
              provider.categoriaSelecionada = provider.classeController.text;
            });
          });

          final colorScheme = Theme.of(context).colorScheme;

          return Scaffold(
            appBar: AppBar(
              title: const Text("Cadastrar Novo Produto"),
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            body: provider.estaSalvando
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SecaoTituloWidget(titulo: "Imagem do Produto"),
                          const SizedBox(height: 16),
                          const SessaoImagemWidget(),
                          const SizedBox(height: 24),
                          const SecaoTituloWidget(titulo: "Dados Básicos"),
                          const SizedBox(height: 16),
                          CampoTextoWidget(
                            label: "Nome do Produto",
                            controller: provider.nomeController,
                            icon: Icons.inventory_2_outlined,
                            validator: (val) => (val == null || val.isEmpty)
                                ? "Obrigatório"
                                : null,
                          ),
                          if (provider.tipoSelecionado ==
                              TipoProduto.industrial)
                            _buildAcoesIAWeb(context, provider, colorScheme),
                          const SizedBox(height: 16),
                          CampoTextoWidget(
                            label: "Descrição (Opcional)",
                            controller: provider.descricaoController,
                            icon: Icons.description_outlined,
                            maxLines: 3,
                            validator: (value) => null,
                          ),
                          if (provider.tipoSelecionado ==
                              TipoProduto.industrial)
                            Align(
                              alignment: Alignment.center,
                              child: _actionChip(
                                label: "Sugerir Descrição com IA",
                                icon: Icons.auto_awesome_rounded,
                                onPressed: () =>
                                    provider.buscarDescricaoIA(context),
                                color: colorScheme.secondary,
                              ),
                            ),
                          const SizedBox(height: 24),
                          const SecaoTituloWidget(
                              titulo: "Classificação Produto"),
                          const SizedBox(height: 8),
                          const SessaoClassificacaoWidget(),
                          const SizedBox(height: 24),

                          // --- FORMULÁRIO DINÂMICO CONFORME TIPO ---
                          _buildFormEspecifico(provider.tipoSelecionado),
                          const SizedBox(height: 24),

                          // --- SEÇÃO DE TAGS (REAGE À CATEGORIA SELECIONADA) ---
                          const SecaoTituloWidget(titulo: "Tags de Busca"),
                          const SizedBox(height: 12),
                          SecaoTagsWidget(
                            key: ValueKey(provider.categoriaSelecionada),
                            categoria: CategoriaProduto.values.firstWhere(
                              (e) => e.label == provider.categoriaSelecionada,
                              orElse: () => CategoriaProduto.outros,
                            ),
                            tagsSelecionadas: provider.tagsSelecionadas,
                            exibirErro: provider.tagErro,
                            onTagChanged: (tag, selecionado) {
                              provider.updateEstado(() {
                                if (selecionado) {
                                  provider.tagsSelecionadas.add(tag);
                                  provider.tagErro = false;
                                } else {
                                  provider.tagsSelecionadas.remove(tag);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                provider.salvarProduto(context);
                              } else {
                                HapticFeedback.heavyImpact();
                                provider.updateEstado(
                                    () => provider.tagErro = true);
                                provider.mostrarAlerta(context,
                                    "⚠️ Preencha os campos destacados em vermelho.");
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(55),
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("FINALIZAR CADASTRO",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFormEspecifico(TipoProduto tipo) {
    switch (tipo) {
      case TipoProduto.industrial:
        return const FormIndustrialWidget();
      case TipoProduto.pesavel:
        return const FormPesavelWidget();
      case TipoProduto.interno:
        return const FormInternoWidget();
    }
  }

  Widget _buildAcoesIAWeb(BuildContext context, NovoProdutoProvider provider,
      ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _actionChip(
              label: "Sugerir com IA",
              icon: Icons.auto_awesome_rounded,
              onPressed: () => provider.buscarNomeIA(context),
              color: colorScheme.secondary),
          _actionChip(
              label: "Buscar na Web",
              icon: Icons.language_rounded,
              onPressed: () => provider.buscarNomeWeb(context),
              color: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _actionChip(
      {required String label,
      required IconData icon,
      required VoidCallback onPressed,
      required Color color}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: color.withOpacity(0.2))),
      ),
    );
  }
}
