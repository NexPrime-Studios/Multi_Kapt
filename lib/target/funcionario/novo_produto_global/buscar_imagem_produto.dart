import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class BuscarImagemProduto {
  Future<Uint8List?> buscarProduto(BuildContext context, String barcode) async {
    final String googleUrl =
        "https://www.google.com.br/search?q=$barcode&tbm=isch&safe=active";

    final Uint8List? imagemFinal = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelecaoImagemPicker(url: googleUrl, barcode: barcode),
      ),
    );

    return imagemFinal;
  }
}

class SelecaoImagemPicker extends StatefulWidget {
  final String url;
  final String barcode;

  const SelecaoImagemPicker({
    super.key,
    required this.url,
    required this.barcode,
  });

  @override
  State<SelecaoImagemPicker> createState() => _SelecaoImagemPickerState();
}

class _SelecaoImagemPickerState extends State<SelecaoImagemPicker> {
  late final WebViewController _controller;
  List<String> _imageUrls = [];
  bool _isExtracting = true;
  final Set<String> _urlsQuebradasConfirmadas = {};

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36")
      ..addJavaScriptChannel(
        'Extractor',
        onMessageReceived: (message) {
          if (mounted) {
            final List<String> linksRaw =
                List<String>.from(jsonDecode(message.message));
            setState(() {
              _imageUrls =
                  linksRaw.where((url) => url.isNotEmpty).toSet().toList();
              _isExtracting = false;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _extrairLinks(),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _extrairLinks() {
    _controller.runJavaScript('''
      setTimeout(() => {
        const query = 'div[data-ou]'; 
        const items = Array.from(document.querySelectorAll(query));
        
        let links = items.map(item => {
          try {
            const dataOu = item.getAttribute('data-ou');
            if (dataOu) return dataOu;
            const img = item.querySelector('img');
            return img ? (img.dataset.src || img.src) : null;
          } catch(e) { return null; }
        });

        if (links.filter(l => l).length < 5) {
          links = Array.from(document.querySelectorAll('img'))
            .map(img => img.dataset.src || img.src);
        }

        const finalLinks = links
          .filter(src => src && src.startsWith('http') && !src.includes('cleardot.gif') && !src.includes('encrypted'))
          .slice(0, 20); 
        
        Extractor.postMessage(JSON.stringify(finalLinks));
      }, 2000);
    ''');
  }

  void _removerImagemQuebrada(String url) {
    if (_urlsQuebradasConfirmadas.contains(url)) return;
    _urlsQuebradasConfirmadas.add(url);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _imageUrls.remove(url));
      }
    });
  }

  Future<void> _finalizarSelecao(String url) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
            child: CircularProgressIndicator(color: colorScheme.secondary)));

    try {
      Uint8List bytes;
      if (url.startsWith('data:image')) {
        bytes = base64Decode(url.split(',').last);
      } else {
        final resp =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 7));
        if (resp.statusCode != 200) throw Exception("Erro download");
        bytes = resp.bodyBytes;
      }

      if (!mounted) return;
      Navigator.pop(context); // Fecha loading

      // Popup de Confirmação com Estilo do Tema e botão "X"
      final bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Confirmar Imagem?",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child:
                          Image.memory(bytes, fit: BoxFit.contain, height: 300),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
                      child: const Text("SIM, USAR ESTA"),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                  color: colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );

      if (confirmar == true && mounted) {
        Navigator.pop(context, bytes);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Escolha uma imagem"),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SizedBox(height: 1, child: WebViewWidget(controller: _controller)),
          if (_isExtracting)
            Expanded(
                child: Center(
                    child: CircularProgressIndicator(
                        color: colorScheme.secondary)))
          else if (_imageUrls.isEmpty)
            const Expanded(
                child: Center(child: Text("Nenhuma imagem encontrada.")))
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1),
                itemCount: _imageUrls.length,
                itemBuilder: (context, index) {
                  if (index >= _imageUrls.length)
                    return const SizedBox.shrink();
                  final url = _imageUrls[index];

                  return GestureDetector(
                    onTap: () => _finalizarSelecao(url),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: colorScheme.outline.withOpacity(0.1)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: url.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(url.split(',').last),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  _removerImagemQuebrada(url);
                                  return const SizedBox.shrink();
                                },
                              )
                            : Image.network(
                                url,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                      child: CircularProgressIndicator(
                                    color:
                                        colorScheme.secondary.withOpacity(0.5),
                                    strokeWidth: 2,
                                  ));
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  _removerImagemQuebrada(url);
                                  return const SizedBox.shrink();
                                },
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
