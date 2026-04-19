import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../services/cliente_provider.dart';
import '../../../models/cliente.dart';

class SeletorCidadeDashboard extends StatefulWidget {
  const SeletorCidadeDashboard({super.key});

  @override
  State<SeletorCidadeDashboard> createState() => _SeletorCidadeDashboardState();
}

class _SeletorCidadeDashboardState extends State<SeletorCidadeDashboard> {
  List<dynamic> _municipiosBase = [];
  List<String> _estados = [];
  bool _carregando = true;

  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      // Caminho corrigido conforme sua verificação
      final String response =
          await rootBundle.loadString('assets/municipios.json');
      final Map<String, dynamic> decoded = json.decode(response);

      if (decoded.containsKey('data')) {
        _municipiosBase = decoded['data'];
        _estados = _municipiosBase
            .map((m) => m['Uf'].toString().trim())
            .where((uf) => uf.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
      }

      if (!mounted) return;
      final cliente = context.read<ClienteProvider>().cliente;
      if (cliente != null) {
        _estadoController.text = cliente.estado;
        _cidadeController.text = cliente.cidade;
      }

      setState(() => _carregando = false);
    } catch (e) {
      debugPrint("Erro ao carregar dados de localização: $e");
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _removerAcentos(String texto) {
    const comAcento =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const semAcento =
        'AAAAAAaaaaaaOOOOOOOoooooooEEEEeeeeoCçDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < comAcento.length; i++) {
      texto = texto.replaceAll(comAcento[i], semAcento[i]);
    }
    return texto.toLowerCase();
  }

  void _atualizarLocalizacaoLocal() {
    final provider = context.read<ClienteProvider>();
    final clienteAtual = provider.cliente;

    if (clienteAtual == null) return;

    final clienteAtualizado = clienteAtual.copyWith(
      estado: _estadoController.text,
      cidade: _cidadeController.text,
    );

    provider.salvarEAtualizarPerfil(clienteAtualizado);

    // Fecha o Pop-up
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Região de busca atualizada!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Material(
      // Garante que elementos de texto e campos tenham o tema correto
      color: Colors.transparent,
      child: Container(
        // O próprio script decide o tamanho agora
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Faz o pop-up não esticar verticalmente
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Onde você está?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Largura fixa para UF evita o "Left Overflow"
                SizedBox(
                  width: 85,
                  child: DropdownButtonFormField<String>(
                    value: _estadoController.text.isEmpty
                        ? null
                        : _estadoController.text,
                    isExpanded: true, // Garante que a seta não empurre o layout
                    decoration: InputDecoration(
                      labelText: "UF",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _estados
                        .map((uf) =>
                            DropdownMenuItem(value: uf, child: Text(uf)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _estadoController.text = val ?? "";
                        _cidadeController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Cidade expandida para ocupar o resto
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textValue) {
                      if (_estadoController.text.isEmpty) return [];
                      String busca = _removerAcentos(textValue.text);
                      return _municipiosBase
                          .where((m) => m['Uf'] == _estadoController.text)
                          .map((m) => m['Nome'].toString())
                          .where(
                              (nome) => _removerAcentos(nome).contains(busca));
                    },
                    onSelected: (selection) =>
                        setState(() => _cidadeController.text = selection),
                    fieldViewBuilder:
                        (context, fieldController, focusNode, onSubmitted) {
                      if (fieldController.text.isEmpty &&
                          _cidadeController.text.isNotEmpty) {
                        fieldController.text = _cidadeController.text;
                      }
                      return TextFormField(
                        controller: fieldController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: "Cidade",
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          hintText: _estadoController.text.isEmpty
                              ? "Selecione UF"
                              : "Digite...",
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_estadoController.text.isNotEmpty &&
                        _cidadeController.text.isNotEmpty)
                    ? _atualizarLocalizacaoLocal
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text(
                  "ATUALIZAR REGIÃO",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ),
            ),
            // Botão opcional para fechar sem salvar
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Center(
                child: Text("Cancelar", style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
