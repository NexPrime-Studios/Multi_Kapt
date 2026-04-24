import 'package:flutter/material.dart';
import 'package:mercado_app/models/produto.dart';
import 'package:mercado_app/target/funcionario/novo_produto_global/verificacao_produto_page.dart';
import 'package:provider/provider.dart';
import '../../../models/item_mercado.dart';
import '../../../services/shared/mercado_shared_provider.dart';
import '../widgets/card_produto_inventario.dart';
import '../../shared/gerenciar_produtos/vincular_produto/seletor_produtos_globais.dart';

class TelaItensMercado extends StatefulWidget {
  const TelaItensMercado({super.key});

  @override
  State<TelaItensMercado> createState() => _TelaItensMercadoState();
}

class _TelaItensMercadoState extends State<TelaItensMercado> {
  String _filtroBusca = "";

  void _criarNovoItemGlobal() async {
    final String? codigoBarras = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const VerificacaoProdutoPage()),
    );

    if (codigoBarras != null) {
      debugPrint("Código capturado: $codigoBarras");
    }
  }

  void _adicionarItemAoMercado() async {
    await showDialog<Produto>(
      context: context,
      builder: (context) => const SeletorProdutosGlobaisPainel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mercadoShared = context.watch<MercadoSharedProvider>();
    final String? mercadoId = mercadoShared.mercadoId;

    if (mercadoId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Itens do Mercado"),
          backgroundColor: colorScheme.primary,
        ),
        body: const Center(child: Text("Mercado não identificado.")),
      );
    }

    final List<ItemMercado> todosItens =
        mercadoShared.itensMercado.where((item) {
      final busca = _filtroBusca.trim().toLowerCase();

      if (busca.isEmpty) return true;

      final nomeMatch = item.produtoNome.toLowerCase().contains(busca);
      final codigoMatch = item.codigoBarras.contains(busca);

      return nomeMatch || codigoMatch;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Itens do Mercado"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Novo Item Global",
            onPressed: _criarNovoItemGlobal,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _filtroBusca = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Buscar no estoque...",
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                fillColor: colorScheme.surface,
                filled: true,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarItemAoMercado,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        icon: const Icon(Icons.inventory_2),
        label: const Text("Add Produto no Mercado",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: todosItens.isEmpty
          ? const Center(
              child: Text("Nenhum item encontrado no estoque."),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: todosItens.length,
              itemBuilder: (context, index) =>
                  CardProdutoInventario(item: todosItens[index]),
            ),
    );
  }
}
