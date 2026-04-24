import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/produto.dart';
import '../../../../services/shared/mercado_shared_provider.dart';
import 'painel_configurar_preco_produto.dart';

class SeletorProdutosGlobaisPainel extends StatefulWidget {
  const SeletorProdutosGlobaisPainel({super.key});

  @override
  State<SeletorProdutosGlobaisPainel> createState() =>
      _SeletorProdutosGlobaisPainelState();
}

class _SeletorProdutosGlobaisPainelState
    extends State<SeletorProdutosGlobaisPainel> {
  final TextEditingController _searchController = TextEditingController();
  List<Produto> _produtosExibidos = [];
  bool _estaCarregando = false;

  // Cache em memória para os 20 itens iniciais
  static List<Produto>? _cacheInicial;

  @override
  void initState() {
    super.initState();
    _carregarProdutosIniciais();
  }

  Future<void> _carregarProdutosIniciais() async {
    if (_cacheInicial != null) {
      setState(() => _produtosExibidos = _cacheInicial!);
      return;
    }

    setState(() => _estaCarregando = true);
    final provider = context.read<MercadoSharedProvider>();
    final produtos = await provider.listarProdutosGlobais();

    _cacheInicial = produtos;
    if (mounted) {
      setState(() {
        _produtosExibidos = produtos;
        _estaCarregando = false;
      });
    }
  }

  Future<void> _pesquisar(String termo) async {
    if (termo.isEmpty) {
      setState(() => _produtosExibidos = _cacheInicial ?? []);
      return;
    }

    setState(() => _estaCarregando = true);
    final provider = context.read<MercadoSharedProvider>();
    final resultados = await provider.buscarProdutosGlobaisPorTermo(termo);

    if (mounted) {
      setState(() {
        _produtosExibidos = resultados;
        _estaCarregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header e Barra de Pesquisa
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _pesquisar,
                    decoration: InputDecoration(
                      hintText: "Nome ou Código de Barras",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Lista de Produtos
            Flexible(
              child: _estaCarregando
                  ? const Center(child: CircularProgressIndicator())
                  : _produtosExibidos.isEmpty
                      ? const Text("Nenhum produto encontrado.")
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _produtosExibidos.length,
                          itemBuilder: (context, index) {
                            final p = _produtosExibidos[index];
                            return _buildCardHorizontal(p, colorScheme);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHorizontal(Produto produto, ColorScheme color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Imagem
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                produto.fotoUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: color.surfaceVariant,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(produto.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Cód.: ${produto.codigoBarras}",
                      style: TextStyle(
                          fontSize: 12, color: color.onSurfaceVariant)),
                ],
              ),
            ),

            IconButton(
              icon: Icon(Icons.add_circle, color: color.secondary, size: 30),
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.85),
                  builder: (context) =>
                      PainelConfigurarPrecoProduto(produto: produto),
                );

                if (result == true && mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
