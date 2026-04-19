import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/lojista_provider.dart';
import '../../../models/item_mercado.dart';
import '../widgets/card_item_promocao.dart';

class TelaPromocoes extends StatefulWidget {
  final String mercadoId;
  const TelaPromocoes({super.key, required this.mercadoId});

  @override
  State<TelaPromocoes> createState() => _TelaPromocoesState();
}

class _TelaPromocoesState extends State<TelaPromocoes> {
  // 1. Controller para gerenciar e limpar o texto da barra de pesquisa
  final TextEditingController _searchController = TextEditingController();
  String _termoBusca = "";

  @override
  void dispose() {
    // Importante para evitar vazamento de memória
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lojistaProvider = context.watch<LojistaProvider>();
    final mercado = lojistaProvider.mercado;

    final List<ItemMercado> itensParaExibir = mercado?.itens.where((item) {
          final nome = item.produtoNome.toLowerCase();
          final busca = _termoBusca.toLowerCase();

          if (_termoBusca.isEmpty) {
            if (item.precoPromocional == null || item.fimPromocao == null) {
              return false;
            }
            return item.fimPromocao!.isAfter(DateTime.now());
          } else {
            return nome.contains(busca);
          }
        }).toList() ??
        [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _termoBusca.isEmpty ? "Promoções Ativas" : "Resultado da Busca",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _termoBusca = val);
              },
              decoration: InputDecoration(
                hintText: "Buscar em todos os produtos...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _termoBusca.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _termoBusca = "");
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),
          Expanded(
            child: itensParaExibir.isEmpty
                ? _buildEmptyState(_termoBusca.isNotEmpty)
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: itensParaExibir.length,
                    itemBuilder: (context, index) {
                      return CardItemPromocao(item: itensParaExibir[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool pesquisando) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            pesquisando ? Icons.search_off : Icons.campaign_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            pesquisando
                ? "Nenhum produto encontrado."
                : "Nenhuma promoção ativa no momento.",
            style: const TextStyle(
                color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
