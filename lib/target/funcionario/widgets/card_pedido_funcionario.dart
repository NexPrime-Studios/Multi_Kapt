import 'package:flutter/material.dart';

class CardPedidoFuncionario extends StatelessWidget {
  final Map<String, dynamic> pedido;
  final Function(
          String id, String statusAtual, Map<String, dynamic> dadosPedido)
      onAvancar;

  const CardPedidoFuncionario({
    super.key,
    required this.pedido,
    required this.onAvancar,
  });

  @override
  Widget build(BuildContext context) {
    final String status = pedido['status'] ?? 'pendente';
    final String id = pedido['id'].toString();
    final cores = Theme.of(context).colorScheme;

    final Color corStatus = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: corStatus.withOpacity(0.3), width: 1),
      ),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: corStatus.withOpacity(0.1),
              child: Icon(Icons.receipt_long, color: corStatus),
            ),
            title: Text(
              "Pedido #${id.length > 5 ? id.substring(0, 5).toUpperCase() : id}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Cliente: ${pedido['nome_cliente'] ?? 'Não informado'}"),
                if (status == 'pronto')
                  const Text(
                    "AGUARDANDO ENTREGA",
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.purple,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "R\$ ${(pedido['total'] ?? 0.0).toStringAsFixed(2)}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: cores.primary),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: corStatus.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getLabelStatus(status),
                    style: TextStyle(
                      fontSize: 10,
                      color: corStatus,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (status == 'entregue' || status == 'cancelado')
                    ? null
                    : () => onAvancar(id, status, pedido),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCorBotaoAvancar(status),
                  foregroundColor: Colors.white, // Garante texto branco
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _getTextoBotaoAvancar(status),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendente':
        return Colors.blue;
      case 'preparando':
        return Colors.orange;
      case 'pronto':
        return Colors.purple;
      case 'saiu_para_entrega':
        return Colors.indigo;
      case 'entregue':
        return Colors.teal;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLabelStatus(String status) {
    switch (status) {
      case 'pendente':
        return "PARA COLETAR";
      case 'preparando':
        return "EM SEPARAÇÃO";
      case 'pronto':
        return "PRONTO P/ ENTREGA";
      case 'saiu_para_entrega':
        return "EM ROTA";
      default:
        return status.toUpperCase();
    }
  }

  String _getTextoBotaoAvancar(String status) {
    switch (status) {
      case 'pendente':
        return "ACEITAR E SEPARAR ITENS";
      case 'preparando':
        return "CONCLUIR SEPARAÇÃO";
      case 'pronto':
        return "INICIAR ENTREGA";
      case 'saiu_para_entrega':
        return "CONFIRMAR ENTREGA FINAL";
      case 'entregue':
        return "CONCLUÍDO";
      default:
        return "INDISPONÍVEL";
    }
  }

  Color _getCorBotaoAvancar(String status) {
    switch (status) {
      case 'pendente':
        return Colors.blue;
      case 'preparando':
        return Colors.orange;
      case 'pronto':
        return Colors.purple;
      case 'saiu_para_entrega':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
