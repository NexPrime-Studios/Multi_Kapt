// lib/target/lojista/widgets/metricas/quantidade_pedidos_widget.dart
import 'package:flutter/material.dart';
import 'card_metrica.dart';

class WidgetQuantidadePedidos extends StatelessWidget {
  final int quantidade;
  final bool carregando;

  const WidgetQuantidadePedidos(
      {super.key, required this.quantidade, this.carregando = false});

  @override
  Widget build(BuildContext context) {
    // Certifique-se de que NÃO há um Expanded aqui
    return CardMetricaBase(
      titulo: "Pedidos Hoje",
      valor: "$quantidade",
      icone: Icons.shopping_basket,
      cor: Colors.orange,
      carregando: carregando,
    );
  }
}
