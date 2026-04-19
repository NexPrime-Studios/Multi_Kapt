import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/item_mercado.dart';
import 'dialog_configurar_promocao.dart';

class CardItemPromocao extends StatelessWidget {
  final ItemMercado item;

  const CardItemPromocao({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final temPromocao = item.precoPromocional != null &&
        item.fimPromocao != null &&
        item.fimPromocao!.isAfter(agora);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área da Imagem
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Container(
                  height: 110, // Reduzi levemente a altura da imagem
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: item.produtoImagem.isNotEmpty
                      ? Image.network(item.produtoImagem, fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: temPromocao ? Colors.orange : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    temPromocao ? "PROMOÇÃO" : "NORMAL",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          // Área de Conteúdo Flexível
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.produtoNome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),

                  // Lógica de Preços compacta
                  if (temPromocao) ...[
                    Text(
                      "R\$ ${item.preco.toStringAsFixed(2)}",
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      "R\$ ${item.precoPromocional!.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ] else ...[
                    const Spacer(),
                    Text(
                      "R\$ ${item.preco.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],

                  const Spacer(), // Empurra as datas e o botão para o fundo
                  const Divider(height: 12),

                  if (item.inicioPromocao != null &&
                      item.fimPromocao != null) ...[
                    _buildInfoRow(Icons.calendar_today,
                        "Início: ${DateFormat('dd/MM').format(item.inicioPromocao!)}"),
                    const SizedBox(height: 2),
                    _buildInfoRow(Icons.timer_outlined,
                        "Fim: ${DateFormat('dd/MM').format(item.fimPromocao!)}",
                        color: temPromocao ? Colors.redAccent : Colors.grey),
                  ],

                  const SizedBox(height: 8),

                  // Botão com altura fixa
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              DialogConfigurarPromocao(item: item),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            temPromocao ? Colors.blueGrey : Colors.orange,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        temPromocao ? "EDITAR" : "ADICIONAR",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text,
      {Color color = Colors.black87}) {
    return Row(
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 9, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
