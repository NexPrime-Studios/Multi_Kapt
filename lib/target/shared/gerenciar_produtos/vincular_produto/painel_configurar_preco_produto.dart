import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../models/produto.dart';
import '../../../../models/item_mercado.dart';
import '../../../../services/shared/mercado_shared_provider.dart';

class PainelConfigurarPrecoProduto extends StatefulWidget {
  final Produto produto;

  const PainelConfigurarPrecoProduto({super.key, required this.produto});

  @override
  State<PainelConfigurarPrecoProduto> createState() =>
      _PainelConfigurarPrecoProdutoState();
}

class _PainelConfigurarPrecoProdutoState
    extends State<PainelConfigurarPrecoProduto> {
  final TextEditingController _precoController = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _confirmarAdicao() async {
    final precoString = _precoController.text.replaceAll(',', '.');
    final preco = double.tryParse(precoString);

    if (preco == null || preco <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe um preço válido.")),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final provider = context.read<MercadoSharedProvider>();

      final novoItem = ItemMercado(
        produtoId: widget.produto.id,
        produtoNome: widget.produto.nome,
        produtoImagem: widget.produto.fotoUrl,
        codigoBarras: widget.produto.codigoBarras ?? '',
        preco: preco,
        disponivel: true,
        produtoCategoria: widget.produto.categoria,
      );

      await provider.adicionarProduto(novoItem);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produto adicionado com sucesso!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao adicionar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundDark = const Color(0xFF1A1A1A);
    final Color accentColor = Theme.of(context).primaryColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: backgroundDark,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white10, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Info do Produto
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          widget.produto.fotoUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image,
                              size: 80, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.produto.nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Cód.: ${widget.produto.codigoBarras}",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: Colors.white10),
                ),

                const Text(
                  "PREÇO DE VENDA",
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                // Campo Preço Estilizado
                TextField(
                  controller: _precoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[.,]?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    prefixText: "R\$ ",
                    prefixStyle:
                        const TextStyle(color: Colors.amber, fontSize: 22),
                    hintText: "0,00",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Colors.amber, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Botão "Salvar"
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _confirmarAdicao,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _salvando
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            "ADICIONAR AO INVENTÁRIO",
                            style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Botão X de fechar no topo direito
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
