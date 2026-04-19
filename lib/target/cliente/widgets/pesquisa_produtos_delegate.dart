import 'package:flutter/material.dart';
import '../../../models/mercado.dart';
import '../../../models/produto.dart';
import 'card_produto_mercado.dart';

class PesquisaProdutosMercadoDelegate extends SearchDelegate {
  final Mercado mercado;
  final List<Produto> produtos;

  PesquisaProdutosMercadoDelegate({
    required this.mercado,
    required this.produtos,
  });

  @override
  String get searchFieldLabel => "Buscar em ${mercado.nome}";

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildGridPesquisa();

  @override
  Widget buildSuggestions(BuildContext context) => _buildGridPesquisa();

  Widget _buildGridPesquisa() {
    // Filtra ignorando maiúsculas/minúsculas
    final filtrados = produtos.where((p) {
      return p.nome.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (query.isEmpty) {
      return const Center(
        child: Text("Digite o nome de um produto"),
      );
    }

    if (filtrados.isEmpty) {
      return const Center(
        child: Text("Nenhum produto encontrado"),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 itens por linha
        childAspectRatio: 0.70,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final prod = filtrados[index];
        // Encontra o item correspondente no mercado para pegar o preço
        final item = mercado.itens.firstWhere((it) => it.produtoId == prod.id);

        return CardProdutoMercado(
          produto: prod,
          item: item,
          mercado: mercado,
        );
      },
    );
  }
}
