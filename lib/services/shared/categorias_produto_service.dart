import 'package:supabase_flutter/supabase_flutter.dart';

class CategoriasProdutoService {
  final _supabase = Supabase.instance.client;

  /// Método base que busca os dados brutos do Supabase
  Future<List<Map<String, dynamic>>> buscarBasesEVariacoes(
      String categoria) async {
    try {
      final List<dynamic> response = await _supabase.rpc(
        'get_produtos_base_por_categoria',
        params: {'p_categoria': categoria},
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar produtos base: $e');
      return [];
    }
  }

  /// Retorna apenas os nomes únicos dos "produtos base" para a categoria
  Future<List<String>> buscarApenasBases(String categoria) async {
    final dados = await buscarBasesEVariacoes(categoria);

    // Extrai o campo 'produto_base', remove nulos e duplicatas
    return dados
        .map((item) => item['produto_base'] as String)
        .toSet() // O Set remove automaticamente duplicatas
        .toList()
      ..sort(); // Ordena alfabeticamente
  }

  /// Retorna as variações disponíveis para um "produto base" específico dentro de uma categoria
  Future<List<String>> buscarVariacoesPorBase(
      String categoria, String produtoBase) async {
    final dados = await buscarBasesEVariacoes(categoria);

    // Filtra apenas os itens que pertencem ao produto base escolhido
    return dados
        .where((item) => item['produto_base'] == produtoBase)
        .map((item) => item['variacao'] as String)
        .toSet()
        .toList()
      ..sort();
  }
}
