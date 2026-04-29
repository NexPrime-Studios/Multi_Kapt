import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../services/shared/serper_service.dart';

class BuscarImagemSerperPage extends StatefulWidget {
  final String? termoBusca;

  const BuscarImagemSerperPage({super.key, this.termoBusca});

  @override
  State<BuscarImagemSerperPage> createState() => _BuscarImagemSerperPageState();
}

class _BuscarImagemSerperPageState extends State<BuscarImagemSerperPage> {
  final TextEditingController _controller = TextEditingController();
  final SerperService _serperService = SerperService();

  List<dynamic> _imagens = [];
  bool _estaCarregando = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.termoBusca ?? "";
    if (_controller.text.isNotEmpty) {
      _executarBusca();
    }
  }

  Future<void> _executarBusca() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _estaCarregando = true;
      _imagens = [];
    });

    try {
      final resultados =
          await _serperService.buscarImagens(_controller.text, limite: 20);

      setState(() {
        _imagens = resultados;
        _estaCarregando = false;
      });
    } catch (e) {
      debugPrint("Erro na busca Serper: $e");
      setState(() => _estaCarregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao buscar imagens: $e")),
        );
      }
    }
  }

  Future<Uint8List?> _baixarImagem(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {
      debugPrint("Erro ao baixar: $e");
    }
    return null;
  }

  void _confirmarSelecao(Map<String, dynamic> imagemData) async {
    final String url = imagemData['imageUrl'];

    final bool? desejaConfirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: EdgeInsets.zero,
        title: Stack(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 44, 12),
              child: Text("Usar esta imagem?", style: TextStyle(fontSize: 18)),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(dialogContext, false),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("CONFIRMAR"),
              ),
            ),
          ),
        ],
      ),
    );

    if (desejaConfirmar == true && mounted) {
      setState(() => _estaCarregando = true);

      final bytes = await _baixarImagem(url);

      if (mounted) {
        if (bytes != null) {
          Navigator.of(context).pop(bytes);
        } else {
          setState(() => _estaCarregando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erro ao baixar a imagem.")),
          );
        }
      }
    }
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
      ),
      body: Column(
        children: [
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
        final item = _imagens[index];
        final String thumbUrl = item['thumbnailUrl'] ?? item['imageUrl'];

        return GestureDetector(
          onTap: () => _confirmarSelecao(item),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image),
              ),
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
                hintText: 'Pesquisar Imagem...',
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
