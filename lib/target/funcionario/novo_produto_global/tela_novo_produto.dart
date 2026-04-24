import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mercado_app/services/shared/gemini_services.dart';
import 'package:mercado_app/target/funcionario/novo_produto_global/buscar_dados_ia_produto.dart';

import '../../../../models/produto_enums.dart';
import '../../../../models/tags_helper.dart';
import '../../../models/produto.dart';
import '../../../services/funcionario/funcionario_service.dart';
import '../../../services/shared/imagem_service.dart';
import '../../../services/shared/mercado_shared_provider.dart';
import 'scanner_manual_page.dart';
import 'package:mercado_app/target/funcionario/novo_produto_global/buscar_imagem_produto.dart';

import '../../shared/global_widgets/campo_texto_widget.dart';
import '../../shared/global_widgets/dropdown_categoria_widget.dart';
import '../../shared/global_widgets/dropdown_unidade_widget.dart';

class TelaNovoProduto extends StatefulWidget {
  const TelaNovoProduto({super.key});

  @override
  State<TelaNovoProduto> createState() => _TelaNovoProdutoState();
}

class _TelaNovoProdutoState extends State<TelaNovoProduto> {
  final _formKey = GlobalKey<FormState>();
  final _mercadorSharedProvider = MercadoSharedProvider();
  final ImagemService _imagemService = ImagemService();
  final _buscarDescricaoService = BuscarDadosIAProduto();

  // Controllers
  final _codigoController = TextEditingController();
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
  bool _carregando = true;
  bool _salvando = false;
  bool _tagErro = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fluxoInicialScanner());
  }

  void _fluxoInicialScanner() async {
    final String? codigoRecebido = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerManualPage()),
    );

    if (codigoRecebido != null && mounted) {
      setState(() => _carregando = true);

      try {
        final Produto? produtoExistente =
            await _mercadorSharedProvider.buscarProdutoGlobal(codigoRecebido);

        if (!mounted) return;

        if (produtoExistente != null) {
          _mostrarAvisoProdutoExistente(codigoRecebido, produtoExistente.nome);
          setState(() => _carregando = false);
        } else {
          setState(() {
            _codigoController.text = codigoRecebido;
            _carregando = false;
          });
        }
      } catch (e) {
        debugPrint("Erro ao processar código recebido: $e");
        if (mounted) setState(() => _carregando = false);
      }
    } else {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarAvisoProdutoExistente(String codigo, String nomeProduto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // Usando uma Column simples no title para evitar o Row Overflow
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
            SizedBox(height: 8),
            Text("Produto já cadastrado"),
          ],
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              const Text("Este código de barras já consta em nossa base:"),
              const SizedBox(height: 12),
              Text(
                codigo,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)),
                child: Text(
                  nomeProduto,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Não é necessário cadastrá-lo novamente."),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Fecha o dialog
              Navigator.pop(context); // Sai da tela de cadastro
            },
            child: const Text("ENTENDIDO"),
          ),
        ],
      ),
    );
  }

  /// Função disparada pelo botão na seção de imagem
  Future<void> _buscarImagemManualmente() async {
    if (_codigoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escaneie o código primeiro!")),
      );
      return;
    }

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
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                                    if (_codigoController.text.isEmpty) return;

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

                          CampoTextoWidget(
                            label: "Marca / Fabricante",
                            controller: _marcaController,
                            icon: Icons.factory_outlined,
                          ),

                          // Campo Descrição + Sugestão
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
                                    if (_codigoController.text.isEmpty) return;

                                    // Agora chama selecionarDado passando 'false' para modo Descrição
                                    final String? desc =
                                        await _buscarDescricaoService
                                            .selecionarDado(
                                                context,
                                                _codigoController.text,
                                                false // modoNome = false
                                                );

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

  // Componentes Auxiliares
  Widget _buildBotaoSugestao(
      {required IconData icon,
      required ColorScheme colorScheme,
      required VoidCallback onPressed}) {
    return Container(
      height: 50,
      width: 50,
      child: IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.secondary.withOpacity(0.1),
          foregroundColor: colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.secondary.withOpacity(0.2)),
          ),
        ),
        icon: Icon(icon),
      ),
    );
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
        // Botão para carregar imagem via Web/IA
        Positioned(
          bottom: -10,
          right: -10,
          child: IconButton.filled(
            onPressed: _buscarImagemManualmente,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.primary,
              elevation: 4,
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: "Buscar imagem online",
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
          checkmarkColor: colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.secondary
                  : colorScheme.outline.withOpacity(0.2),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBotaoSalvar(ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: _salvando
          ? null
          : () async {
              // Evita múltiplos cliques
              final formValido = _formKey.currentState!.validate();

              setState(() => _tagErro = _tagsSelecionadas.isEmpty);

              if (_imagemBytes == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("É obrigatório ter uma imagem do produto!"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              if (formValido && !_tagErro) {
                setState(() => _salvando = true);

                try {
                  String idProduto =
                      DateTime.now().millisecondsSinceEpoch.toString();

                  // 2. Fazer Upload da Imagem
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
                    marca: _marcaController.text.trim().toUpperCase(),
                    codigoBarras: _codigoController.text.trim(),
                    categoria: _categoria,
                    unidadeMedida: _unidade,
                    tags: _tagsSelecionadas,
                  );

                  // 5. Salvar no Banco via provider
                  await _mercadorSharedProvider
                      .cadastrarProdutoGlobal(novoProduto);

                  GeminiService.limparCache();

                  if (!mounted) return;
                  Navigator.pop(context);
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
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Preencha todos os campos e tags.")),
                );
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

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
        child: CircularProgressIndicator(color: colorScheme.secondary));
  }
}
