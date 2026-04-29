import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../services/shared/user_provider.dart';

class SeletorLocalizacaoWidget extends StatefulWidget {
  const SeletorLocalizacaoWidget({super.key});

  @override
  State<SeletorLocalizacaoWidget> createState() =>
      _SeletorLocalizacaoWidgetState();
}

class _SeletorLocalizacaoWidgetState extends State<SeletorLocalizacaoWidget> {
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

      final provider = context.read<UserProvider>();
      final cliente = provider.usuario;

      // Carrega os dados existentes (prioriza o objeto cliente, depois o provider)
      String estadoInicial = cliente?.estado ?? provider.estado;
      String cidadeInicial = cliente?.cidade ?? provider.cidade;

      setState(() {
        _estadoController.text = estadoInicial;
        _cidadeController.text = cidadeInicial;
        _carregando = false;
      });
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
    final provider = context.read<UserProvider>();
    final clienteAtual = provider.usuario;

    final novaCidade = _cidadeController.text;
    final novoEstado = _estadoController.text;

    if (clienteAtual != null) {
      final clienteAtualizado = clienteAtual.copyWith(
        estado: novoEstado,
        cidade: novaCidade,
      );
      provider.salvarEAtualizarPerfil(clienteAtualizado);
    } else {
      provider.definirLocalizacaoLocal(novaCidade, novoEstado);
    }

    if (mounted) Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Região atualizada para $novaCidade - $novoEstado!"),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_rounded, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  "Onde você quer pesquisar?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- DROPDOWN UF COM CORREÇÃO DE ASSERTION ---
                SizedBox(
                  width: 90,
                  child: DropdownButtonFormField<String>(
                    // AQUI ESTÁ A CORREÇÃO:
                    // Se o estado salvo não existir na lista do JSON, fica null e não quebra.
                    initialValue: _estados.contains(_estadoController.text)
                        ? _estadoController.text
                        : null,
                    isExpanded: true,
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

                // --- AUTOCOMPLETE CIDADE ---
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
                      // Sincroniza o controller do autocomplete com o valor salvo
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

            // --- BOTÃO ATUALIZAR ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    _isLocalizacaoValida() ? _atualizarLocalizacaoLocal : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 225, 255),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
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
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isLocalizacaoValida() {
    final estado = _estadoController.text;
    final cidade = _cidadeController.text;

    if (estado.isEmpty || cidade.isEmpty) return false;

    // Verifica se o estado digitado existe na lista de estados
    if (!_estados.contains(estado)) return false;

    // Verifica se a cidade digitada existe na lista de municípios para aquele estado
    bool cidadeExisteNoEstado = _municipiosBase.any((m) =>
        m['Uf'] == estado &&
        m['Nome'].toString().toLowerCase() == cidade.toLowerCase());

    return cidadeExisteNoEstado;
  }
}
