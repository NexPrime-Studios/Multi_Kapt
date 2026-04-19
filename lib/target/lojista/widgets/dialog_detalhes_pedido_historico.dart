import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/pedido.dart';

class DialogDetalhesPedidoHistorico extends StatelessWidget {
  final Pedido pedido;

  const DialogDetalhesPedidoHistorico({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final dataFormatada =
        DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(pedido.dataCriacao);
    final cores = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CABEÇALHO ESTILIZADO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PEDIDO #${pedido.idPedido.substring(0, 6).toUpperCase()}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      Text(dataFormatada,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SEÇÃO 1: DADOS DO CLIENTE
                    _buildSecaoTitulo("DADOS DO CLIENTE"),
                    _itemLinha(Icons.person, "Nome", pedido.nomeCliente),
                    _itemLinha(Icons.phone, "Telefone", pedido.telefoneCliente),
                    _itemLinha(
                        Icons.location_on, "Endereço", pedido.enderecoEntrega),

                    const Divider(height: 32),

                    // SEÇÃO 2: LOGÍSTICA (QUEM OPEROU O PEDIDO)
                    _buildSecaoTitulo("OPERAÇÃO"),
                    _itemLinha(Icons.inventory_2, "Coletor/Separador",
                        pedido.nomeColetor ?? "Não atribuído"),
                    _itemLinha(Icons.delivery_dining, "Entregador",
                        pedido.nomeEntregador ?? "Não atribuído"),
                    _itemLinha(
                        Icons.payments, "Pagamento", pedido.formaPagamento),

                    const Divider(height: 32),

                    // SEÇÃO 3: ITENS
                    _buildSecaoTitulo("ITENS DO PEDIDO"),
                    ...pedido.itens.map((item) => _buildCardItem(item)),

                    const SizedBox(height: 20),

                    // RESUMO DE VALORES
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _resumoLinha("Subtotal",
                              pedido.total - double.parse(pedido.taxa)),
                          _resumoLinha(
                              "Taxa de Entrega", double.parse(pedido.taxa)),
                          const Divider(),
                          _resumoLinha("TOTAL FINAL", pedido.total,
                              isTotal: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titulo,
        style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: Colors.blueGrey,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _itemLinha(IconData icone, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icone, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                children: [
                  TextSpan(
                      text: "$label: ",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: valor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> item) {
    final nome = item['produto_nome'] ?? 'Produto';
    final qtd = item['quantidade'] ?? 0;
    final precoFinal = (item['preco_final'] ?? 0.0).toDouble();
    final emFalta = item['em_falta'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
        color: emFalta ? Colors.red[50] : Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Colors.blueGrey[800],
                borderRadius: BorderRadius.circular(4)),
            child: Text("${qtd}x",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration:
                            emFalta ? TextDecoration.lineThrough : null)),
                if (emFalta)
                  const Text("ITEM EM FALTA",
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text("R\$ ${precoFinal.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _resumoLinha(String label, double valor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 16 : 13)),
          Text(
            "R\$ ${valor.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
