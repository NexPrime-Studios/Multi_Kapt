// lib/target/lojista/pages/tela_metricas.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/lojista_provider.dart';
import '../../../services/metricas_service.dart';
import '../widgets/metricas/valor_total_widget.dart';
import '../widgets/metricas/quantidade_pedidos_widget.dart';
import '../widgets/metricas/ticket_medio_widget.dart';

class TelaMetricas extends StatelessWidget {
  const TelaMetricas({super.key});

  @override
  Widget build(BuildContext context) {
    // Acesso ao provider para obter o ID do mercado atual
    final lojistaProvider = context.read<LojistaProvider>();
    final metricasService = MetricasService();

    // Verificação de segurança: Se por algum motivo o mercado for nulo, evita crash
    if (lojistaProvider.mercado == null) {
      return const Scaffold(
        body: Center(child: Text("Mercado não encontrado")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "RELATÓRIOS FINANCEIROS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        // Realiza uma única chamada à View do Supabase para otimizar a performance
        future: metricasService
            .buscarMetricasConsolidadas(lojistaProvider.mercado!.id),
        builder: (context, snapshot) {
          final bool carregando =
              snapshot.connectionState == ConnectionState.waiting;

          // Dados padrão caso a busca falhe ou esteja carregando
          final dados = snapshot.data ??
              {
                'pedidos_hoje': 0,
                'faturamento_hoje': 0.0,
                'ticket_medio_mes': 0.0,
              };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Faturamento Hoje (Ocupa a largura total)
              WidgetValorTotal(
                valor: (dados['faturamento_hoje'] as num).toDouble(),
                carregando: carregando,
              ),

              const SizedBox(height: 16),

              // Linha com Pedidos e Ticket Médio lado a lado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // O Expanded é usado AQUI, onde o pai é uma Row
                  Expanded(
                    child: WidgetQuantidadePedidos(
                      quantidade: (dados['pedidos_hoje'] as num).toInt(),
                      carregando: carregando,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: WidgetTicketMedio(
                      valor: (dados['ticket_medio_mes'] as num).toDouble(),
                      carregando: carregando,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Espaço reservado para expansões futuras (Gráficos, etc)
              if (!carregando)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "Métricas baseadas em pedidos com status 'entregue'.",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
