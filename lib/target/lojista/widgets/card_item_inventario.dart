import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/item_mercado.dart';
import '../../../services/lojista_provider.dart';

class CardItemInventario extends StatelessWidget {
  final String mercadoId;
  final ItemMercado item;
  final VoidCallback onDelete;

  const CardItemInventario({
    super.key,
    required this.mercadoId,
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Note que removemos o FutureBuilder.
    // Agora usamos item.produtoNome e item.produtoImagem diretamente.

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ÁREA DA IMAGEM
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.05,
                child: _buildImagem(item.produtoImagem),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap:
                      onDelete, // Chama a função de deleção passada pela tela pai
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.red, size: 16),
                  ),
                ),
              ),
            ],
          ),

          // 2. INFORMAÇÕES DO PRODUTO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    item.produtoNome, // Nome agora vem direto do item
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.1,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "R\$ ${item.preco.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // 3. FOOTER (Disponibilidade)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.disponivel
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.disponivel ? "ATIVO" : "OFF",
                    style: TextStyle(
                      fontSize: 10,
                      color: item.disponivel ? Colors.green : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 24,
                  child: Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: item.disponivel,
                      activeThumbColor: Colors.green,
                      onChanged: (val) {
                        context
                            .read<LojistaProvider>()
                            .toggleDisponibilidade(item, val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagem(String url) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: url.isNotEmpty
          ? ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            )
          : const Icon(Icons.inventory_2, color: Colors.grey, size: 30),
    );
  }
}
