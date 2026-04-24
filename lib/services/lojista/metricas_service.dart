// lib/services/metricas_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class MetricasService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> buscarMetricasConsolidadas(
      String mercadoId) async {
    try {
      final data = await _supabase
          .from('metricas_mercado')
          .select()
          .eq('mercado_id', mercadoId)
          .maybeSingle();

      if (data == null) {
        return {
          'pedidos_hoje': 0,
          'faturamento_hoje': 0.0,
          'ticket_medio_mes': 0.0,
        };
      }

      return {
        'pedidos_hoje': data['pedidos_hoje'] ?? 0,
        'faturamento_hoje': (data['faturamento_hoje'] ?? 0.0).toDouble(),
        'ticket_medio_mes': (data['ticket_medio_mes'] ?? 0.0).toDouble(),
      };
    } catch (e) {
      debugPrint("Erro ao buscar métricas da View: $e");
      return {
        'pedidos_hoje': 0,
        'faturamento_hoje': 0.0,
        'ticket_medio_mes': 0.0,
      };
    }
  }
}
