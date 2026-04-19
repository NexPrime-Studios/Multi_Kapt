import 'package:flutter/material.dart';

class CardMetricaBase extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;
  final bool carregando;

  const CardMetricaBase({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    // REMOVIDO: O Expanded foi removido daqui para evitar erros de ParentData
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: carregando
            ? const SizedBox(
                height: 80, // Altura mínima para o loading não achatar o card
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min, // Ocupa apenas o espaço necessário
                children: [
                  Icon(icone, color: cor, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    titulo,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
