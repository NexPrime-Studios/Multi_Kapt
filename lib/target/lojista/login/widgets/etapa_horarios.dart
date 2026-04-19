import 'package:flutter/material.dart';
import '../../widgets/grade_horarios_widget.dart';
import '../../../../models/horario_mercado.dart';

class EtapaHorarios extends StatelessWidget {
  final Map<String, DiaFuncionamento> grade;
  // Adicione estes dois callbacks
  final Function(String, bool) onSelecionarHora;
  final Function(String, bool) onToggleDia;

  const EtapaHorarios({
    super.key,
    required this.grade,
    required this.onSelecionarHora,
    required this.onToggleDia,
  });

  @override
  Widget build(BuildContext context) {
    return GradeHorariosWidget(
      grade: grade,
      onSelecionarHora: onSelecionarHora, // Repassa a função vinda do pai
      onToggleDia: onToggleDia, // Repassa a função vinda do pai
    );
  }
}
