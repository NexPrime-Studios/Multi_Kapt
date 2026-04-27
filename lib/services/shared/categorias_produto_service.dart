import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/produto_enums.dart';

class CategoriasProdutoService {
  final _supabase = Supabase.instance.client;

  /// Método que estava faltando: busca o JSON completo da categoria
  Future<List<dynamic>> fetchDadosCompletosDaCategoria(
      CategoriaProduto categoria) async {
    try {
      final response = await _supabase
          .from('categorias_produtos')
          .select('dados')
          .eq('nome_categoria', categoria.name)
          .maybeSingle();

      if (response == null || response['dados'] == null) return [];

      return response['dados'] as List<dynamic>;
    } catch (e) {
      print('Erro ao buscar dados da categoria: $e');
      return [];
    }
  }

  /// Método para salvar novos itens (RPC)
  Future<void> salvarEstruturaProdutoCompleta({
    required CategoriaProduto categoria,
    required String nomeSubcategoria,
    required String nomeProdutoBase,
    required List<String> variacoes,
  }) async {
    try {
      await _supabase.rpc('upsert_produto_hierarquico', params: {
        'p_categoria': categoria.name,
        'p_subcategoria': nomeSubcategoria,
        'p_produto': nomeProdutoBase,
        'p_variacoes': variacoes,
      });
    } catch (e) {
      print('Erro ao salvar estrutura: $e');
      rethrow;
    }
  }
}
