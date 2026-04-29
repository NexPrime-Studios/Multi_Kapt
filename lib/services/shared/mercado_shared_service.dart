import 'package:flutter/material.dart';
import 'package:mercado_app/models/item_mercado.dart';
import 'package:mercado_app/models/produto.dart';
import 'package:mercado_app/supabase_keys.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/mercado.dart';
import '../../models/pedido.dart';

class MercadoSharedService {
  final _supabase = Supabase.instance.client;

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - INICIAR/GERENCIAR MERCADO
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Future<Mercado?> buscarMercadoPorId(String id) async {
    try {
      final response = await _supabase
          .from(SupabaseKeys.tbMercados)
          .select()
          .eq('id', id)
          .single();

      return Mercado.fromMap(id, response);
    } catch (e) {
      debugPrint("Erro ao buscar dados do mercado: $e");
      return null;
    }
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - GESTÃO DE PRODUTOS GLOBAIS
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Future<void> criarAtualizarProdutoGlobal(Produto produto) async {
    try {
      final dadosProduto = produto.toMap();

      if (produto.id.isEmpty) {
        dadosProduto.remove('id');
      }

      await _supabase.from(SupabaseKeys.tbProdutosGlobal).upsert(dadosProduto);
    } catch (e) {
      debugPrint("Erro ao salvar produto global: $e");
      rethrow;
    }
  }

  Future<Produto?> buscarProdutoGlobal(String codigoBarras) async {
    try {
      final response = await _supabase
          .from(SupabaseKeys.tbProdutosGlobal)
          .select()
          .eq('codigo_barras', codigoBarras)
          .maybeSingle();

      if (response != null) {
        return Produto.fromMap(response['id'] as String, response);
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
          .from(SupabaseKeys.tbProdutosGlobal)
          .select()
          .or('codigo_barras.eq.$termoBusca,nome.ilike.%$termoBusca%');

      return response
          .map((map) => Produto.fromMap(map['id'] as String, map))
          .toList();
    } catch (e) {
      debugPrint("Erro ao buscar produto por termo: $e");
      return [];
    }
  }

  Future<List<Produto>> listarPrimeirosProdutosGlobais() async {
    try {
      // Busca os primeiros 20 itens da tabela
      final response = await _supabase
          .from(SupabaseKeys.tbProdutosGlobal)
          .select()
          .limit(20);

      final List<Produto> produtos = (response as List)
          .map((map) => Produto.fromMap(map['id'] as String, map))
          .toList();

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
  Future<void> adicionarAtualizarItemNoMercado(ItemMercado item) async {
    try {
      await _supabase.from(SupabaseKeys.tbProdutosMercado).upsert(item.toMap());
    } catch (e) {
      debugPrint("Erro ao salvar item no mercado: $e");
      rethrow;
    }
  }

  Future<void> removerItemDoMercado(String mercadoId, String produtoId) async {
    try {
      await _supabase
          .from(SupabaseKeys.tbProdutosMercado)
          .delete()
          .eq('mercado_id', mercadoId)
          .eq('produto_id', produtoId);
    } catch (e) {
      debugPrint("Erro ao remover item do mercado: $e");
      rethrow;
    }
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - BUSCAR ITEM
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Future<List<ItemMercado>> listarItensDoMercado(String mercadoId) async {
    try {
      final List<dynamic> response = await _supabase
          .from(SupabaseKeys.tbProdutosMercado)
          .select()
          .eq('mercado_id', mercadoId);

      return response.map((map) => ItemMercado.fromMap(map)).toList();
    } catch (e) {
      debugPrint("Erro ao listar itens do mercado: $e");
      return [];
    }
  }

  Future<ItemMercado?> buscarItemEspecificoNoMercado(
      String mercadoId, String produtoId) async {
    try {
      final response = await _supabase
          .from(SupabaseKeys.tbProdutosMercado)
          .select()
          .eq('mercado_id', mercadoId)
          .eq('produto_id', produtoId)
          .maybeSingle();

      if (response != null) {
        return ItemMercado.fromMap(response);
      }
      return null;
    } catch (e) {
      debugPrint("Erro ao buscar item específico: $e");
      return null;
    }
  }

  // ==========================================
  // GESTÃO DE PEDIDOS
  // ==========================================
  Stream<List<Pedido>> buscarPedidosAtivos(String mercadoId) {
    return _supabase
        .from(SupabaseKeys.tbViewPedidosAtivos)
        .stream(primaryKey: ['id'])
        .eq('mercado_id', mercadoId)
        .map((data) {
          return data.map((map) {
            try {
              return Pedido.fromMap(map['id'].toString(), map);
            } catch (e) {
              debugPrint('Erro de parsing no pedido ${map['id']}: $e');
              throw FormatException('Erro ao processar dados do pedido');
            }
          }).toList();
        })
        .handleError((error) {
          debugPrint('Erro no Stream de Pedidos: $error');
        });
  }
}
