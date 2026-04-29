import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class BuscarImagemWebViewPage extends StatefulWidget {
  final String? termoBusca;

  const BuscarImagemWebViewPage({super.key, this.termoBusca});

  @override
  State<BuscarImagemWebViewPage> createState() =>
      _BuscarImagemWebViewPageState();
}

class _BuscarImagemWebViewPageState extends State<BuscarImagemWebViewPage> {
  late final WebViewController _webController;
  final TextEditingController _controller = TextEditingController();

  List<String> _imagens = [];
  bool _estaCarregando = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.termoBusca ?? "";

    _webController = WebViewController()
      ..setUserAgent(
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Delay para garantir que o lazy load inicial do Google processe os src
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (_estaCarregando) {
                _extrairImagensDoGoogle();
              }
            });
          },
        ),
      );

    if (_controller.text.isNotEmpty) {
      _executarBusca();
    }
  }

  void _executarBusca() {
    if (_controller.text.isEmpty) return;

    setState(() {
      _estaCarregando = true;
      _imagens = [];
    });

    final searchUrl = Uri.encodeFull(
        "https://www.google.com/images?q=${_controller.text}&tbm=isch");

    _webController.loadRequest(Uri.parse(searchUrl));
  }

  Future<void> _extrairImagensDoGoogle() async {
    try {
      final String js = """
        (function() {
          var imgs = document.querySelectorAll('img');
          var results = [];
          for (var i = 0; i < imgs.length; i++) {
            var src = imgs[i].src || imgs[i].getAttribute('data-src');
            
            if (src) {
              // Filtros de segurança e utilidade
              var isGoogleLogo = src.includes('googlelogo') || src.includes('gstatic.com/images?q=tbn:download');
              var isIcon = src.startsWith('data:image/svg') || src.length < 100; // Filtra svgs e base64 curtinhos (ícones)

              if (!isGoogleLogo && !isIcon) {
                if (src.startsWith('http') || src.startsWith('data:image')) {
                  results.push(src);
                }
              }
            }
            if (results.length >= 100) break; // Pega o máximo possível da 1ª página
          }
          return JSON.stringify(results);
        })();
      """;

      final Object response =
          await _webController.runJavaScriptReturningResult(js);

      String rawJson = response.toString();
      if (rawJson.startsWith('"') && rawJson.endsWith('"')) {
        rawJson =
            rawJson.substring(1, rawJson.length - 1).replaceAll('\\"', '"');
      }

      final List<dynamic> decoded = jsonDecode(rawJson);
      final List<String> links = decoded.map((e) => e.toString()).toList();

      setState(() {
        _imagens = links;
        _estaCarregando = false;
      });
    } catch (e) {
      debugPrint("Erro no scraping: $e");
      setState(() => _estaCarregando = false);
    }
  }

  Future<Uint8List?> _baixarImagem(String url) async {
    try {
      if (url.startsWith('data:image')) {
        return base64Decode(url.split(',').last);
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {
      debugPrint("Erro ao baixar: $e");
    }
    return null;
  }

  Widget _construirWidgetImagem(String url, {bool ehGrid = false}) {
    final imageWidget = url.startsWith('data:image')
        ? Image.memory(
            base64Decode(url.split(',').last),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              if (ehGrid) _removerImagemDaLista(url);
              return const SizedBox.shrink();
            },
          )
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              if (ehGrid) _removerImagemDaLista(url);
              return const SizedBox.shrink();
            },
          );

    return imageWidget;
  }

  void _removerImagemDaLista(String url) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _imagens.remove(url);
        });
      }
    });
  }

  void _confirmarSelecao(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Usar esta imagem?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _construirWidgetImagem(url),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _estaCarregando = true);
              final bytes = await _baixarImagem(url);
              if (mounted) {
                if (bytes != null)
                  Navigator.pop(context, bytes);
                else
                  setState(() => _estaCarregando = false);
              }
            },
            child: const Text("CONFIRMAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mostrarBusca =
        widget.termoBusca == null || widget.termoBusca!.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Imagens'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 1,
            child: WebViewWidget(controller: _webController),
          ),
          if (mostrarBusca) _buildCampoBusca(),
          Expanded(
            child: _estaCarregando
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black))
                : _buildGridImagens(),
          ),
        ],
      ),
    );
  }

  Widget _buildGridImagens() {
    if (_imagens.isEmpty && !_estaCarregando) {
      return const Center(child: Text('Nenhuma imagem encontrada.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _imagens.length,
      itemBuilder: (context, index) {
        final url = _imagens[index];
        return GestureDetector(
          onTap: () => _confirmarSelecao(url),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _construirWidgetImagem(url, ehGrid: true),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCampoBusca() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Pesquisar novo termo...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _executarBusca(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.search),
            onPressed: _executarBusca,
          ),
        ],
      ),
    );
  }
}
