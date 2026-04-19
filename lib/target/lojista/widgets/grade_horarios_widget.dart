import 'package:flutter/material.dart';
import '../../../models/horario_mercado.dart';

class GradeHorariosWidget extends StatelessWidget {
  final Map<String, DiaFuncionamento> grade;
  final Function(String, bool) onSelecionarHora;
  final Function(String, bool) onToggleDia;

  const GradeHorariosWidget({
    super.key,
    required this.grade,
    required this.onSelecionarHora,
    required this.onToggleDia,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: grade.keys.map((dia) {
        final info = grade[dia]!;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              SwitchListTile(
                title: Text(
                  dia.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: info.aberto,
                onChanged: (val) => onToggleDia(dia, val),
              ),
              if (info.aberto)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      ActionChip(
                        label: Text("Abre: ${info.abertura}"),
                        onPressed: () => onSelecionarHora(dia, true),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: Text("Fecha: ${info.fechamento}"),
                        onPressed: () => onSelecionarHora(dia, false),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
