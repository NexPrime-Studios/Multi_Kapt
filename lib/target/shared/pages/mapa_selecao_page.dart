import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class TelaMapaSelecao extends StatefulWidget {
  final LatLng posicaoInicial;

  const TelaMapaSelecao({super.key, required this.posicaoInicial});

  @override
  State<TelaMapaSelecao> createState() => _TelaMapaSelecaoState();
}

class _TelaMapaSelecaoState extends State<TelaMapaSelecao> {
  late LatLng _pontoAtual;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _pontoAtual = widget.posicaoInicial;
  }

  Future<void> _buscarEndereco() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _buscando = true);

    try {
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final novaPos =
            LatLng(locations.first.latitude, locations.first.longitude);
        _moverPara(novaPos);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Endereço não encontrado ou serviço indisponível.")),
      );
    } finally {
      setState(() => _buscando = false);
    }
  }

  void _moverPara(LatLng pos) {
    setState(() => _pontoAtual = pos);
    _mapController.move(pos, 16);
    FocusScope.of(context).unfocus();
  }

  Future<void> _irParaMinhaLocalizacao() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition();
      _moverPara(LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Não foi possível obter a sua localização.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final larguraTela = MediaQuery.of(context).size.width;
    final isWebPC = larguraTela > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecione o local",
            style: TextStyle(color: Colors.black, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // 1. O MAPA (Ocupa todo o fundo)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pontoAtual,
              initialZoom: 16,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) _pontoAtual = pos.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.maptiler.com/maps/basic/{z}/{x}/{y}.png?key=JtnonX09fMRm7ejYxIt4',
                userAgentPackageName: 'com.example.mercado_app',
              ),
            ],
          ),

          // 2. BARRA DE PESQUISA (Corrigida para evitar erro de largura infinita)
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: SizedBox(
                  // Define um tamanho real para o telemóvel e um fixo para o PC
                  width: isWebPC ? 500 : larguraTela - 30,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5))
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _buscarEndereco(),
                      decoration: InputDecoration(
                        hintText: "Procurar rua, bairro ou cidade...",
                        prefixIcon: Icon(Icons.search, color: cores.primary),
                        suffixIcon: _buscando
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _searchController.clear()),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. PIN CENTRAL (Ignora toques para não atrapalhar o mapa)
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35),
                child: Icon(Icons.location_pin, color: cores.primary, size: 50),
              ),
            ),
          ),

          // 4. BOTÃO DE LOCALIZAÇÃO ATUAL
          Positioned(
            bottom: 30,
            right: 16,
            child: FloatingActionButton(
              heroTag: "btn_mapa_gps",
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _irParaMinhaLocalizacao,
              child: Icon(Icons.my_location, color: cores.primary),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, _pontoAtual),
            child: const Text("CONFIRMAR LOCALIZAÇÃO",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
