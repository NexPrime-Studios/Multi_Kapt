import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'seletor_mapa.dart';
import 'package:latlong2/latlong.dart' as ll;

class EtapaLocalizacao extends StatefulWidget {
  final Map<String, TextEditingController> controllers;

  const EtapaLocalizacao({super.key, required this.controllers});

  @override
  State<EtapaLocalizacao> createState() => _EtapaLocalizacaoState();
}

class _EtapaLocalizacaoState extends State<EtapaLocalizacao> {
  List<dynamic> _municipiosBase = [];
  List<String> _estados = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDados();
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

  Future<void> _carregarDados() async {
    try {
      final String response = await rootBundle.loadString('municipios.json');
      final Map<String, dynamic> decoded = json.decode(response);

      if (decoded.containsKey('data')) {
        final List<dynamic> data = decoded['data'];
        if (mounted) {
          setState(() {
            _municipiosBase = data;
            _estados = data
                .map((m) => m['Uf'].toString().trim())
                .where((uf) => uf.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
            _carregando = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = "Erro ao carregar dados de localização.";
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    bool temCoordenadas = widget.controllers['lat']!.text.isNotEmpty &&
        widget.controllers['lng']!.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Endereço Completo",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controllers['end']!,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: "Rua, número, bairro...",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon:
                const Icon(Icons.location_on_outlined, color: Colors.blueGrey),
          ),
          validator: (v) => v == null || v.isEmpty ? "Campo obrigatório" : null,
        ),

        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Estado - UF",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    focusNode: FocusNode(canRequestFocus: false),
                    initialValue: widget.controllers['estado']!.text.isEmpty
                        ? null
                        : widget.controllers['estado']!.text,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: _estados
                        .map((uf) => DropdownMenuItem(
                            value: uf,
                            child: Text(uf,
                                style: const TextStyle(color: Colors.black))))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        widget.controllers['estado']!.text = val ?? "";
                        widget.controllers['cidade']!.clear();
                      });
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? "Obrigatório" : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Cidade",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (widget.controllers['estado']!.text.isEmpty) return [];
                      String busca = _removerAcentos(textEditingValue.text);
                      return _municipiosBase
                          .where((m) =>
                              m['Uf'] == widget.controllers['estado']!.text)
                          .map((m) => m['Nome'].toString())
                          .where(
                              (nome) => _removerAcentos(nome).contains(busca));
                    },
                    onSelected: (selection) =>
                        widget.controllers['cidade']!.text = selection,
                    fieldViewBuilder:
                        (context, textController, focusNode, onFieldSubmitted) {
                      if (widget.controllers['cidade']!.text.isNotEmpty &&
                          textController.text.isEmpty) {
                        textController.text =
                            widget.controllers['cidade']!.text;
                      }
                      return TextFormField(
                        controller: textController,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          hintText: widget.controllers['estado']!.text.isEmpty
                              ? "Selecione UF"
                              : "Digite...",
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Obrigatório" : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text("Localização Exata no Mapa",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 14)),
        const SizedBox(height: 8),

        // Validador Invisível para as coordenadas
        FormField<String>(
          validator: (_) {
            if (!temCoordenadas) {
              return "Você precisa marcar a localização no mapa";
            }
            return null;
          },
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ll.LatLng? resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SeletorMapa()),
                      );

                      if (resultado != null) {
                        setState(() {
                          widget.controllers['lat']!.text =
                              resultado.latitude.toString();
                          widget.controllers['lng']!.text =
                              resultado.longitude.toString();
                        });
                        state.didChange(
                            resultado.toString()); // Notifica o validador
                      }
                    },
                    icon: Icon(
                        temCoordenadas ? Icons.check_circle : Icons.map_sharp),
                    label: Text(temCoordenadas
                        ? "LOCALIZAÇÃO DEFINIDA"
                        : "ABRIR MAPA E MARCAR LOCAL"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: temCoordenadas
                          ? Colors.green[700]
                          : Colors.blueAccent,
                      foregroundColor: Colors.white,
                      side: state.hasError
                          ? const BorderSide(color: Colors.red, width: 2)
                          : null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(state.errorText!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            );
          },
        ),

        if (temCoordenadas)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Coordenadas: ${widget.controllers['lat']!.text}, ${widget.controllers['lng']!.text}",
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
      ],
    );
  }
}
