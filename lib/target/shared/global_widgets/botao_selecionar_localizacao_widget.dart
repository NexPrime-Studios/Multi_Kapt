import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../pages/mapa_selecao_page.dart';

class CampoSelecionarLocalizacaoWidget extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final Function(LatLng) onLocationSelected;

  const CampoSelecionarLocalizacaoWidget({
    super.key,
    this.latitude,
    this.longitude,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    bool localizacaoOk = latitude != null && longitude != null;

    return Card(
      elevation: 0,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue[100]!, width: 1), // Borda sutil
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER COM ÍCONE DE ATENÇÃO ---
            Row(
              children: [
                Icon(Icons.report_problem_rounded,
                    color: const Color.fromARGB(255, 0, 0, 0), size: 20),
                const SizedBox(width: 8),
                Text(
                  "Localização Necessária",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // --- DESCRIÇÃO ---
            Text(
              "Para continuar, precisamos que você selecione o ponto exato no mapa.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // --- O BOTÃO ---
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final LatLng? res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TelaMapaSelecao(
                        posicaoInicial: LatLng(-23.55, -46.63),
                      ),
                    ),
                  );
                  if (res != null) onLocationSelected(res);
                },
                icon: Icon(localizacaoOk ? Icons.location_on : Icons.map),
                label: Text(
                  localizacaoOk ? "ALTERAR LOCALIZAÇÃO" : "SELECIONAR LOCAL",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: localizacaoOk
                      ? Colors.green[600]
                      : const Color.fromARGB(255, 0, 0, 0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            if (localizacaoOk)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      "Lat: ${latitude!.toStringAsFixed(4)}, Long: ${longitude!.toStringAsFixed(4)}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
