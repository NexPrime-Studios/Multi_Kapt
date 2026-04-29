import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../models/produto.dart';
import '../../../../enums/produto_enums.dart';
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

class TelaCadastroNovoProduto extends StatelessWidget {
  final String codigoBarrasInicial;
  final TipoProduto tipoDefinido;

  const TelaCadastroNovoProduto({
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
            ..tipoSelecionado = tipoDefinido
            ..codigoBarrasController.text = codigoBarrasInicial,
        ),
        ChangeNotifierProvider(create: (_) => CategoriaProvider()),
      ],
      child: _ConteudoTelaCadastro(
        codigoBarrasInicial: codigoBarrasInicial,
        tipoDefinido: tipoDefinido,
      ),
    );
  }
}

class _ConteudoTelaCadastro extends StatefulWidget {
  final String codigoBarrasInicial;
  final TipoProduto tipoDefinido;

  const _ConteudoTelaCadastro({
    required this.codigoBarrasInicial,
    required this.tipoDefinido,
  });

  @override
  State<_ConteudoTelaCadastro> createState() => _ConteudoTelaCadastroState();
}

class _ConteudoTelaCadastroState extends State<_ConteudoTelaCadastro> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NovoProdutoProvider>();

      provider.codigoBarrasController.text = widget.codigoBarrasInicial;
      provider.tipoSelecionado = widget.tipoDefinido;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NovoProdutoProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastrar Novo Produto"),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (provider.carregandoIA)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
        ],
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

                    if (provider.tipoSelecionado == TipoProduto.industrial) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: SecaoTituloWidget(titulo: "Dados Básicos"),
                          ),
                          const SizedBox(width: 8),
                          _buildBotaoIA(provider, colorScheme),
                        ],
                      ),
                    ] else ...[
                      const SecaoTituloWidget(titulo: "Dados Básicos"),
                    ],

                    const SizedBox(height: 16),
                    // CAMPO NOME
                    CampoTextoWidget(
                      label: "Nome do Produto",
                      controller: provider.nomeController,
                      icon: Icons.inventory_2_outlined,
                      maxLines: null, // Adaptável
                      hintText: provider.carregandoIA
                          ? "Buscando na IA..."
                          : "Ex: Coca-Cola 2L",
                      onClear: () =>
                          setState(() => provider.nomeController.clear()),
                      capitalization: TextCapitalization.words,
                    ),

                    // CAMPO DESCRIÇÃO
                    CampoTextoWidget(
                      label: "Descrição",
                      controller: provider.descricaoController,
                      icon: Icons.description_outlined,
                      maxLines: null, // Adaptável
                      hintText: provider.carregandoIA
                          ? "Gerando descrição..."
                          : "Uso e benefícios",
                      onClear: () =>
                          setState(() => provider.descricaoController.clear()),
                    ),

                    const SizedBox(height: 8),
                    const SecaoTituloWidget(titulo: "Classificação"),
                    const SizedBox(height: 16),
                    const SessaoClassificacaoWidget(),
                    const SizedBox(height: 24),

                    _buildFormEspecifico(provider.tipoSelecionado),

                    const SizedBox(height: 24),
                    const SecaoTituloWidget(titulo: "Tags de Busca"),
                    const SizedBox(height: 12),

                    _buildSecaoTags(provider),

                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          provider.salvarProduto(context);
                        } else {
                          HapticFeedback.heavyImpact();
                          provider.updateEstado(() => provider.tagErro = true);
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
  }

  Widget _buildSecaoTags(NovoProdutoProvider p) {
    return Consumer<CategoriaProvider>(
      builder: (context, catP, _) {
        final categoriaLabel = catP.categoriaSelecionada?.label;
        return SecaoTagsWidget(
          key: ValueKey(categoriaLabel),
          categoria: CategoriaProduto.values.firstWhere(
            (e) => e.label == categoriaLabel,
            orElse: () => CategoriaProduto.outros,
          ),
          tagsSelecionadas: p.tagsSelecionadas,
          exibirErro: p.tagErro,
          onTagChanged: (tag, selecionado) {
            p.updateEstado(() {
              if (selecionado) {
                p.tagsSelecionadas.add(tag);
                p.tagErro = false;
              } else {
                p.tagsSelecionadas.remove(tag);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildBotaoIA(NovoProdutoProvider provider, ColorScheme colorScheme) {
    final bool podeBuscar = !provider.carregandoIA &&
        widget.codigoBarrasInicial.isNotEmpty &&
        widget.codigoBarrasInicial != "0";

    return ActionChip(
      avatar: provider.carregandoIA
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.auto_awesome, size: 16, color: colorScheme.primary),
      label: Text(
        provider.carregandoIA ? "Buscando..." : "Completar com IA",
        style: TextStyle(
            color: provider.carregandoIA ? Colors.grey : colorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
      onPressed: podeBuscar
          ? () => provider.inicializarBuscaIA(widget.codigoBarrasInicial)
          : null,
      backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
      side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
}
