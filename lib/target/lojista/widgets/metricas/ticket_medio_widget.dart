// lib/target/lojista/widgets/metricas/ticket_medio_widget.dart

import 'package:flutter/material.dart';
import 'card_metrica.dart';

class WidgetTicketMedio extends StatelessWidget {
  final double valor;
  final bool carregando;

  const WidgetTicketMedio({
    super.key,
    required this.valor,
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    return CardMetricaBase(
      titulo: "Ticket Médio (Mês)",
      valor: "R\$ ${valor.toStringAsFixed(2)}",
      icone: Icons.analytics,
      cor: Colors.blue,
      carregando: carregando,
    );
  }
}
