import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/lojista/lojista_provider.dart';
import '../../../models/item_mercado.dart';
import '../widgets/seletor_produtos_globais.dart';
import '../cadastro_produto/cadastro_produto_widget.dart';
import '../widgets/card_item_inventario.dart';

class TelaInventarioMercado extends StatefulWidget {
  const TelaInventarioMercado({super.key});

  @override
  State<TelaInventarioMercado> createState() => _TelaInventarioMercadoState();
}

class _TelaInventarioMercadoState extends State<TelaInventarioMercado> {
  String _filtroNome = "";

  @override
  Widget build(BuildContext context) {
    final lojistaProvider = context.watch<LojistaProvider>();
    final mercado = lojistaProvider.mercado;

    if (mercado == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final listaFiltrada = mercado.itens.where((item) {
      final nome = item.produtoNome.toLowerCase();
      return nome.contains(_filtroNome.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Meu Inventário",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [_buildBotaoCriarItem(context)],
      ),
      body: Column(
        children: [
          _buildBarraBusca(),
          Expanded(
            child: listaFiltrada.isEmpty
                ? _buildEmptyState(_filtroNome.isNotEmpty)
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: listaFiltrada.length,
                    itemBuilder: (context, index) {
                      final item = listaFiltrada[index];

                      return CardItemInventario(
                        mercadoId: mercado.id,
                        item: item,
                        onDelete: () => _confirmarRemocao(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 7, 7, 212),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        onPressed: () =>
            _abrirSeletorGlobal(context, mercado.id, mercado.itens),
        label: const Text("Add Produto ao mercado"),
        icon: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  Widget _buildBotaoCriarItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
          backgroundColor: const Color.fromARGB(255, 253, 255, 124),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        onPressed: () => showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const DialogCadastroProduto(),
        ),
        icon: const Icon(Icons.add),
        label: const Text("Novo Produto Global"),
      ),
    );
  }

  Widget _buildBarraBusca() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (val) => setState(() => _filtroNome = val),
        decoration: InputDecoration(
          hintText: "Buscar no meu inventário...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
        ),
      ),
    );
  }

  void _abrirSeletorGlobal(
      BuildContext context, String mercadoId, List<ItemMercado> lista) {
    showDialog(
      context: context,
      builder: (_) => SeletorProdutosGlobais(
        mercadoId: mercadoId,
        idsJaNoInventario: lista.map((i) => i.produtoId).toList(),
      ),
    );
  }

  void _confirmarRemocao(BuildContext context, ItemMercado item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remover Produto?"),
        content: Text("Isso removerá '${item.produtoNome}' da sua loja."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<LojistaProvider>().removerItem(item);

              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Produto removido com sucesso.")),
              );
            },
            child: const Text("REMOVER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool temFiltro) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(temFiltro ? Icons.search_off : Icons.inventory_2_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            temFiltro ? "Nenhum produto encontrado." : "Inventário vazio.",
            style: const TextStyle(
                color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
