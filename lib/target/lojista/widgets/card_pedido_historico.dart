import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/pedido.dart';
import '../widgets/dialog_detalhes_pedido_historico.dart';

class CardPedidoHistorico extends StatelessWidget {
  final Pedido pedido;

  const CardPedidoHistorico({
    super.key,
    required this.pedido,
  });

  @override
  Widget build(BuildContext context) {
    // Formatação de data e valores baseada no modelo
    final dataFormatada =
        DateFormat('dd/MM/yy • HH:mm', 'pt_BR').format(pedido.dataCriacao);
    final idCurto = pedido.idPedido.substring(0, 6).toUpperCase();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => showDialog(
          context: context,
          builder: (context) => DialogDetalhesPedidoHistorico(pedido: pedido),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // LINHA 1: ID, Data e Valor
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long,
                          size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(
                        "#$idCurto",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Text(
                    "R\$ ${pedido.total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.green,
                        fontSize: 17),
                  ),
                ],
              ),
              const Divider(height: 20),

              // LINHA 2: Informações do Cliente e Itens
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              pedido.nomeCliente.toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dataFormatada,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${pedido.itens.length} itens",
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pedido.formaPagamento,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ],
              ),

              // LINHA 3: Rodapé com Equipe (se houver)
              if (pedido.nomeColetor != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.assignment_ind_outlined,
                        size: 12, color: Colors.orange[800]),
                    const SizedBox(width: 4),
                    Text(
                      "Coletado por: ${pedido.nomeColetor}",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
