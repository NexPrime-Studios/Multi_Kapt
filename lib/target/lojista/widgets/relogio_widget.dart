import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RelogioDigital extends StatefulWidget {
  const RelogioDigital({super.key});

  @override
  State<RelogioDigital> createState() => _RelogioDigitalState();
}

class _RelogioDigitalState extends State<RelogioDigital> {
  late DateTime _agora;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _agora = DateTime.now();
    // Atualiza a cada minuto é suficiente já que não mostramos segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _agora = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Especificar o locale 'pt_BR' explicitamente nos formatadores
    final String horaFormatada = DateFormat('HH:mm').format(_agora);
    final String diaSemana =
        DateFormat('EEEE', 'pt_BR').format(_agora).toUpperCase();
    final String dataFormatada =
        DateFormat('dd/MM/yyyy', 'pt_BR').format(_agora);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone de tempo sutil
          const Icon(Icons.access_time_filled,
              size: 18, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                horaFormatada,
                style: const TextStyle(
                  fontSize: 20, // Tamanho menor e elegante
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D2D2D),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                "$diaSemana, $dataFormatada",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
