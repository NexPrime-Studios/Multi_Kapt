import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class SeletorMapa extends StatefulWidget {
  const SeletorMapa({super.key});

  @override
  State<SeletorMapa> createState() => _SeletorMapaState();
}

class _SeletorMapaState extends State<SeletorMapa> {
  LatLng _pontoSelecionado = const LatLng(-23.5505, -46.6333);
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _sugestoes = [];
  bool _estaPesquisando = false;

  Future<void> _buscarEndereco(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _estaPesquisando = true;
      _sugestoes = [];
    });

    try {
      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5");

      final response =
          await http.get(url, headers: {'User-Agent': 'MercadoApp_V1'});

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          setState(() {
            _sugestoes = decoded;
          });
        }
      }
    } catch (e) {
      debugPrint("Erro na busca: $e");
    } finally {
      if (mounted) setState(() => _estaPesquisando = false);
    }
  }

  Future<void> _irParaLocalizacaoAtual() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition();
        LatLng novaPos = LatLng(position.latitude, position.longitude);

        setState(() => _pontoSelecionado = novaPos);
        _mapController.move(novaPos, 16);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível acessar o GPS.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marcar Localização"),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pontoSelecionado,
              initialZoom: 15,
              onTap: (_, point) => setState(() => _pontoSelecionado = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mercado.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pontoSelecionado,
                    width: 80,
                    height: 80,
                    child: const Icon(Icons.location_on,
                        color: Colors.red, size: 45),
                  ),
                ],
              ),
            ],
          ),

          // Barra de Pesquisa no Topo
          Positioned(
            top: 20,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10)
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    onSubmitted: _buscarEndereco,
                    decoration: InputDecoration(
                      // TEXTO ALTERADO CONFORME SOLICITADO
                      hintText: "Coloque o cep ou procure por sua cidade",
                      hintStyle:
                          const TextStyle(color: Colors.black38, fontSize: 14),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.black54),
                      suffixIcon: _estaPesquisando
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.blueAccent))
                          : IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.black54),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _sugestoes = []);
                              }),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                // Resultados
                if (_sugestoes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 5)
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _sugestoes.length,
                      itemBuilder: (context, i) {
                        final item = _sugestoes[i];
                        final String label =
                            item['display_name']?.toString() ?? "";

                        return ListTile(
                          dense: true,
                          title: Text(label,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 13)),
                          onTap: () {
                            try {
                              double lat = double.parse(item['lat'].toString());
                              double lon = double.parse(item['lon'].toString());
                              LatLng pos = LatLng(lat, lon);
                              setState(() {
                                _pontoSelecionado = pos;
                                _sugestoes = [];
                                _searchController.text = label;
                              });
                              _mapController.move(pos, 16);
                            } catch (e) {
                              debugPrint("Erro ao converter coordenadas: $e");
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Botão Localização Atual (GPS)
          Positioned(
            bottom: 30,
            right: 15,
            child: FloatingActionButton.extended(
              heroTag: "btn_gps",
              backgroundColor: Colors.white,
              onPressed: _irParaLocalizacaoAtual,
              // Ícone que aparece à esquerda do texto
              icon: const Icon(Icons.my_location, color: Colors.blueAccent),
              // Texto que você solicitou
              label: const Text(
                "BUSCAR LOCALIZAÇÃO ATUAL",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // BOTÃO SALVAR CENTRALIZADO NA PARTE DE BAIXO
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 220,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _pontoSelecionado),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 221, 255),
                    foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "SALVAR LOCALIZAÇÃO",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
