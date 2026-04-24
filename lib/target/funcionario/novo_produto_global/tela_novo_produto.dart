import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mercado_app/services/shared/gemini_services.dart';
import 'package:mercado_app/target/funcionario/novo_produto_global/buscar_dados_ia_produto.dart';

import '../../../../models/produto_enums.dart';
import '../../../../models/tags_helper.dart';
import '../../../models/produto.dart';
import '../../../services/shared/imagem_service.dart';
import '../../../services/shared/mercado_shared_provider.dart';
import 'package:mercado_app/target/funcionario/novo_produto_global/buscar_imagem_produto.dart';

import '../../shared/global_widgets/campo_texto_widget.dart';
import '../../shared/global_widgets/dropdown_categoria_widget.dart';
import '../../shared/global_widgets/dropdown_unidade_widget.dart';

class TelaNovoProduto extends StatefulWidget {
  final String codigoBarras; // Agora recebe o código como parâmetro obrigatório

  const TelaNovoProduto({super.key, required this.codigoBarras});

  @override
  State<TelaNovoProduto> createState() => _TelaNovoProdutoState();
}

class _TelaNovoProdutoState extends State<TelaNovoProduto> {
  final _formKey = GlobalKey<FormState>();
  final _mercadorSharedProvider = MercadoSharedProvider();
  final ImagemService _imagemService = ImagemService();
  final _buscarDescricaoService = BuscarDadosIAProduto();

  // Controllers
  late final TextEditingController _codigoController;
  final _nomeController = TextEditingController();
  final _marcaController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorMedidaController = TextEditingController(text: "1");

  // Estado dos dados
  Uint8List? _imagemBytes;
  CategoriaProduto _categoria = CategoriaProduto.mercearia;
  UnidadeMedida _unidade = UnidadeMedida.unidade;
  final List<String> _tagsSelecionadas = [];

  // Estado de UI
  bool _carregando = false;
  bool _salvando = false;
  bool _tagErro = false;

  @override
  void initState() {
    super.initState();
    // Inicializa o controller com o código recebido
    _codigoController = TextEditingController(text: widget.codigoBarras);
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nomeController.dispose();
    _marcaController.dispose();
    _descricaoController.dispose();
    _valorMedidaController.dispose();
    super.dispose();
  }

  Future<void> _buscarImagemManualmente() async {
    setState(() => _carregando = true);
    try {
      final Uint8List? imagem = await BuscarImagemProduto()
          .buscarProduto(context, _codigoController.text);

      if (mounted) {
        setState(() {
          _imagemBytes = imagem;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
      debugPrint("Erro ao buscar imagem: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Novo Produto"),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando || _salvando
          ? _buildLoadingState(colorScheme)
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderDestaque(colorScheme, theme),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionTitle(
                              colorScheme, "Detalhes do Produto"),
                          const SizedBox(height: 16),

                          // Campo Nome
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CampoTextoWidget(
                                  label: "Nome do Produto",
                                  controller: _nomeController,
                                  icon: Icons.inventory_2_outlined,
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: _buildBotaoSugestao(
                                  icon: Icons.auto_awesome_rounded,
                                  colorScheme: colorScheme,
                                  onPressed: () async {
                                    final String? nome =
                                        await _buscarDescricaoService
                                            .selecionarDado(context,
                                                _codigoController.text, true);
                                    if (nome != null) {
                                      setState(
                                          () => _nomeController.text = nome);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Campo Marca (UpperCase)
                          CampoTextoWidget(
                            label: "Marca / Fabricante",
                            controller: _marcaController,
                            icon: Icons.factory_outlined,
                            formatters: [
                              UpperCaseTextFormatter(), // Formata em tempo real
                            ],
                          ),

                          // Campo Descrição
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CampoTextoWidget(
                                  label: "Descrição",
                                  controller: _descricaoController,
                                  icon: Icons.description_outlined,
                                  maxLines: 5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 50),
                                child: _buildBotaoSugestao(
                                  icon: Icons.auto_awesome_rounded,
                                  colorScheme: colorScheme,
                                  onPressed: () async {
                                    final String? desc =
                                        await _buscarDescricaoService
                                            .selecionarDado(context,
                                                _codigoController.text, false);
                                    if (desc != null) {
                                      setState(() =>
                                          _descricaoController.text = desc);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          _buildSectionTitle(colorScheme, "Classificação"),
                          const SizedBox(height: 16),

                          DropdownCategoriaWidget(
                            value: _categoria,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _categoria = val;
                                  _tagsSelecionadas.clear();
                                  _tagErro = false;
                                });
                              }
                            },
                          ),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: CampoTextoWidget(
                                  label: "Qtd/Medida",
                                  controller: _valorMedidaController,
                                  type: TextInputType.number,
                                  icon: Icons.summarize_outlined,
                                  validator: (v) => (v == null ||
                                          v.isEmpty ||
                                          double.tryParse(v) == null)
                                      ? "Inválido"
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownUnidadeWidget(
                                  value: _unidade,
                                  onChanged: (val) {
                                    if (val != null)
                                      setState(() => _unidade = val);
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          _buildSectionTitle(colorScheme, "Tags de Busca"),
                          const SizedBox(height: 12),

                          _buildTagChips(colorScheme),

                          if (_tagErro)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: Text(
                                "Selecione ao menos uma tag informativa",
                                style: TextStyle(
                                    color: colorScheme.error, fontSize: 12),
                              ),
                            ),

                          const SizedBox(height: 40),
                          _buildBotaoSalvar(colorScheme),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildBotaoSalvar(ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: _salvando
          ? null
          : () async {
              final formValido = _formKey.currentState!.validate();
              setState(() => _tagErro = _tagsSelecionadas.isEmpty);

              if (_imagemBytes == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("É obrigatório ter uma imagem do produto!"),
                      backgroundColor: Colors.redAccent),
                );
                return;
              }

              if (formValido && !_tagErro) {
                setState(() => _salvando = true);
                try {
                  String idProduto =
                      DateTime.now().millisecondsSinceEpoch.toString();

                  final fotoUrl = await _imagemService.uploadProdutoImage(
                    bytes: _imagemBytes!,
                    produtoId: idProduto,
                  );

                  if (fotoUrl == null)
                    throw Exception("Falha ao fazer upload da imagem.");

                  String nomeFinal = _nomeController.text.trim();
                  if (_valorMedidaController.text.isNotEmpty) {
                    nomeFinal +=
                        " ${_valorMedidaController.text}${_unidade.sigla}";
                  }

                  final novoProduto = Produto(
                    id: '',
                    nome: nomeFinal,
                    descricao: _descricaoController.text.trim(),
                    fotoUrl: fotoUrl,
                    marca: _marcaController.text
                        .trim()
                        .toUpperCase(), // Final UpperCase
                    codigoBarras: _codigoController.text.trim(),
                    categoria: _categoria,
                    unidadeMedida: _unidade,
                    tags: _tagsSelecionadas,
                  );

                  await _mercadorSharedProvider
                      .cadastrarProdutoGlobal(novoProduto);
                  GeminiService.limparCache();

                  if (!mounted) return;

                  // Retorna true para fechar a tela anterior também
                  Navigator.pop(context, true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("✅ Produto Cadastrado com Sucesso!"),
                        backgroundColor: Colors.green),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Erro ao salvar: $e"),
                          backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _salvando = false);
                }
              }
            },
      child: _salvando
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Text("CADASTRAR PRODUTO"),
    );
  }

  // Métodos de UI permanecem similares, mas adaptados
  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
        child: CircularProgressIndicator(color: colorScheme.secondary));
  }

  Widget _buildSectionTitle(ColorScheme colorScheme, String title) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: colorScheme.secondary,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title.toUpperCase(),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
                letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildHeaderDestaque(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        children: [
          _buildSecaoImagem(colorScheme),
          const SizedBox(height: 24),
          TextField(
            controller: _codigoController,
            enabled: false,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: "Código Identificado",
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon:
                  const Icon(Icons.qr_code_2_rounded, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoImagem(ColorScheme colorScheme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 140,
          width: 140,
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: colorScheme.secondary.withOpacity(0.5), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: _imagemBytes != null
                ? Image.memory(_imagemBytes!, fit: BoxFit.cover)
                : Icon(Icons.add_a_photo_outlined,
                    size: 40, color: colorScheme.secondary.withOpacity(0.5)),
          ),
        ),
        Positioned(
          bottom: -10,
          right: -10,
          child: IconButton.filled(
            onPressed: _buscarImagemManualmente,
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChips(ColorScheme colorScheme) {
    final sugestoes = TagsHelper.sugestoesPorCategoria[_categoria.name] ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sugestoes.map((tag) {
        final isSelected = _tagsSelecionadas.contains(tag);
        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (v) {
            setState(() {
              if (v) {
                _tagsSelecionadas.add(tag);
                _tagErro = false;
              } else {
                _tagsSelecionadas.remove(tag);
              }
            });
          },
          selectedColor: colorScheme.secondary,
        );
      }).toList(),
    );
  }

  Widget _buildBotaoSugestao(
      {required IconData icon,
      required ColorScheme colorScheme,
      required VoidCallback onPressed}) {
    return SizedBox(
      height: 50,
      width: 50,
      child: IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
            backgroundColor: colorScheme.secondary.withOpacity(0.1),
            foregroundColor: colorScheme.secondary),
        icon: Icon(icon),
      ),
    );
  }
}

/// Helper para converter texto em maiúsculo enquanto digita
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
