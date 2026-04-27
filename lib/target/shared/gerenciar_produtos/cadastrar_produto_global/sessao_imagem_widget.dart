import 'package:flutter/material.dart';
import 'package:mercado_app/models/produto.dart';
import 'package:provider/provider.dart';
import 'providers/novo_produto_provider.dart';

class SessaoImagemWidget extends StatefulWidget {
  const SessaoImagemWidget({super.key});

  @override
  State<SessaoImagemWidget> createState() => _SessaoImagemWidgetState();
}

class _SessaoImagemWidgetState extends State<SessaoImagemWidget> {
  // Controller local para o campo de busca manual
  final TextEditingController _buscaController = TextEditingController();

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NovoProdutoProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    void tratarCliqueImagem() {
      if (provider.semImagem || provider.estaSalvando) return;

      if (provider.tipoSelecionado == TipoProduto.interno) {
        provider.selecionarImagemLocal(context);
      } else {
        provider.processarBuscaImagem(context);
      }
    }

    final Color corBorda = provider.imagemErro
        ? Colors.red.shade700
        : (provider.semImagem
            ? Colors.grey.shade400
            : colorScheme.secondary.withOpacity(0.5));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                // --- ÁREA DA IMAGEM ---
                GestureDetector(
                  onTap: tratarCliqueImagem,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: provider.semImagem
                          ? Colors.grey[100]
                          : colorScheme.surfaceVariant.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: corBorda,
                        width: provider.imagemErro ? 2.5 : 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: provider.estaSalvando
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : _buildConteudoImagem(provider, corBorda),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // --- CONTROLES LATERAIS ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Foto do Produto",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color:
                              provider.imagemErro ? Colors.red.shade800 : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSubtitulo(provider),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text("Produto sem foto",
                            style: TextStyle(fontSize: 13)),
                        value: provider.semImagem,
                        activeColor: colorScheme.secondary,
                        onChanged: (val) {
                          provider.updateEstado(() {
                            provider.semImagem = val;
                            provider.imagemErro = false;
                            if (val) provider.imagemBytes = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- CAMPO DE PESQUISA INTERNO (Apenas para PESÁVEIS) ---
            if (!provider.semImagem &&
                provider.tipoSelecionado == TipoProduto.pesavel) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(),
              ),
              TextField(
                controller: _buscaController,
                decoration: InputDecoration(
                  hintText: "Nome do produto para pesquisar imagem...",
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (valor) {
                  if (valor.isNotEmpty) {
                    provider.processarBuscaImagem(context, nomeManual: valor);
                  }
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.estaSalvando
                      ? null
                      : () => provider.processarBuscaImagem(context,
                          nomeManual: _buscaController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.travel_explore, size: 18),
                  label: const Text("BUSCAR NA INTERNET",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getSubtitulo(NovoProdutoProvider provider) {
    if (provider.semImagem) return "Opcional desativado";
    if (provider.imagemBytes != null) return "Imagem selecionada";

    switch (provider.tipoSelecionado) {
      case TipoProduto.interno:
        return "Toque para abrir galeria";
      case TipoProduto.industrial:
        return "Busca automática por código";
      case TipoProduto.pesavel:
        return "Use o campo de busca abaixo";
    }
  }

  Widget _buildConteudoImagem(NovoProdutoProvider provider, Color corIcone) {
    if (provider.semImagem) {
      return const Icon(Icons.image_not_supported_outlined, color: Colors.grey);
    }
    if (provider.imagemBytes != null) {
      return Image.memory(
        provider.imagemBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    IconData icone = provider.tipoSelecionado == TipoProduto.interno
        ? Icons.photo_library_outlined
        : Icons.cloud_download_outlined;

    return Icon(icone, color: corIcone);
  }
}
