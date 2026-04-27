import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class BuscarImagemProduto {
  Future<Uint8List?> buscarProduto(
      BuildContext context, String valor, bool isIndustrial) async {
    String termoBusca;
    if (isIndustrial) {
      termoBusca = valor;
    } else {
      termoBusca =
          "$valor professional food product photography white background";
    }

    // 2. URL com SafeSearch Ativo
    final String googleUrl =
        "https://www.google.com.br/search?q=${Uri.encodeComponent(termoBusca)}&tbm=isch&safe=active";

    final Uint8List? imagemFinal = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelecaoImagemPicker(url: googleUrl, termoBusca: valor),
      ),
    );

    return imagemFinal;
  }
}

class SelecaoImagemPicker extends StatefulWidget {
  final String url;
  final String termoBusca;

  const SelecaoImagemPicker({
    super.key,
    required this.url,
    required this.termoBusca,
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
        const blacklist = ['adult', 'sexy', 'nudity', 'violence', 'blood'];
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
          .filter(src => {
            if (!src || !src.startsWith('http') || src.includes('cleardot.gif') || src.includes('encrypted')) {
              return false;
            }
            // Filtro adicional de segurança por palavras na URL
            return !blacklist.some(word => src.toLowerCase().includes(word));
          })
          .slice(0, 24); 
        
        Extractor.postMessage(JSON.stringify(finalLinks));
      }, 1500);
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
        title: Text("Buscando: ${widget.termoBusca}"),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // WebView invisível para processamento
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
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2));
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
