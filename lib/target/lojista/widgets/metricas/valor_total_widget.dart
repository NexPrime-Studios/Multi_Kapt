// lib/target/lojista/widgets/metricas/valor_total_widget.dart

import 'package:flutter/material.dart';
import 'card_metrica.dart';

class WidgetValorTotal extends StatelessWidget {
  final double valor;
  final bool carregando;

  const WidgetValorTotal(
      {super.key, required this.valor, this.carregando = false});

  @override
  Widget build(BuildContext context) {
    return CardMetricaBase(
      titulo: "Faturamento Hoje",
      valor: "R\$ ${valor.toStringAsFixed(2)}",
      icone: Icons.attach_money,
      cor: Colors.green,
      carregando: carregando,
    );
  }
}
