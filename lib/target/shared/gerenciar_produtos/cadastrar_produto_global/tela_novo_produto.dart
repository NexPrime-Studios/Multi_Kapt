import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mercado_app/services/shared/gemini_services.dart';
import 'package:mercado_app/target/funcionario/novo_produto_global/buscar_dados_ia_produto.dart';

import '../../../../../models/produto_enums.dart';
import '../../../../models/produto.dart';
import '../../../../models/unidade_medida_enums.dart';
import '../../../../services/shared/imagem_service.dart';
import '../../../../services/shared/mercado_shared_provider.dart';
import 'package:mercado_app/target/shared/gerenciar_produtos/cadastrar_produto_global/buscar_imagem_produto.dart';

import '../../global_widgets/secao_titulo_widget.dart';
import '../../global_widgets/campo_texto_widget.dart';
import '../../global_widgets/dropdown_unidade_widget.dart';
import '../../global_widgets/secao_tags_widgets.dart';
import '../../../funcionario/novo_produto_global/buscar_nome_produto.dart';

class TelaNovoProduto extends StatefulWidget {
  final String codigoBarras;
  const TelaNovoProduto({super.key, required this.codigoBarras});

  @override
  State<TelaNovoProduto> createState() => _TelaNovoProdutoState();
}

class _TelaNovoProdutoState extends State<TelaNovoProduto> {
  final _formKey = GlobalKey<FormState>();
  final _mercadorSharedProvider = MercadoSharedProvider();
  final ImagemService _imagemService = ImagemService();
  final _buscarDescricaoService = BuscarDadosIAProduto();
  final _buscarNomeWeb = BuscarNomeProduto();

  // Controllers
  late final TextEditingController _codigoController;
  final _nomeController = TextEditingController();
  final _marcaController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorMedidaController = TextEditingController(text: "1");
  final _pesoEstimadoController = TextEditingController(); // Novo

  // Estado dos dados
  Uint8List? _imagemBytes;
  bool _semImagem = false;
  bool _semMarca = false;
  CategoriaProduto _categoria = CategoriaProduto.outros;
  UnidadeMedida _unidade = UnidadeMedida.unidade;
  final List<String> _tagsSelecionadas = [];

  // Novas Características (Booleanos)
  bool _isVegano = false;
  bool _isSemGluten = false;
  bool _isPerecivel = false;
  bool _isSemAcucar = false;
  bool _isZeroLactose = false;
  bool _precoVariavel = false;

  // Estado de UI
  bool _carregando = false;
  bool _salvando = false;
  bool _tagErro = false;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.codigoBarras);
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nomeController.dispose();
    _marcaController.dispose();
    _descricaoController.dispose();
    _valorMedidaController.dispose();
    _pesoEstimadoController.dispose();
    super.dispose();
  }

  // --- Lógica de Negócio ---

  Future<void> _buscarImagemManualmente() async {
    if (_semImagem) return;
    setState(() => _carregando = true);
    try {
      final Uint8List? imagem = await BuscarImagemProduto()
          .buscarProduto(context, _codigoController.text, true);
      if (mounted) {
        setState(() {
          _imagemBytes = imagem;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvarProduto() async {
    final formValido = _formKey.currentState!.validate();
    setState(() => _tagErro = _tagsSelecionadas.isEmpty);
    final bool imagemFaltando = !_semImagem && _imagemBytes == null;

    // 3. Efeito Visual de Erro e Interrupção
    if (!formValido || _tagErro || imagemFaltando) {
      HapticFeedback.heavyImpact();

      String mensagemErro = "⚠️ Verifique os campos em vermelho";
      if (imagemFaltando)
        mensagemErro = "⚠️ Adicione uma foto ou marque 'Sem imagem'";
      if (_tagErro) mensagemErro = "⚠️ Selecione pelo menos uma Tag";

      _mostrarSnackBar(mensagemErro, Colors.orangeAccent.shade700);
      return;
    }

    setState(() => _salvando = true);

    try {
      String? fotoUrl;
      String idProduto = DateTime.now().millisecondsSinceEpoch.toString();

      if (_semImagem) {
        fotoUrl = "semimagem";
      } else {
        fotoUrl = await _imagemService.uploadProdutoImage(
          bytes: _imagemBytes!,
          produtoId: idProduto,
        );
      }

      final novoProduto = Produto(
        id: '',
        nome:
            "${_nomeController.text.trim()} ${_valorMedidaController.text}${_unidade.sigla}",

        descricao: _descricaoController.text.trim(),
        fotoUrl: fotoUrl ?? "semimagem",
        marca:
            _semMarca ? "semmarca" : _marcaController.text.trim().toUpperCase(),

        codigoBarras: _codigoController.text.trim(),
        unidadeMedida: _unidade,
        tags: _tagsSelecionadas,
        quantidadeConteudo:
            double.tryParse(_valorMedidaController.text.replaceAll(',', '.')) ??
                0.0,
        tipo: TipoProduto.industrial,
        categoria: 'teste',
        subcategoria: idProduto,
        produtoBase: 'teste',
        // Características booleanas
        isVegano: _isVegano,
        isSemGluten: _isSemGluten,
        isPerecivel: _isPerecivel,
        isSemAcucar: _isSemAcucar,
        isZeroLactose: _isZeroLactose,
        pesoEstimadoUnidade: _precoVariavel
            ? double.tryParse(_pesoEstimadoController.text.replaceAll(',', '.'))
            : null,
      );

      await _mercadorSharedProvider.cadastrarProdutoGlobal(novoProduto);
      GeminiService.limparCache();

      if (!mounted) return;

      Navigator.pop(context, true);
      _mostrarSnackBar("✅ Produto Cadastrado com Sucesso!", Colors.green);
    } catch (e) {
      if (mounted) _mostrarSnackBar("❌ Erro ao salvar: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarSnackBar(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: cor),
    );
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
        elevation: 0,
      ),
      body: _carregando || _salvando
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.secondary))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SecaoTituloWidget(titulo: "Id do Produto"),
                      const SizedBox(height: 16),
                      CampoTextoWidget(
                        label: "Código de Barras",
                        controller: _codigoController,
                        icon: Icons.qr_code_2_rounded,
                        enabled: false,
                      ),
                      const SizedBox(height: 24),
                      const SecaoTituloWidget(titulo: "Imagem"),
                      const SizedBox(height: 16),
                      _buildCampoImagemComToggle(colorScheme, theme),
                      const SizedBox(height: 24),
                      const SecaoTituloWidget(titulo: "Identificação"),
                      const SizedBox(height: 16),
                      CampoTextoWidget(
                        label: "Nome do Produto",
                        controller: _nomeController,
                        icon: Icons.inventory_2_outlined,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _buildAcoesSugestao(
                            onIA: () async {
                              final nome =
                                  await _buscarDescricaoService.selecionarDado(
                                      context, _codigoController.text, true);
                              if (nome != null)
                                setState(() => _nomeController.text = nome);
                            },
                            onWeb: () async {
                              final nome = await _buscarNomeWeb.buscarNome(
                                  context, _codigoController.text);
                              if (nome != null)
                                setState(() => _nomeController.text = nome);
                            },
                            labelIA: "Sugerir com IA",
                            labelWeb: "Buscar na Web",
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CampoTextoWidget(
                        label: "Descrição",
                        controller: _descricaoController,
                        icon: Icons.description_outlined,
                        maxLines: 3,
                        validator: ((value) => null),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _actionChip(
                            label: "Sugerir Descrição com IA",
                            icon: Icons.auto_awesome_rounded,
                            onPressed: () async {
                              final desc =
                                  await _buscarDescricaoService.selecionarDado(
                                      context, _codigoController.text, false);
                              if (desc != null) {
                                setState(
                                    () => _descricaoController.text = desc);
                              }
                            },
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 3,
                            child: CampoTextoWidget(
                              label: "Marca / Fabricante",
                              controller: _marcaController,
                              icon: Icons.factory_outlined,
                              enabled: !_semMarca,
                              formatters: [UpperCaseTextFormatter()],
                              validator: (val) {
                                if (!_semMarca &&
                                    (val == null || val.isEmpty)) {
                                  return "Obrigatório";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            height: 100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Sem Marca",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _semMarca
                                        ? colorScheme.secondary
                                        : Colors.grey[600],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Switch(
                                    value: _semMarca,
                                    activeColor: colorScheme.secondary,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (val) {
                                      setState(() {
                                        _semMarca = val;
                                        if (val) {
                                          _marcaController.clear();
                                          FocusScope.of(context).unfocus();
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const SecaoTituloWidget(
                          titulo: "Classificação, Conteúdo e Medida"),
                      const SizedBox(height: 16),
                      _buildLinhaMedida(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Vendido por Peso (Preço Variável)",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text(
                            "Marque se o valor final depende do peso (ex: carnes, legumes)",
                            style: TextStyle(fontSize: 12)),
                        value: _precoVariavel,
                        activeColor: colorScheme.secondary,
                        onChanged: (val) =>
                            setState(() => _precoVariavel = val),
                      ),
                      if (_precoVariavel) ...[
                        const SizedBox(height: 8),
                        CampoTextoWidget(
                          label: "Peso Médio por Unidade (kg)",
                          controller: _pesoEstimadoController,
                          icon: Icons.scale_rounded,
                          type: const TextInputType.numberWithOptions(
                              decimal: true),
                          formatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'))
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      const SecaoTituloWidget(
                          titulo: "Características do Produto"),
                      const SizedBox(height: 8),
                      _buildCaracteristicaSwitch(
                        label: "Perecível (Validade Curta)",
                        descricao:
                            "Itens que estragam rápido ou precisam de refrigeração, como carne, frutas, Iogurte e etc..",
                        value: _isPerecivel,
                        onChanged: (val) => setState(() => _isPerecivel = val),
                        colorScheme: colorScheme,
                      ),
                      _buildCaracteristicaSwitch(
                        label: "Sem Açúcar",
                        descricao: "Produtos 'Diet', 'Zero' ou 'Sem Açucar'.",
                        value: _isSemAcucar,
                        onChanged: (val) => setState(() => _isSemAcucar = val),
                        colorScheme: colorScheme,
                      ),
                      _buildCaracteristicaSwitch(
                        label: "Produto Vegano",
                        descricao:
                            "Livre de qualquer ingrediente de origem animal.",
                        value: _isVegano,
                        onChanged: (val) => setState(() => _isVegano = val),
                        colorScheme: colorScheme,
                      ),
                      _buildCaracteristicaSwitch(
                        label: "Sem Glúten",
                        descricao: "Produtos seguros para celíacos.",
                        value: _isSemGluten,
                        onChanged: (val) => setState(() => _isSemGluten = val),
                        colorScheme: colorScheme,
                      ),
                      _buildCaracteristicaSwitch(
                        label: "Zero Lactose",
                        descricao:
                            "Para intolerantes à lactose ou derivados do leite.",
                        value: _isZeroLactose,
                        onChanged: (val) =>
                            setState(() => _isZeroLactose = val),
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 24),
                      const SecaoTituloWidget(titulo: "Tags de Busca"),
                      const SizedBox(height: 12),
                      SecaoTagsWidget(
                        categoria: _categoria,
                        tagsSelecionadas: _tagsSelecionadas,
                        exibirErro: _tagErro,
                        onTagChanged: (tag, selecionado) {
                          setState(() {
                            if (selecionado) {
                              _tagsSelecionadas.add(tag);
                              _tagErro = false;
                            } else {
                              _tagsSelecionadas.remove(tag);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 40),
                      _buildBotaoSalvar(colorScheme),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // --- Widgets de Apoio ---

  Widget _buildCaracteristicaSwitch({
    required String label,
    String? descricao, // Agora é opcional
    required bool value,
    required Function(bool) onChanged,
    required ColorScheme colorScheme,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: descricao != null
          ? Text(descricao,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]))
          : null,
      value: value,
      activeColor: colorScheme.secondary,
      onChanged: onChanged,
    );
  }

  Widget _buildCampoImagemComToggle(ColorScheme colorScheme, ThemeData theme) {
    return Row(
      children: [
        GestureDetector(
          onTap: _semImagem ? null : _buscarImagemManualmente,
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: _semImagem
                  ? Colors.grey[200]
                  : colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _semImagem
                      ? Colors.grey
                      : colorScheme.secondary.withOpacity(0.5),
                  width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _semImagem
                  ? const Icon(Icons.image_not_supported_outlined,
                      color: Colors.grey)
                  : (_imagemBytes != null
                      ? Image.memory(_imagemBytes!, fit: BoxFit.cover)
                      : Icon(Icons.add_a_photo_outlined,
                          color: colorScheme.secondary)),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Produto sem foto?",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Sem imagem", style: TextStyle(fontSize: 14)),
                value: _semImagem,
                activeColor: colorScheme.secondary,
                onChanged: (bool value) {
                  setState(() {
                    _semImagem = value;
                    if (value) _imagemBytes = null;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinhaMedida() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: CampoTextoWidget(
            label: "Quant./Medida",
            controller: _valorMedidaController,
            type: const TextInputType.numberWithOptions(decimal: true),
            icon: Icons.summarize_outlined,
            formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: DropdownUnidadeWidget(
              mostrarLabel: false,
              value: _unidade,
              onChanged: (val) {
                if (val != null) setState(() => _unidade = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcoesSugestao(
      {required VoidCallback onIA,
      required VoidCallback onWeb,
      required String labelIA,
      required String labelWeb}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      children: [
        _actionChip(
            label: labelIA,
            icon: Icons.auto_awesome_rounded,
            onPressed: onIA,
            color: colorScheme.secondary),
        _actionChip(
            label: labelWeb,
            icon: Icons.language_rounded,
            onPressed: onWeb,
            color: Colors.blueAccent),
      ],
    );
  }

  Widget _actionChip(
      {required String label,
      required IconData icon,
      required VoidCallback? onPressed,
      required Color color}) {
    bool estaDesabilitado = onPressed == null;
    return TextButton.icon(
      onPressed: onPressed,
      icon: estaDesabilitado
          ? const SizedBox(
              width: 12,
              height: 12,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.grey))
          : Icon(icon, size: 16),
      label: Text(estaDesabilitado ? "Processando..." : label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: estaDesabilitado ? Colors.grey : color)),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: estaDesabilitado
                    ? Colors.grey.withOpacity(0.2)
                    : color.withOpacity(0.2))),
      ),
    );
  }

  Widget _buildBotaoSalvar(ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: _salvando ? null : _salvarProduto,
      style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: _salvando
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Text("CADASTRAR PRODUTO"),
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
