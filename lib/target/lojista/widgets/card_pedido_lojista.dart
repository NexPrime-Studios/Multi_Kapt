import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/pedido.dart';
import 'painel_atribuicao_pedido.dart';

class CardPedidoLojista extends StatefulWidget {
  final Pedido pedido;
  final String mercadoId;

  const CardPedidoLojista({
    super.key,
    required this.pedido,
    required this.mercadoId,
  });

  @override
  State<CardPedidoLojista> createState() => _CardPedidoLojistaState();
}

class _CardPedidoLojistaState extends State<CardPedidoLojista> {
  late Timer _timer;
  Duration _tempoDecorrido = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tempoDecorrido = DateTime.now().difference(widget.pedido.dataCriacao);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _tempoDecorrido =
              DateTime.now().difference(widget.pedido.dataCriacao);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Abre o painel inferior para atribuir ou editar o funcionário
  void _mostrarPainelAtribuicao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PainelAtribuicaoPedido(pedido: widget.pedido),
    );
  }

  // LÓGICA DE CORES
  Color _getCorFundoStatus() {
    switch (widget.pedido.status) {
      case StatusPedido.pendente:
        return Colors.blue.shade50;
      case StatusPedido.preparando:
        return Colors.orange.shade50;
      case StatusPedido.pronto:
        return Colors.green.shade50;
      case StatusPedido.saiuParaEntrega:
        return Colors.purple.shade50;
      default:
        return Colors.white;
    }
  }

  Color _getCorTempo() {
    if (_tempoDecorrido.inMinutes >= 20) return Colors.red;
    if (_tempoDecorrido.inMinutes >= 10) return Colors.orange;
    return Colors.blue;
  }

  Widget _buildStatusBadge() {
    String label = "AGUARDANDO";
    Color cor = Colors.grey;
    IconData icone = Icons.hourglass_empty;

    switch (widget.pedido.status) {
      case StatusPedido.pendente:
        label = "PENDENTE";
        cor = Colors.blue;
        icone = Icons.notification_important;
        break;
      case StatusPedido.preparando:
        label = "PREPARANDO";
        cor = Colors.orange;
        icone = Icons.inventory_2;
        break;
      case StatusPedido.pronto:
        label = "PRONTO";
        cor = Colors.green;
        icone = Icons.check_circle;
        break;
      case StatusPedido.saiuParaEntrega:
        label = "EM ROTA";
        cor = Colors.purple;
        icone = Icons.local_shipping;
        break;
      case StatusPedido.entregue:
        label = "ENTREGUE";
        cor = Colors.teal;
        icone = Icons.task_alt;
        break;
      case StatusPedido.cancelado:
        label = "CANCELADO";
        cor = Colors.red;
        icone = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
                color: cor, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final corTempo = _getCorTempo();
    final corFundo = _getCorFundoStatus();
    final idCurto = widget.pedido.idPedido.length >= 6
        ? widget.pedido.idPedido.substring(0, 6).toUpperCase()
        : widget.pedido.idPedido.toUpperCase();

    final temFuncionario = widget.pedido.nomeColetor != null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 0),
      color: corFundo,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        height: 85,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(
          children: [
            // 1. TEMPO DE ESPERA
            SizedBox(
              width: 100,
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: corTempo, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "${_tempoDecorrido.inMinutes}m",
                    style: TextStyle(
                        color: corTempo,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            ),

            const VerticalDivider(width: 40, indent: 20, endIndent: 20),

            // 2. INFO CLIENTE
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.pedido.nomeCliente.toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("ID #$idCurto",
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 11)),
                ],
              ),
            ),

            // 3. STATUS
            Expanded(
              flex: 2,
              child: Center(child: _buildStatusBadge()),
            ),

            const VerticalDivider(width: 40, indent: 20, endIndent: 20),

            // 4. RESPONSÁVEL (Editável)
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: _mostrarPainelAtribuicao,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("RESPONSÁVEL",
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.black45,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Icon(Icons.edit,
                              size: 10, color: Colors.blue.shade300),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.pedido.nomeColetor?.toUpperCase() ??
                            "AGUARDANDO...",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: temFuncionario
                                ? Colors.black87
                                : Colors.blue.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. VALOR TOTAL
            SizedBox(
              width: 120,
              child: Text(
                "R\$ ${widget.pedido.total.toStringAsFixed(2)}",
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
