import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/pedido.dart';
import '../../../models/item_pedido.dart';
import 'item_pedido_card.dart';

class CardPedidoCliente extends StatefulWidget {
  final Pedido pedido;
  const CardPedidoCliente({super.key, required this.pedido});

  @override
  State<CardPedidoCliente> createState() => _CardPedidoClienteState();
}

class _CardPedidoClienteState extends State<CardPedidoCliente> {
  bool _expandido = false;

  Color _getCorStatus(StatusPedido status) {
    switch (status) {
      case StatusPedido.pendente:
        return Colors.blue;
      case StatusPedido.preparando:
        return Colors.orange;
      case StatusPedido.pronto:
        return Colors.green;
      case StatusPedido.saiuParaEntrega:
        return Colors.purple;
      case StatusPedido.entregue:
        return Colors.teal; // Cor para entregue
      case StatusPedido.cancelado:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada =
        DateFormat('dd/MM - HH:mm').format(widget.pedido.dataCriacao);
    final corStatus = _getCorStatus(widget.pedido.status);

    return GestureDetector(
      onTap: () => setState(() => _expandido = !_expandido),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border(left: BorderSide(color: corStatus, width: 6)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            // --- CABEÇALHO ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                        color: corStatus.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.store, color: corStatus),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.pedido.nomeMercado.toUpperCase(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: corStatus)),
                        Text(
                            "Pedido #${widget.pedido.idPedido.substring(0, 6).toUpperCase()}",
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 13)),
                        Text(dataFormatada,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("R\$ ${widget.pedido.total.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      _buildStatusBadge(widget.pedido.status, corStatus),
                    ],
                  ),
                ],
              ),
            ),

            if (_expandido) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle("ITENS DO PEDIDO"),
                    ...widget.pedido.itens.map((itemMap) {
                      return ItemPedidoCard(item: ItemPedido.fromMap(itemMap));
                    }),

                    const Divider(height: 32),
                    _sectionTitle("LOGÍSTICA"),
                    _buildInfoRow(Icons.location_on, "ENTREGA",
                        widget.pedido.enderecoEntrega),

                    const Divider(height: 32),
                    _sectionTitle("RASTREAMENTO"),
                    _buildTimeline(), // AQUI ESTÁ A CORREÇÃO
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)));

  // --- TIMELINE CORRIGIDA ---
  Widget _buildTimeline() {
    // 1. Definimos a ordem lógica exata dos status
    final ordemStatus = [
      'pendente',
      'preparando',
      'pronto',
      'saiu_para_entrega',
      'entregue',
    ];

    // 2. Mapeamos os nomes técnicos para nomes amigáveis
    final nomesAmigaveis = {
      'pendente': 'Pedido realizado',
      'preparando': 'Em separação',
      'pronto': 'Pronto para retirada',
      'saiu_para_entrega': 'Saiu para entrega',
      'entregue': 'Entregue ao cliente',
    };

    return Column(
      children: ordemStatus.map((statusChave) {
        // 3. Verificamos se este status existe no mapa de horários do pedido
        final dataStatus = widget.pedido.horarios[statusChave];

        // Se não houver data para esse status, não mostramos nada (ou ignore)
        if (dataStatus == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                nomesAmigaveis[statusChave]!.toUpperCase(),
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                DateFormat('HH:mm').format(dataStatus),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icone, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$titulo: ",
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          Expanded(
              child: Text(valor,
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(StatusPedido status, Color cor) {
    String label = status.name.toUpperCase();
    if (label == 'SAIU_PARA_ENTREGA') label = 'SAIU PARA ENTREGA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: cor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
      child: Text(label,
          style:
              TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
