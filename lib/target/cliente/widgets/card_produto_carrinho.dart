import 'package:flutter/material.dart';
import '../../../models/carrinho_item.dart';
import '../../../services/cliente/carrinho_service.dart';

class CardProdutoCarrinho extends StatelessWidget {
  final CarrinhoItem item;
  final CarrinhoService carrinho;
  final int index;

  const CardProdutoCarrinho({
    super.key,
    required this.item,
    required this.carrinho,
    required this.index,
  });

  String _formatarQuantidade(double qtd) {
    if (qtd % 1 == 0) {
      return qtd.toInt().toString();
    }
    return qtd.toStringAsFixed(2).replaceAll('.', ',');
  }

  void _confirmarRemocao(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Remover item?",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content:
              Text("Deseja retirar '${item.produto.nome}' do seu carrinho?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                carrinho.remover(index);
                Navigator.pop(context);
              },
              child: const Text("REMOVER",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    // Criamos um controller local para o TextField refletir o estado atual
    final TextEditingController qtdController =
        TextEditingController(text: _formatarQuantidade(item.quantidade));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 26,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 0, 208, 255),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.produto.nome.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Icon(Icons.inventory_2_outlined,
                          color: cores.primary.withOpacity(0.4), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "R\$ ${item.precoUnitario.toStringAsFixed(2)} un.",
                            style:
                                TextStyle(color: Colors.grey[500], fontSize: 9),
                          ),
                          Text(
                            "Total: R\$ ${item.total.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.deepOrange,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildBotaoQtd(Icons.remove, () {
                                if (item.quantidade > 1) {
                                  carrinho.atualizarQuantidade(
                                      index, item.quantidade - 1);
                                } else {
                                  _confirmarRemocao(context);
                                }
                              }),

                              // CAMPO DE TEXTO EDITÁVEL
                              IntrinsicWidth(
                                child: Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 35),
                                  child: TextField(
                                    controller: qtdController,
                                    textAlign: TextAlign.center,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 4),
                                    ),
                                    onChanged: (val) {
                                      String formatado =
                                          val.replaceAll(',', '.');
                                      double? novo = double.tryParse(formatado);
                                      if (novo != null && novo >= 0) {
                                        // Atualizamos silenciosamente para não perder o foco
                                        item.quantidade = novo;
                                        carrinho.notifyListeners();
                                      }
                                    },
                                    onSubmitted: (val) {
                                      // Ao dar 'Enter', garante que o carrinho processe a mudança final
                                      carrinho.notifyListeners();
                                    },
                                  ),
                                ),
                              ),

                              _buildBotaoQtd(Icons.add, () {
                                carrinho.atualizarQuantidade(
                                    index, item.quantidade + 1);
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _confirmarRemocao(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.red[300],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (item.observacao.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.edit_note,
                            size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.observacao,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoQtd(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }
}
