import 'package:flutter/material.dart';
import '../../../models/mercado.dart';
import '../../../models/produto.dart';
import '../../../models/produto_enums.dart';
import '../../../services/shared/usuario_service.dart';
import '../widgets/card_produto_mercado.dart';
import '../widgets/botao_carrinho_flutuante.dart';
import '../widgets/categorias_selector.dart';
import '../widgets/mercado_header_sliver.dart';
import '../widgets/pesquisa_produtos_delegate.dart'; // Import do seu novo script
import 'tela_carrinho.dart';

class MercadoPaginaCliente extends StatefulWidget {
  final Mercado mercado;
  const MercadoPaginaCliente({super.key, required this.mercado});

  @override
  State<MercadoPaginaCliente> createState() => _MercadoPaginaClienteState();
}

class _MercadoPaginaClienteState extends State<MercadoPaginaCliente> {
  final UsuarioService _service = UsuarioService();
  final String _termoBuscaInterna = "";
  CategoriaProduto? _categoriaSelecionada;
  List<Produto> _todosOsProdutos = [];

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // --- BOTÕES FLUTUANTES SOBREPOSTOS ---
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão de Pesquisa (Novo)
          FloatingActionButton(
            heroTag: 'btn-pesquisa-mercado', // Hero tag única para evitar erros
            onPressed: () => showSearch(
              context: context,
              delegate: PesquisaProdutosMercadoDelegate(
                mercado: widget.mercado,
                produtos: _todosOsProdutos,
              ),
            ),
            backgroundColor: cores.primary,
            mini:
                true, // Botão um pouco menor que o do carrinho para harmonia visual
            child: const Icon(Icons.search, color: Colors.white),
          ),
          const SizedBox(height: 12), // Espaço entre os botões
          // Botão do Carrinho (Existente)
          BotaoCarrinhoFlutuante(
            aoPressionar: () async {
              final sucesso = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CarrinhoPage()),
              );

              if (sucesso == true && mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          MercadoHeaderSliver(mercado: widget.mercado),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CategoriasSelector(
                categorias: widget.mercado.categorias,
                selecionada: _categoriaSelecionada,
                onSelect: (cat) => setState(() => _categoriaSelecionada = cat),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildSearchBar(cores)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: _buildGridProdutos(cores),
          ),
        ],
      ),
    );
  }

  // Mantive a barra de busca fixa por precaução, mas agora o FAB também faz o serviço
  Widget _buildSearchBar(ColorScheme cores) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: () => showSearch(
          context: context,
          delegate: PesquisaProdutosMercadoDelegate(
            mercado: widget.mercado,
            produtos: _todosOsProdutos,
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: cores.primary),
              const SizedBox(width: 10),
              Text(
                "Buscar em ${widget.mercado.nome}...",
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridProdutos(ColorScheme cores) {
    return FutureBuilder<List<Produto>>(
      future: _service.buscarDetalhesDosProdutos(
          widget.mercado.itens.map((i) => i.produtoId).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: Text("Nenhum produto encontrado.")),
          );
        }

        _todosOsProdutos = snapshot.data!;

        final filtrados = _todosOsProdutos.where((p) {
          final matchesBusca =
              p.nome.toLowerCase().contains(_termoBuscaInterna.toLowerCase());
          final matchesCat = _categoriaSelecionada == null ||
              p.categoria == _categoriaSelecionada;
          return matchesBusca && matchesCat;
        }).toList();

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.70,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final prod = filtrados[index];
              final item = widget.mercado.itens
                  .firstWhere((it) => it.produtoId == prod.id);
              return CardProdutoMercado(
                  produto: prod, item: item, mercado: widget.mercado);
            },
            childCount: filtrados.length,
          ),
        );
      },
    );
  }
}
