// lib/target/cliente/widgets/card_produto_mercado.dart
import 'package:flutter/material.dart';
import '../../../../models/produto.dart';
import '../../../../models/item_mercado.dart';
import '../../../../models/mercado.dart';
import 'painel_detalhes_produto.dart';

class CardProdutoMercado extends StatelessWidget {
  final Produto produto;
  final ItemMercado item;
  final Mercado mercado;

  const CardProdutoMercado({
    super.key,
    required this.produto,
    required this.item,
    required this.mercado,
  });

  @override
  Widget build(BuildContext context) {
    final bool emPromocao = item.emPromocao;
    final double precoAtual = emPromocao ? item.precoPromocional! : item.preco;

    final Color corDestaque = emPromocao ? Colors.red : Colors.transparent;
    final Color corFundoPreco =
        emPromocao ? Colors.red.withOpacity(0.08) : Colors.transparent;

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (context) => DetalhesProdutoWidget(
          produto: produto,
          item: item,
          mercado: mercado,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: corDestaque,
            width: emPromocao ? 1.5 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: emPromocao
                  ? Colors.red.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Área da Imagem Atualizada
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                      child: produto.fotoUrl.isNotEmpty
                          ? Image.network(
                              produto.fotoUrl,
                              fit: BoxFit.cover,
                              // Tratamento de carregamento
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              // Tratamento de erro (URL inválida ou falha de rede)
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                Icons.broken_image_outlined,
                                color: Colors.grey[300],
                                size: 40,
                              ),
                            )
                          : Icon(
                              Icons.shopping_bag_outlined,
                              color: emPromocao
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.grey[300],
                              size: 40,
                            ),
                    ),
                  ),
                  if (emPromocao)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "OFERTA",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: corFundoPreco,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    produto.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (emPromocao)
                    Text(
                      "R\$ ${item.preco.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    "R\$ ${precoAtual.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: emPromocao ? Colors.red : Colors.deepOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
