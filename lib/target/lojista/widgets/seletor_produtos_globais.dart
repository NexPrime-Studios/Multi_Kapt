import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/item_mercado.dart';
import '../../../models/produto.dart';
import '../../../services/lojista_provider.dart';

class SeletorProdutosGlobais extends StatefulWidget {
  final String mercadoId;
  final List<String> idsJaNoInventario;

  const SeletorProdutosGlobais({
    super.key,
    required this.mercadoId,
    required this.idsJaNoInventario,
  });

  @override
  State<SeletorProdutosGlobais> createState() => _SeletorProdutosGlobaisState();
}

class _SeletorProdutosGlobaisState extends State<SeletorProdutosGlobais> {
  String _termoBusca = "";

  void _configurarPreco(BuildContext context, Produto produto) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Definir preço: ${produto.nome}"),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Preço de Venda",
            prefixText: "R\$ ",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () async {
              final preco =
                  double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;

              // CRIANDO O ITEM MERCADO COM OS DADOS "CARIMBADOS"
              // Isso permite que o lojista filtre por nome no inventário instantaneamente
              final novoItem = ItemMercado(
                produtoId: produto.id,
                produtoNome:
                    produto.nome, // <--- Dado duplicado para performance
                produtoImagem:
                    produto.fotoUrl, // <--- Dado duplicado para performance
                produtoCategoria:
                    produto.categoria.name, // <--- Categoria para filtros
                preco: preco,
                disponivel: true,
                codigoBarras: produto.codigoBarras,
              );

              // Chamada via Provider para manter o estado global atualizado
              await context.read<LojistaProvider>().adicionarItem(novoItem);

              if (context.mounted) {
                Navigator.pop(ctx); // Fecha o dialog de preço
                Navigator.pop(context); // Fecha o seletor global

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text("${produto.nome} adicionado ao inventário!")),
                );
              }
            },
            child: const Text("VINCULAR AO MEU MERCADO"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos o watch aqui apenas se precisarmos de algum dado do service global,
    // mas o StreamBuilder abaixo já resolve a lista de produtos.
    final lojistaProvider = context.read<LojistaProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  const Text(
                    "Biblioteca Global",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (val) => setState(() => _termoBusca = val),
                    decoration: InputDecoration(
                      hintText: "Pesquisar na biblioteca...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<List<Produto>>(
                      stream: lojistaProvider.service.listarProdutosGlobais(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text("Nenhum produto cadastrado."));
                        }

                        // Filtra para não mostrar o que o lojista já tem no inventário
                        final filtrados = snapshot.data!.where((p) {
                          final jaPossui =
                              widget.idsJaNoInventario.contains(p.id);
                          final matchBusca = p.nome.toLowerCase().contains(
                                _termoBusca.toLowerCase(),
                              );
                          return !jaPossui && matchBusca;
                        }).toList();

                        if (filtrados.isEmpty) {
                          return const Center(
                              child: Text("Nenhum resultado encontrado."));
                        }

                        return ListView.separated(
                          itemCount: filtrados.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final prod = filtrados[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: prod.fotoUrl.isNotEmpty
                                    ? Image.network(prod.fotoUrl,
                                        width: 45,
                                        height: 45,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                                Icons.image_not_supported))
                                    : const Icon(Icons.image, size: 45),
                              ),
                              title: Text(prod.nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  "${prod.marca} • ${prod.unidadeMedida.name}"),
                              trailing: const Icon(Icons.add_circle,
                                  color: Colors.green),
                              onTap: () => _configurarPreco(context, prod),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
