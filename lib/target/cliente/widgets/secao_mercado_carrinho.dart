import 'package:flutter/material.dart';
import '../../../models/carrinho_item.dart';
import '../../../models/mercado.dart'; // Importe para acessar o enum PagamentosAceitos
import '../../../services/cliente/carrinho_service.dart';
import '../../../services/shared/usuario_service.dart';
import 'card_produto_carrinho.dart';

class SecaoMercadoCarrinho extends StatefulWidget {
  final String mercadoId;
  final List<CarrinhoItem> itens;
  final CarrinhoService carrinho;
  final UsuarioService service;
  final Function(String id, bool atingiu, double taxa) onValidacaoMudou;

  const SecaoMercadoCarrinho({
    super.key,
    required this.mercadoId,
    required this.itens,
    required this.carrinho,
    required this.service,
    required this.onValidacaoMudou,
  });

  @override
  State<SecaoMercadoCarrinho> createState() => _SecaoMercadoCarrinhoState();
}

class _SecaoMercadoCarrinhoState extends State<SecaoMercadoCarrinho> {
  Mercado? _mercado;
  double _totalMercado = 0;
  bool _editandoPagamento = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final m = await widget.service.buscarMercadoPorId(widget.mercadoId);
    if (mounted) {
      setState(() {
        _mercado = m;
        _calcularTotal();
      });
    }
  }

  void _calcularTotal() {
    _totalMercado = widget.itens.fold(0, (sum, item) => sum + item.total);
    if (_mercado != null) {
      bool atingiu = _totalMercado >= (_mercado!.pedidoMinimo);
      widget.onValidacaoMudou(widget.mercadoId, atingiu, _mercado!.taxaEntrega);
    }
  }

  // Função auxiliar para exibir o nome amigável do Enum
  String _getNomePagamento(PagamentosAceitos pag) {
    switch (pag) {
      case PagamentosAceitos.dinheiro:
        return 'Dinheiro';
      case PagamentosAceitos.cartao:
        return 'Cartão';
      case PagamentosAceitos.pix:
        return 'Pix';
      case PagamentosAceitos.vale:
        return 'Vale Refeição';
    }
  }

  // Função para retornar o ícone baseado no Enum
  IconData _getIconePagamento(PagamentosAceitos pag) {
    switch (pag) {
      case PagamentosAceitos.dinheiro:
        return Icons.payments_outlined;
      case PagamentosAceitos.cartao:
        return Icons.credit_card;
      case PagamentosAceitos.pix:
        return Icons.pix;
      case PagamentosAceitos.vale:
        return Icons.account_balance_wallet_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    _calcularTotal();

    if (_mercado == null) return const SizedBox();

    bool atingiuMinimo = _totalMercado >= _mercado!.pedidoMinimo;

    // ALTERADO: Agora é uma lista de Enums
    List<PagamentosAceitos> formasAceitas = _mercado!.pagamentosAceitos;

    // NOTA: Certifique-se que o CarrinhoService agora armazene/gerencie PagamentosAceitos em vez de Strings
    var pagamentoSelecionado =
        widget.carrinho.pagamentosPorMercado[widget.mercadoId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _mercado!.nome,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...widget.itens.asMap().entries.map((entry) {
          return CardProdutoCarrinho(
            item: entry.value,
            carrinho: widget.carrinho,
            index: widget.carrinho.itens.indexOf(entry.value),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: atingiuMinimo ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color:
                    atingiuMinimo ? Colors.green[100]! : Colors.orange[100]!),
          ),
          child: Row(
            children: [
              Icon(
                atingiuMinimo ? Icons.check_circle : Icons.info_outline,
                color: atingiuMinimo ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  atingiuMinimo
                      ? "Mínimo atingido! Taxa de entrega: GRÁTIS"
                      : "Abaixo do mínimo de R\$ ${_mercado!.pedidoMinimo.toStringAsFixed(2)}. Taxa de R\$ ${_mercado!.taxaEntrega.toStringAsFixed(2)} será aplicada.",
                  style: TextStyle(
                      fontSize: 11,
                      color: atingiuMinimo
                          ? Colors.green[800]
                          : Colors.orange[800],
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Pagamento",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            if (pagamentoSelecionado != null && !_editandoPagamento)
              TextButton(
                onPressed: () => setState(() => _editandoPagamento = true),
                style:
                    TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text("Alterar",
                    style: TextStyle(fontSize: 12, color: Colors.blue)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: (pagamentoSelecionado != null && !_editandoPagamento)
              ? _buildCardPagamentoFechado(pagamentoSelecionado)
              : _buildListaPagamentoAberta(formasAceitas),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCardPagamentoFechado(dynamic selecionado) {
    // Tratamento para garantir que seja o enum
    final PagamentosAceitos pag = selecionado is String
        ? PagamentosAceitos.values.byName(selecionado)
        : selecionado;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(_getIconePagamento(pag), size: 18, color: Colors.green),
          const SizedBox(width: 10),
          Text(
            _getNomePagamento(pag),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Spacer(),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildListaPagamentoAberta(List<PagamentosAceitos> formasAceitas) {
    return Container(
      decoration: BoxDecoration(
        color:
            formasAceitas.isEmpty ? Colors.grey[100] : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                formasAceitas.isEmpty ? Colors.grey[300]! : Colors.red[200]!),
      ),
      child: Column(
        children: formasAceitas.isEmpty
            ? [
                const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text("Nenhuma forma disponível"))
              ]
            : formasAceitas.map((forma) {
                bool ehUltimo = formasAceitas.last == forma;
                return Column(
                  children: [
                    _buildOpcaoPagamento(forma),
                    if (!ehUltimo) const Divider(height: 1),
                  ],
                );
              }).toList(),
      ),
    );
  }

  Widget _buildOpcaoPagamento(PagamentosAceitos forma) {
    // Compara com o valor selecionado no carrinho
    final selecionado =
        widget.carrinho.pagamentosPorMercado[widget.mercadoId] == forma;

    return ListTile(
      onTap: () {
        // Envia o enum diretamente para o serviço do carrinho
        widget.carrinho.selecionarPagamento(widget.mercadoId, forma.name);
        setState(() => _editandoPagamento = false);
      },
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        _getIconePagamento(forma),
        size: 18,
        color: selecionado ? Colors.blue[800] : Colors.black,
      ),
      title: Text(
        _getNomePagamento(forma),
        style: TextStyle(
          fontSize: 13,
          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
          color: selecionado ? Colors.blue[800] : Colors.grey[700],
        ),
      ),
      trailing: selecionado
          ? Icon(Icons.check_circle, color: Colors.blue[800], size: 20)
          : Icon(Icons.circle_outlined, color: Colors.grey[300], size: 20),
    );
  }
}
