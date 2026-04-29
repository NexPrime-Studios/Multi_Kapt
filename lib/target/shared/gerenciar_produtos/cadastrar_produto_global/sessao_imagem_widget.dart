import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mercado_app/models/produto.dart';
import 'package:mercado_app/target/shared/gerenciar_produtos/cadastrar_produto_global/buscar_imagem_serper.dart';
import 'package:provider/provider.dart';
import 'providers/novo_produto_provider.dart';

class SessaoImagemWidget extends StatefulWidget {
  const SessaoImagemWidget({super.key});

  @override
  State<SessaoImagemWidget> createState() => _SessaoImagemWidgetState();
}

class _SessaoImagemWidgetState extends State<SessaoImagemWidget> {
  final TextEditingController _buscaController = TextEditingController();

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _aplicarImagem(
      NovoProdutoProvider provider, Uint8List? imagemSelecionada) {
    if (imagemSelecionada != null) {
      provider.updateEstado(() {
        provider.imagemBytes = imagemSelecionada;
      });
    }
  }

  void _tratarCliqueImagem(
      BuildContext context, NovoProdutoProvider provider) async {
    if (provider.semImagem || provider.estaSalvando) return;

    Uint8List? imagemRetornada;

    if (provider.tipoSelecionado == TipoProduto.interno) {
      provider.selecionarImagemLocal(context);
      return;
    }

    // Define qual termo enviar
    String termo = (provider.tipoSelecionado == TipoProduto.industrial)
        ? provider.codigoBarrasController.text
        : "";

    // Abre a tela e aguarda o resultado (bytes)
    if (!kIsWeb) {
      imagemRetornada = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (context) => BuscarImagemSerperPage(termoBusca: termo),
        ),
      );

      // Se o usuário confirmou e baixou a imagem, aplica no provider
      if (imagemRetornada != null) {
        _aplicarImagem(provider, imagemRetornada);
      }
    } else {
      provider.selecionarImagemLocal(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NovoProdutoProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _tratarCliqueImagem(context, provider),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 90,
                    width: 90,
                    clipBehavior:
                        Clip.antiAlias, // Importante para arredondar a imagem
                    decoration: BoxDecoration(
                      color: provider.semImagem
                          ? Colors.grey[100]
                          : colorScheme.surfaceVariant.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildConteudoImagem(
                        provider, colorScheme.primary), // Use sua função aqui
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Foto do Produto",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.red)),
                      const SizedBox(height: 4),
                      Text(_getSubtitulo(provider),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      const Divider(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text("Produto sem foto",
                            style: TextStyle(fontSize: 13)),
                        value: provider.semImagem,
                        onChanged: (val) {
                          provider.updateEstado(() {
                            provider.semImagem = val;
                            if (val) provider.imagemBytes = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
        return "Toque para abrir câmera/galeria";
      case TipoProduto.industrial:
        return "Busca automática por código";
      case TipoProduto.pesavel:
        return "Use o campo de busca abaixo";
      default:
        return "";
    }
  }

  Widget _buildConteudoImagem(NovoProdutoProvider provider, Color corIcone) {
    if (provider.semImagem)
      return const Icon(Icons.image_not_supported_outlined, color: Colors.grey);
    if (provider.imagemBytes != null)
      return Image.memory(provider.imagemBytes!, fit: BoxFit.cover);
    return Icon(
        provider.tipoSelecionado == TipoProduto.interno
            ? Icons.add_a_photo_outlined
            : Icons.cloud_download_outlined,
        color: corIcone);
  }
}
