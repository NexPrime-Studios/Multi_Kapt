// lib/target/cliente/widgets/painel_detalhes_produto.dart
import 'package:flutter/material.dart';
import 'package:mercado_app/models/produto_enums.dart';
import 'package:provider/provider.dart';
import '../../../../models/produto.dart';
import '../../../../models/item_mercado.dart';
import '../../../../models/mercado.dart';
import '../../../../models/unidade_medida_enums.dart';
import '../../../../services/cliente/carrinho_service.dart';
import '../seletor_quantidade_widget.dart';
import 'painel_recado_produto.dart';

class DetalhesProdutoWidget extends StatefulWidget {
  final Produto produto;
  final ItemMercado item;
  final Mercado mercado;

  const DetalhesProdutoWidget({
    super.key,
    required this.produto,
    required this.item,
    required this.mercado,
  });

  @override
  State<DetalhesProdutoWidget> createState() => _DetalhesProdutoWidgetState();
}

class _DetalhesProdutoWidgetState extends State<DetalhesProdutoWidget> {
  double _quantidade = 1.0;
  bool _aceitaSubstituicao = false;
  final _controller = TextEditingController();
  final _obsController = TextEditingController();
  bool _descricaoExpandida = false;

  @override
  void initState() {
    super.initState();
    if (widget.produto.unidadeMedida.ehPeso) _quantidade = 0.5;
    _controller.text = _formatarQtd();
  }

  @override
  void dispose() {
    _controller.dispose();
    _obsController.dispose();
    super.dispose();
  }

  double get _precoAtual => widget.item.emPromocao
      ? widget.item.precoPromocional!
      : widget.item.preco;

  String _formatarQtd() => widget.produto.unidadeMedida.ehPeso
      ? _quantidade.toStringAsFixed(1).replaceAll('.', ',')
      : _quantidade.toInt().toString();

  void _atualizarQtd(double novo) {
    if (novo <= 0) return;
    setState(() {
      _quantidade = novo;
      _controller.text = _formatarQtd();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final ehPeso = widget.produto.unidadeMedida.ehPeso;
    final total = _precoAtual * _quantidade;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(ehPeso),
              const Divider(height: 8),
              const SizedBox(height: 12),

              Center(
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // Removida a verificação de nulo e o operador '!'
                  child: widget.produto.fotoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.produto.fotoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        )
                      : Icon(Icons.image_outlined,
                          size: 48, color: Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 16),

              _buildInfoProduto(cores),

              const SizedBox(height: 16),
              _buildBotaoObservacao(),

              const SizedBox(height: 20),

              // --- 1. SELETOR DE QUANTIDADE (Agora em primeiro) ---
              const Text(
                "Quantidade desejada:",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SeletorQuantidade(
                  quantidade: _quantidade,
                  sigla: widget.produto.unidadeMedida.sigla,
                  passo: ehPeso ? 0.1 : 1.0,
                  controller: _controller,
                  onUpdate: _atualizarQtd,
                ),
              ),

              if (ehPeso)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Center(
                    child: Text(
                      "Peso estimado que pode ser ajustado na pesagem final",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // --- 2. TOGGLE DE SUBSTITUIÇÃO (Agora em segundo) ---
              const Text(
                "Se este produto faltar, aceita trocar por um similar?",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              _buildToggleSubstituicao(),

              const SizedBox(height: 24),
              _buildResumoETaxa(total, cores),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSubstituicao() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment<bool>(
            value: false,
            label: Text("Não trocar", style: TextStyle(fontSize: 12)),
            icon: Icon(Icons.block, size: 18),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text("Sim, aceito", style: TextStyle(fontSize: 12)),
            icon: Icon(Icons.swap_horiz, size: 18),
          ),
        ],
        selected: {_aceitaSubstituicao},
        onSelectionChanged: (Set<bool> novaSelecao) {
          setState(() {
            _aceitaSubstituicao = novaSelecao.first;
          });
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return _aceitaSubstituicao ? Colors.green[700] : Colors.red[700];
            }
            return Colors.grey[100];
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return Colors.grey[700];
          }),
        ),
      ),
    );
  }

  Widget _buildHeader(bool ehPeso) => SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(ehPeso ? "Venda por Peso" : "Detalhes do Produto",
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: () => Navigator.pop(context)),
          ],
        ),
      );

  Widget _buildInfoProduto(ColorScheme cores) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.produto.nome,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          Text(
              "${widget.produto.marca} • ${widget.produto.unidadeMedida.name.toUpperCase()}",
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // --- BLOCO DE DESCRIÇÃO COM "LER MAIS" ---
          if (widget.produto.descricao.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () =>
                  setState(() => _descricaoExpandida = !_descricaoExpandida),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.produto.descricao,
                    // Se não estiver expandido, limita a 3 linhas
                    maxLines: _descricaoExpandida ? null : 3,
                    overflow: _descricaoExpandida
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _descricaoExpandida ? "Ver menos" : "Ler mais...",
                      style: TextStyle(
                        fontSize: 15,
                        color: cores.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text("Cód: ${widget.produto.codigoBarras}",
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  fontFamily: 'monospace')),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.item.emPromocao) ...[
                Text(
                  "R\$ ${widget.item.preco.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "R\$ ${_precoAtual.toStringAsFixed(2)}",
                    style: TextStyle(
                        color: widget.item.emPromocao
                            ? Colors.redAccent
                            : cores.secondary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      "/ ${widget.produto.unidadeMedida.sigla}",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

  Widget _buildBotaoObservacao() {
    bool temObservacao = _obsController.text.isNotEmpty;

    return InkWell(
      onTap: () async {
        final resultado = await showDialog<String>(
          context: context,
          builder: (context) => PainelRecadoProduto(
            observacaoInicial: _obsController.text,
          ),
        );
        if (resultado != null) {
          setState(() => _obsController.text = resultado);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              temObservacao ? Colors.blue.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: temObservacao ? Colors.blue : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(temObservacao ? Icons.edit_note : Icons.add_comment_outlined,
                size: 20, color: temObservacao ? Colors.blue : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                temObservacao
                    ? _obsController.text
                    : "Adicionar recado para o separador",
                style: TextStyle(
                  color: temObservacao ? Colors.black87 : Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoETaxa(double total, ColorScheme cores) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subtotal:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13)),
              Text("R\$ ${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cores.secondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                context.read<CarrinhoService>().adicionar(
                    widget.produto,
                    _quantidade,
                    _precoAtual,
                    widget.mercado.id,
                    widget.mercado.nome,
                    _obsController.text.trim(),
                    _aceitaSubstituicao);
                Navigator.pop(context);
              },
              child: const Text("ADICIONAR NO CARRINHO",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ),
        ],
      );
}
