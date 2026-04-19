import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/pedido.dart';
import '../../../services/lojista_provider.dart';
import '../widgets/card_pedido_historico.dart';

class TelaHistoricoPedidos extends StatefulWidget {
  final String mercadoId;
  const TelaHistoricoPedidos({super.key, required this.mercadoId});

  @override
  State<TelaHistoricoPedidos> createState() => _TelaHistoricoPedidosState();
}

class _TelaHistoricoPedidosState extends State<TelaHistoricoPedidos> {
  final _scrollController = ScrollController();
  final List<Pedido> _pedidos = [];

  int _offset = 0;
  bool _temMais = true;
  bool _carregando = false;
  String _filtroAtual = "Hoje";

  @override
  void initState() {
    super.initState();
    // Carregamento inicial via microtask para garantir que o provider esteja pronto
    Future.microtask(() => _carregarPedidos(reset: true));

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _carregarPedidos();
      }
    });
  }

  DateTime _getDataLimite() {
    final agora = DateTime.now();
    switch (_filtroAtual) {
      case "Hoje":
        return DateTime(agora.year, agora.month, agora.day);
      case "Semana":
        return agora.subtract(const Duration(days: 7));
      case "Mês":
        return DateTime(agora.year, agora.month, 1);
      default:
        return DateTime(2000);
    }
  }

  Future<void> _carregarPedidos({bool reset = false}) async {
    if (_carregando || (!_temMais && !reset)) return;

    setState(() => _carregando = true);
    if (reset) {
      _pedidos.clear();
      _offset = 0;
      _temMais = true;
    }

    try {
      final provider = context.read<LojistaProvider>();

      final listaRaw = await provider.buscarHistoricoPedidosPaginados(
        mercadoId: widget.mercadoId,
        dataLimite: _getDataLimite(),
        offset: _offset,
        limit: 20,
      );

      final novosPedidos = listaRaw
          .map((map) => Pedido.fromMap(map['id'] as String, map))
          .toList();

      if (novosPedidos.length < 20) _temMais = false;

      setState(() {
        _pedidos.addAll(novosPedidos);
        _offset += novosPedidos.length;
      });
    } catch (e) {
      debugPrint("Erro ao carregar histórico: $e");
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Histórico de Pedidos",
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildBarraFiltros(),
        ),
      ),
      body: _pedidos.isEmpty && _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _carregarPedidos(reset: true),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _pedidos.length + (_temMais ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _pedidos.length) {
                    return CardPedidoHistorico(
                      pedido: _pedidos[index],
                    );
                  } else {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
            ),
    );
  }

  Widget _buildBarraFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ["Hoje", "Semana", "Mês", "Todos"].map((f) {
          final isSelected = _filtroAtual == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: isSelected,
              selectedColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              onSelected: (val) {
                if (val && _filtroAtual != f) {
                  setState(() => _filtroAtual = f);
                  _carregarPedidos(reset: true);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _mostrarDetalhesPedido(Pedido p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Detalhes do Pedido",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: p.itens.length,
                        itemBuilder: (context, index) {
                          final item = p.itens[index];
                          final qtd = item['quantidade'] ?? 0;
                          final nome = item['nome'] ?? 'Produto';
                          final preco =
                              (item['preco_unitario'] ?? 0.0).toDouble();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Colors.blue[50],
                                  child: Text("${qtd}x",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(nome,
                                        style: const TextStyle(fontSize: 15))),
                                Text("R\$ ${(preco * qtd).toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL PAGO",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          Text("R\$ ${p.total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            });
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
