import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BuscarNomeProduto {
  Future<String?> buscarNome(BuildContext context, String barcode) async {
    final String googleUrl =
        "https://www.google.com.br/search?q=$barcode&tbm=shop&safe=active";

    final String? nomeFinal = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelecaoNomePicker(url: googleUrl, barcode: barcode),
      ),
    );

    return nomeFinal;
  }
}

class SelecaoNomePicker extends StatefulWidget {
  final String url;
  final String barcode;

  const SelecaoNomePicker(
      {super.key, required this.url, required this.barcode});

  @override
  State<SelecaoNomePicker> createState() => _SelecaoNomePickerState();
}

class _SelecaoNomePickerState extends State<SelecaoNomePicker> {
  late final WebViewController _controller;
  List<String> _sugestoesNomes = [];
  bool _isExtracting = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36")
      ..addJavaScriptChannel(
        'Extractor',
        onMessageReceived: (message) {
          if (mounted) {
            final List<String> nomesRaw =
                List<String>.from(jsonDecode(message.message));
            setState(() {
              _sugestoesNomes = nomesRaw
                  .where((n) => n.isNotEmpty && n.length > 5)
                  .toSet()
                  .toList();
              _isExtracting = false;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => _extrairNomes()),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _extrairNomes() {
    _controller.runJavaScript('''
      setTimeout(() => {
        const selectors = ['.sh-np__product-title', '.Xjkr1', 'h3'];
        let foundNames = [];
        selectors.forEach(selector => {
          const elements = Array.from(document.querySelectorAll(selector));
          elements.forEach(el => {
            const text = el.innerText.trim();
            if (text) foundNames.push(text);
          });
        });
        Extractor.postMessage(JSON.stringify(foundNames));
      }, 2000);
    ''');
  }

  Future<void> _confirmarEEditarNome(String nomeSugerido) async {
    final TextEditingController editController =
        TextEditingController(text: nomeSugerido);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String? nomeConfirmado = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        // Usando Dialog genérico para customizar o topo
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Confirmar Nome",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: editController,
                    maxLines: 4,
                    cursorColor: colorScheme.secondary,
                    decoration: InputDecoration(
                      labelText: "Nome do Produto",
                      filled: true,
                      fillColor:
                          colorScheme.surfaceContainerHighest.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, editController.text),
                    child: const Text("USAR ESTE NOME"),
                  ),
                ],
              ),
            ),
            // Botão "X" no topo direito
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: colorScheme.primary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );

    if (nomeConfirmado != null && mounted) {
      Navigator.pop(context, nomeConfirmado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sugestões (Shopping)"),
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
          else if (_sugestoesNomes.isEmpty)
            const Expanded(
                child: Center(child: Text("Nenhuma sugestão encontrada.")))
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _sugestoesNomes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final nome = _sugestoesNomes[index];
                  return ListTile(
                    tileColor:
                        colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    leading: Icon(Icons.shopping_bag_outlined,
                        color: colorScheme.secondary),
                    title: Text(
                      nome,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right,
                        color: colorScheme.primary.withOpacity(0.2)),
                    onTap: () => _confirmarEEditarNome(nome),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
