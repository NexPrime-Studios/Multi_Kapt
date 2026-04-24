import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/item_mercado.dart';
import '../../../services/shared/mercado_shared_provider.dart';

class CardProdutoInventario extends StatelessWidget {
  final ItemMercado item;

  const CardProdutoInventario({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mercadoProv = context.read<MercadoSharedProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // --- PARTE SUPERIOR: IMAGEM E INFOS BÁSICAS ---
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 40,
                    height: 40,
                    color: colorScheme.surfaceVariant,
                    child: item.produtoImagem.isNotEmpty
                        ? Image.network(item.produtoImagem, fit: BoxFit.cover)
                        : Icon(Icons.image_not_supported,
                            size: 18, color: colorScheme.outline),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.produtoNome,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Cód: ${item.codigoBarras}",
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, thickness: 0.5),
            ),

            // --- PARTE INFERIOR: EXCLUIR | DISPONÍVEL | PREÇO (Tudo em uma linha) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. ESQUERDA: Botão de Excluir
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.delete_outline_rounded,
                      color: colorScheme.error, size: 22),
                  onPressed: () => _confirmarRemocao(context, mercadoProv),
                ),

                // 2. MEIO: Switch de Disponibilidade
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 30,
                      width: 40,
                      child: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: item.disponivel,
                          activeColor: Colors.green,
                          onChanged: (val) async {
                            final itemEditado = item.copyWith(disponivel: val);
                            await mercadoProv.atualizarItem(itemEditado);
                          },
                        ),
                      ),
                    ),
                    Text(
                      item.disponivel ? "Ativo" : "Off",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            item.disponivel ? Colors.green : colorScheme.error,
                      ),
                    ),
                  ],
                ),

                // 3. DIREITA: Preço e Botão Editar
                InkWell(
                  onTap: () => _editarPreco(context, mercadoProv),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "R\$ ${item.preco.toStringAsFixed(2).replaceAll('.', ',')}",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 14, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS DE DIÁLOGO ---

  void _editarPreco(BuildContext context, MercadoSharedProvider provider) {
    final TextEditingController precoController =
        TextEditingController(text: item.preco.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Editar Preço"),
        content: TextField(
          controller: precoController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: "R\$ ",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Sair")),
          ElevatedButton(
            onPressed: () async {
              final novoPreco =
                  double.tryParse(precoController.text.replaceAll(',', '.'));
              if (novoPreco != null) {
                final itemEditado = item.copyWith(preco: novoPreco);
                await provider.atualizarItem(itemEditado);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _confirmarRemocao(BuildContext context, MercadoSharedProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remover Item?"),
        content: Text("Deseja excluir '${item.produtoNome}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Não")),
          TextButton(
            onPressed: () async {
              await provider.removerItem(item.codigoBarras);
              if (context.mounted) Navigator.pop(ctx);
            },
            child:
                const Text("Sim, excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
