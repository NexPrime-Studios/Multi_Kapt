import 'package:flutter/material.dart';
import 'package:mercado_app/models/item_mercado.dart';
import 'package:mercado_app/models/produto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/mercado.dart';

class MercadoSharedService {
  final _supabase = Supabase.instance.client;

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - INICIAR/GERENCIAR MERCADO
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Future<Mercado?> buscarMercadoPorId(String id) async {
    try {
      final response =
          await _supabase.from('mercados').select().eq('id', id).single();

      return Mercado.fromMap(id, response);
    } catch (e) {
      debugPrint("Erro ao buscar dados do mercado: $e");
      return null;
    }
  }

  Stream<Mercado> streamMercado(String id) {
    return _supabase
        .from('mercados')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((lista) => Mercado.fromMap(id, lista.first));
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - GESTÃO DE PRODUTOS GLOBAIS
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Future<void> salvarProdutoGlobal(Produto produto) async {
    try {
      final dadosProduto = produto.toMap();

      if (produto.id.isNotEmpty) {
        await _supabase
            .from('produtos')
            .update(dadosProduto)
            .eq('id', produto.id);
      } else {
        dadosProduto.remove('id');
        await _supabase.from('produtos').insert(dadosProduto);
      }
    } catch (e) {
      debugPrint("Erro ao salvar produto global: $e");
      rethrow;
    }
  }

  Future<Produto?> buscarProdutoGlobal(String codigoBarras) async {
    try {
      final response = await _supabase
          .from('produtos')
          .select()
          .eq('codigo_barras', codigoBarras)
          .maybeSingle();

      if (response != null) {
        return Produto.fromMap(response['id'], response);
      }
      return null;
    } catch (e) {
      debugPrint("Erro ao buscar produto global por EAN: $e");
      return null;
    }
  }

  Future<List<Produto>> buscarProdutosGlobaisPorTermo(String termoBusca) async {
    try {
      final response = await _supabase
          .from('produtos')
          .select()
          .or('codigo_barras.eq.$termoBusca,nome.ilike.%$termoBusca%');

      return response
          .map((map) => Produto.fromMap(map['id'] as String, map))
          .toList();
    } catch (e) {
      debugPrint("Erro ao buscar produto global: $e");
      return [];
    }
  }

  Future<List<Produto>> listarProdutosGlobais() async {
    try {
      // Busca os primeiros 20 itens da tabela 'produtos' no Supabase
      final List<dynamic> data =
          await _supabase.from('produtos').select().limit(20);

      final produtos =
          data.map((map) => Produto.fromMap(map['id'], map)).toList();

      produtos.shuffle();
      return produtos;
    } catch (e) {
      debugPrint("Erro ao buscar e embaralhar produtos: $e");
      return [];
    }
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - GESTÃO DE INVENTÁRIO
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Future<void> adicionarItemAoInventario(
      String mercadoId, ItemMercado novoItem) async {
    try {
      final itens = await _getItensDoMercado(mercadoId);

      // Evita duplicação por código de barras
      if (!itens.any((i) => i['codigo_barras'] == novoItem.codigoBarras)) {
        itens.add(novoItem.toMap());
        await _updateItens(mercadoId, itens);
      }
    } catch (e) {
      debugPrint("Erro ao adicionar item: $e");
      rethrow;
    }
  }

  Future<void> atualizarItemNoInventario(
      String mercadoId, ItemMercado itemAtualizado) async {
    try {
      // Busca a lista atual de itens (geralmente do Firestore ou DB local)
      final itens = await _getItensDoMercado(mercadoId);

      final novosItens = itens.map((itemMap) {
        // Se encontrar o código de barras, substitui o mapa inteiro
        if (itemMap['codigo_barras'] == itemAtualizado.codigoBarras) {
          return itemAtualizado
              .toMap(); // Certifique-se de ter o método toMap() no seu Model
        }
        return itemMap;
      }).toList();

      await _updateItens(mercadoId, novosItens);
    } catch (e) {
      debugPrint("Erro ao atualizar item no service: $e");
      rethrow;
    }
  }

  Future<void> removerItemDoInventario(
      String mercadoId, String codigoBarras) async {
    try {
      final itens = await _getItensDoMercado(mercadoId);

      itens.removeWhere((item) => item['codigo_barras'] == codigoBarras);

      await _updateItens(mercadoId, itens);
    } catch (e) {
      debugPrint("Erro ao remover item: $e");
      rethrow;
    }
  }

  // ----------- METODOS AUXILIARES -----------
  Future<List<Map<String, dynamic>>> _getItensDoMercado(
      String mercadoId) async {
    final res = await _supabase
        .from('mercados')
        .select('itens')
        .eq('id', mercadoId)
        .single();

    // Converte para List<Map<String, dynamic>> garantindo mutabilidade
    final List rawList = res['itens'] ?? [];
    return List<Map<String, dynamic>>.from(rawList);
  }

  Future<void> _updateItens(String mercadoId, List itens) async {
    await _supabase
        .from('mercados')
        .update({'itens': itens}).eq('id', mercadoId);
  }
}
