import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../models/mercado.dart';
import '../../models/produto.dart';
import '../../models/item_mercado.dart';
import '../../models/pedido.dart';
import '../../models/funcionario.dart';

class LojistaService {
  final _supabase = Supabase.instance.client;

  SupabaseClient get supabase => _supabase;
  // ==========================================
  // GESTÃO DO MERCADO (PERFIL E STATUS)
  // ==========================================

  Future<String> adicionarMercado(Mercado mercado) async {
    try {
      final user = _supabase.auth.currentUser;
      final dados = mercado.toMap();
      dados['admin_uid'] = user?.id;

      final response =
          await _supabase.from('mercados').insert(dados).select('id').single();

      return response['id'].toString();
    } catch (e) {
      debugPrint("Erro ao adicionar mercado: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> buscarMercadosPorEmail() async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) return [];

    try {
      final response = await _supabase
          .from('funcionarios')
          .select('mercado_id, funcao, mercados(nome)')
          .eq('email', user.email!)
          .eq('ativo', true);

      final listaValida = (response as List).where((item) {
        return item['mercados'] != null && item['mercados']['nome'] != null;
      }).toList();

      return List<Map<String, dynamic>>.from(listaValida);
    } catch (e) {
      debugPrint("Erro ao buscar mercados: $e");
      return [];
    }
  }

  Future<void> atualizarMercado(Mercado mercado) async {
    try {
      await _supabase
          .from('mercados')
          .update(mercado.toMap())
          .eq('id', mercado.id);
    } catch (e) {
      debugPrint("Erro ao atualizar mercado: $e");
      rethrow;
    }
  }

  Future<void> atualizarStatusMercado(String mercadoId, bool aberto) async {
    try {
      await _supabase
          .from('mercados')
          .update({'esta_aberto': aberto}).eq('id', mercadoId);
    } catch (e) {
      debugPrint("Erro na rede: $e");
      rethrow;
    }
  }

  Stream<Mercado?> streamMercadoPorAdmin(String uid) {
    return _supabase.from('mercados').stream(primaryKey: ['id']).map((data) {
      final filtrado = data.where((m) => m['admin_uid'] == uid);
      if (filtrado.isNotEmpty) {
        return Mercado.fromMap(filtrado.first['id'], filtrado.first);
      }
      return null;
    });
  }

  // ==========================================
  // GESTÃO DE INVENTÁRIO (PRODUTOS DO MERCADO)
  // ==========================================

  Future<void> adicionarItemAoInventario(
      String mercadoId, ItemMercado novoItem) async {
    final res = await _supabase
        .from('mercados')
        .select('itens')
        .eq('id', mercadoId)
        .single();
    List itens = res['itens'] ?? [];
    itens.add(novoItem.toMap());

    await _supabase
        .from('mercados')
        .update({'itens': itens}).eq('id', mercadoId);
  }

  Future<void> atualizarDisponibilidadeItem(
      String mercadoId, String produtoId, bool disponivel) async {
    final res = await _supabase
        .from('mercados')
        .select('itens')
        .eq('id', mercadoId)
        .single();
    List itensMap = res['itens'] ?? [];

    List novosItens = itensMap.map((item) {
      if (item['produtoId'] == produtoId) item['disponivel'] = disponivel;
      return item;
    }).toList();

    await _supabase
        .from('mercados')
        .update({'itens': novosItens}).eq('id', mercadoId);
  }

  Future<void> removerItemDoInventario(
      String mercadoId, ItemMercado itemParaRemover) async {
    final res = await _supabase
        .from('mercados')
        .select('itens')
        .eq('id', mercadoId)
        .single();
    List itensMap = res['itens'] ?? [];

    itensMap.removeWhere((i) => i['produtoId'] == itemParaRemover.produtoId);

    await _supabase
        .from('mercados')
        .update({'itens': itensMap}).eq('id', mercadoId);
  }

  // ==========================================
  // GESTÃO DE PRODUTOS GLOBAIS (BIBLIOTECA)
  // ==========================================

  Stream<List<Produto>> listarProdutosGlobais() {
    return _supabase.from('produtos').stream(primaryKey: ['id']).map(
        (data) => data.map((map) => Produto.fromMap(map['id'], map)).toList());
  }

  Future<Produto?> buscarDetalheProduto(String id) async {
    final response =
        await _supabase.from('produtos').select().eq('id', id).maybeSingle();

    if (response != null) {
      return Produto.fromMap(response['id'], response);
    }
    return null;
  }

  Future<void> salvarProduto(Produto produto) async {
    try {
      if (produto.id.isNotEmpty) {
        await _supabase
            .from('produtos')
            .update(produto.toMap())
            .eq('id', produto.id);
      } else {
        await _supabase.from('produtos').insert(produto.toMap());
      }
    } catch (e) {
      debugPrint("Erro ao salvar produto global: $e");
      rethrow;
    }
  }

  // ==========================================
  // GESTÃO DE PEDIDOS
  // ==========================================

  Stream<List<Pedido>> buscarPedidosAtivos(String mercadoId) {
    return _supabase.from('pedidos').stream(primaryKey: ['id']).map((data) {
      return data
          .where(
              (p) => p['mercado_id'] == mercadoId && p['status'] != 'entregue')
          .map((map) => Pedido.fromMap(map['id'], map))
          .toList();
    });
  }

  Future<void> atualizarStatusPedido(
      String mercadoId, String pedidoId, String novoStatus) async {
    final res = await _supabase
        .from('pedidos')
        .select('horarios')
        .eq('id', pedidoId)
        .single();
    Map horarios = res['horarios'] ?? {};
    horarios[novoStatus] = DateTime.now().toIso8601String();

    await _supabase.from('pedidos').update({
      'status': novoStatus,
      'horarios': horarios,
    }).eq('id', pedidoId);
  }

  Future<void> atribuirFuncionarioAoPedido(
    String pedidoId,
    String nomeFuncionario,
    String codigoFuncionario,
  ) async {
    try {
      await _supabase.from('pedidos').update({
        'coletor_id': codigoFuncionario,
        'nome_coletor': nomeFuncionario,
      }).eq('id', pedidoId);
    } catch (e) {
      debugPrint("Erro ao atribuir funcionário: $e");
      rethrow;
    }
  }

  Future<PostgrestList> buscarHistoricoPedidosPaginados({
    required String mercadoId,
    required DateTime dataLimite,
    int offset = 0,
    int limit = 20,
  }) async {
    return await _supabase
        .from('pedidos')
        .select()
        .eq('mercado_id', mercadoId)
        .gte('data', dataLimite.toIso8601String())
        .order('data', ascending: false)
        .range(offset, offset + limit);
  }

  // ==========================================
  // Funcionarios
  // ==========================================

  Future<void> salvarFuncionario(Funcionario funcionario) async {
    try {
      if (funcionario.id.isNotEmpty) {
        await _supabase
            .from('funcionarios')
            .update(funcionario.toMap())
            .eq('id', funcionario.id);
      } else {
        await _supabase.from('funcionarios').insert(funcionario.toMap());
      }
    } catch (e) {
      debugPrint("Erro ao salvar funcionário: $e");
      rethrow;
    }
  }

  Stream<List<Funcionario>> listarFuncionarios(String mercadoId) {
    return _supabase
        .from('funcionarios')
        .stream(primaryKey: ['id'])
        .eq('mercado_id', mercadoId)
        .map((data) => data.map((map) => Funcionario.fromMap(map)).toList());
  }

  Future<void> alternarStatusFuncionario(String id, bool ativo) async {
    await _supabase.from('funcionarios').update({'ativo': ativo}).eq('id', id);
  }

  Future<Produto?> buscarProdutoPorCodigoBarras(String codigo) async {
    try {
      final response = await _supabase
          .from('produtos')
          .select()
          .eq('codigo_barras', codigo)
          .maybeSingle();

      if (response != null) {
        return Produto.fromMap(response['id'], response);
      }

      return null;
    } catch (e) {
      debugPrint("Erro ao buscar produto por EAN: $e");
      return null;
    }
  }
}
