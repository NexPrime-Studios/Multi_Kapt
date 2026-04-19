import 'package:flutter/material.dart';
import '../../../models/item_pedido.dart';

class ItemPedidoCard extends StatelessWidget {
  final ItemPedido item;

  const ItemPedidoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool emFalta = item.emFalta;
    final bool isSubstituto = item.substituido;
    final bool foiAlterado = item.foiAlterado;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        margin: EdgeInsets.only(left: isSubstituto ? 12 : 0),
        padding: isSubstituto ? const EdgeInsets.all(8) : null,
        decoration: isSubstituto
            ? BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.1)))
            : null,
        child: Row(
          children: [
            if (isSubstituto)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.subdirectory_arrow_right,
                    size: 16, color: Colors.orange),
              ),

            // Quantidade
            Text(
              emFalta
                  ? "0x "
                  : "${foiAlterado ? item.quantidadeColetada : item.quantidade}x ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: emFalta
                    ? Colors.red
                    : (foiAlterado || isSubstituto
                        ? Colors.orange[800]
                        : Colors.black87),
                fontSize: 14,
              ),
            ),

            // Nome do Produto
            Expanded(
              child: Text(
                item.nome,
                style: TextStyle(
                  fontSize: 13,
                  color: emFalta ? Colors.grey : Colors.black87,
                  decoration: emFalta ? TextDecoration.lineThrough : null,
                ),
              ),
            ),

            // Preços e Status
            if (emFalta)
              const Text("EM FALTA",
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 10))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Preço original riscado se houve alteração manual de valor
                  if (foiAlterado)
                    Text(
                      "R\$ ${(item.preco * (item.quantidadeColetada ?? item.quantidade)).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),

                  Text(
                    "R\$ ${item.precoFinal.toStringAsFixed(2)}",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: (foiAlterado || isSubstituto)
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: (foiAlterado || isSubstituto)
                            ? Colors.green[700]
                            : Colors.black87),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
