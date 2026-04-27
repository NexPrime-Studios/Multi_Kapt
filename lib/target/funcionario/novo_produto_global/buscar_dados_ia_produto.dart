import 'package:flutter/material.dart';
import 'package:mercado_app/services/shared/gemini_services.dart';

class BuscarDadosIAProduto {
  Future<String?> selecionarDado(
      BuildContext context, String barcode, bool buscarNome) async {
    // Retorna o texto final após seleção e edição no popup
    final String? resultadoFinal = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelecaoDadosIA(barcode: barcode, modoNome: buscarNome),
      ),
    );

    return resultadoFinal;
  }
}

class SelecaoDadosIA extends StatefulWidget {
  final String barcode;
  final bool modoNome;
  const SelecaoDadosIA(
      {super.key, required this.barcode, required this.modoNome});

  @override
  State<SelecaoDadosIA> createState() => _SelecaoDadosIAState();
}

class _SelecaoDadosIAState extends State<SelecaoDadosIA> {
  final GeminiService _gemini = GeminiService();
  bool _isLoading = true;
  Map<String, dynamic>? _dados;

  // Lista para controlar quais itens estão selecionados
  final List<String> _selecionados = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() async {
    final res = await _gemini.buscarDadosProduto(widget.barcode);
    if (mounted) {
      setState(() {
        _dados = res;
        _isLoading = false;
      });
    }
  }

  void _abrirPopupEdicao() {
    if (_selecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione ao menos uma opção!")),
      );
      return;
    }

    String textoUnido = _selecionados.join(widget.modoNome ? " " : "\n\n");
    final TextEditingController editController =
        TextEditingController(text: textoUnido);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Column(
          children: [
            // Botão "X" no topo direito
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.modoNome ? "Revisar Nome" : "Revisar Descrição",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          child: TextField(
            controller: editController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              hintText: "Edite o texto final...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  String textoFinal = editController.text;
                  Navigator.pop(context);
                  Navigator.pop(this.context, textoFinal);
                },
                child: const Text(
                  "FINALIZAR",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modoNome ? "Compor Nome" : "Compor Descrição"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dados == null
              ? const Center(child: Text("Erro ao carregar dados"))
              : Column(
                  children: [
                    // Cabeçalho fixo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "MARCA: ${_dados!['marca']?.toString().toUpperCase()}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text("CATEGORIA: ${_dados!['categoria']}"),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            "Selecione as opções para combinar:",
                            style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ...((widget.modoNome
                                  ? _dados!['nome']
                                  : _dados!['descricao']) as List)
                              .map((item) {
                            final bool isSelected =
                                _selecionados.contains(item);
                            return Card(
                              elevation: isSelected ? 2 : 0,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CheckboxListTile(
                                title: Text(item,
                                    style: const TextStyle(fontSize: 14)),
                                value: isSelected,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selecionados.add(item);
                                    } else {
                                      _selecionados.remove(item);
                                    }
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    // Botão de rodapé para prosseguir
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _abrirPopupEdicao,
                          icon: const Icon(Icons.add_task),
                          label: const Text("ADICIONAR E REVISAR",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
