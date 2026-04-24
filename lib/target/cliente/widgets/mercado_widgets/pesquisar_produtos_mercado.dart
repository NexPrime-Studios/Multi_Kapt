import 'package:flutter/material.dart';
import '../../../../models/mercado.dart';
import '../../../../models/produto.dart';
import 'card_produto_mercado.dart';

class PesquisarProdutosNoMercadoPage extends SearchDelegate {
  final Mercado mercado;
  final List<Produto> produtos;

  PesquisarProdutosNoMercadoPage({
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
    // Filtra por nome e por disponibilidade no mercado
    final filtrados = produtos.where((p) {
      // 1. Verifica se o nome coincide com a busca
      final matchesNome = p.nome.toLowerCase().contains(query.toLowerCase());

      // 2. Encontra o item correspondente para checar disponibilidade
      final itemNoMercado = mercado.itens.firstWhere(
        (it) => it.produtoId == p.id,
      );

      // Retorna verdadeiro apenas se o nome bater E o produto estiver disponível
      return matchesNome && itemNoMercado.disponivel;
    }).toList();

    if (query.isEmpty) {
      return const Center(
        child: Text("Digite o nome de um produto"),
      );
    }

    if (filtrados.isEmpty) {
      return const Center(
        child: Text("Nenhum produto disponível encontrado"),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.70,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final prod = filtrados[index];
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
