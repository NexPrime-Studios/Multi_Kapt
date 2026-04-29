import 'package:flutter/material.dart';
import 'package:mercado_app/models/item_mercado.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/funcionario.dart';
import '../../models/mercado.dart';
import '../../models/produto.dart';

class FuncionarioService {
  final _supabase = Supabase.instance.client;

  // --- PERSISTÊNCIA LOCAL ---

  /// Salva o vínculo do funcionário no dispositivo
  Future<void> marcarComoFuncionario(
      String mercadoId, String funcionarioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_funcionario', true);
    await prefs.setString('mercado_vinculado_id', mercadoId);
    await prefs.setString('funcionario_id', funcionarioId);
  }

  // --- BUSCA DE DADOS (SUPABASE) ---

  /// Busca o nome do mercado pelo ID para exibição no aviso de vínculo
  Future<String?> buscarNomeMercado(String mercadoId) async {
    try {
      final response = await _supabase
          .from('mercados')
          .select('nome')
          .eq('id', mercadoId)
          .maybeSingle();

      return response?['nome'];
    } catch (e) {
      debugPrint("Erro ao buscar nome do mercado: $e");
      return null;
    }
  }

  /// Busca o nome do funcionário validando se ele pertence ao mercado específico
  Future<String?> buscarNomeFuncionarioParaVinculo(
      String funcionarioId, String mercadoId) async {
    try {
      final response = await _supabase
          .from('funcionarios')
          .select('nome')
          .eq('id', funcionarioId)
          .eq('mercado_id', mercadoId)
          .maybeSingle();

      return response?['nome'];
    } catch (e) {
      debugPrint("Erro ao buscar nome do funcionário para vínculo: $e");
      return null;
    }
  }

  /// Busca os IDs necessários através do código manual (Ex: ABC123)
  Future<Map<String, dynamic>?> buscarDadosPorCodigoManual(
      String codigo) async {
    try {
      final response = await _supabase
          .from('funcionarios')
          .select('id, mercado_id')
          .eq('codigo_id', codigo.toUpperCase().trim())
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint("Erro ao buscar dados por código manual: $e");
      return null;
    }
  }

  /// Busca os detalhes completos do funcionário pelo ID (usado no perfil)
  Future<Funcionario?> buscarDadosFuncionario(String id) async {
    try {
      final response =
          await _supabase.from('funcionarios').select().eq('id', id).single();

      return Funcionario.fromMap(response);
    } catch (e) {
      debugPrint("Erro ao buscar dados do funcionário: $e");
      return null;
    }
  }

  /// Busca os dados do mercado onde o funcionário trabalha
  Future<Mercado?> buscarMercadoVinculado(String mercadoId) async {
    try {
      final response = await _supabase
          .from('mercados')
          .select()
          .eq('id', mercadoId)
          .single();

      return Mercado.fromMap(response['id'], response);
    } catch (e) {
      debugPrint("Erro ao buscar mercado vinculado: $e");
      return null;
    }
  }

  // --- GESTÃO DE PEDIDOS ---

  Stream<List<Map<String, dynamic>>> streamPedidos(String mercadoId) {
    return _supabase
        .from('pedidos')
        .stream(primaryKey: ['id'])
        .eq('mercado_id', mercadoId)
        .order('data', ascending: false)
        .map((dados) {
          return dados.where((p) {
            final status = p['status']?.toString().toLowerCase();
            return status != 'cancelado' && status != 'entregue';
          }).toList();
        });
  }

  Future<void> atualizarStatusPedido({
    required String pedidoId,
    required String novoStatus,
    String? funcionarioNome,
    String? funcionarioCodigo,
  }) async {
    try {
      final res = await _supabase
          .from('pedidos')
          .select('horarios')
          .eq('id', pedidoId)
          .single();

      Map<String, dynamic> horarios =
          Map<String, dynamic>.from(res['horarios'] ?? {});

      horarios[novoStatus] = DateTime.now().toIso8601String();

      final Map<String, dynamic> dadosParaAtualizar = {
        'status': novoStatus,
        'horarios': horarios,
      };

      if (novoStatus == 'preparando') {
        dadosParaAtualizar['nome_coletor'] = funcionarioNome;
        dadosParaAtualizar['coletor_id'] = funcionarioCodigo;
      }

      if (novoStatus == 'saiu_para_entrega') {
        dadosParaAtualizar['nome_entregador'] = funcionarioNome;
        dadosParaAtualizar['entregador_id'] = funcionarioCodigo;
      }

      await _supabase
          .from('pedidos')
          .update(dadosParaAtualizar)
          .eq('id', pedidoId);
    } catch (e) {
      debugPrint("Erro detalhado no Supabase: $e");
      rethrow;
    }
  }

  Future<void> finalizarSeparacaoPedido({
    required String pedidoId,
    required List itensAtualizados,
  }) async {
    try {
      final response = await _supabase
          .from('pedidos')
          .select('horarios, total')
          .eq('id', pedidoId)
          .single();

      Map<String, dynamic> horariosAtuais =
          Map<String, dynamic>.from(response['horarios'] ?? {});

      horariosAtuais['pronto'] = DateTime.now().toIso8601String();

      double novoTotalPedido = 0;
      for (var item in itensAtualizados) {
        novoTotalPedido +=
            (item['preco_final'] ?? item['preco'] ?? 0).toDouble();
      }

      // 4. Update completo
      await _supabase.from('pedidos').update({
        'status': 'pronto',
        'itens': itensAtualizados,
        'horarios': horariosAtuais,
        'total': novoTotalPedido,
      }).eq('id', pedidoId);
    } catch (e) {
      throw Exception("Erro ao finalizar separação: $e");
    }
  }

  Future<Map<String, dynamic>?> buscarProdutoPorCodigo(
      String codigoBarras, String mercadoId) async {
    try {
      final response = await _supabase
          .from('mercados')
          .select('itens')
          .eq('id', mercadoId)
          .single();

      final List<dynamic> todosOsItens = response['itens'] ?? [];

      // 2. Procuramos na lista o produto que possui o código de barras lido
      final produtoEncontrado = todosOsItens.firstWhere(
        (item) =>
            item['codigo_barras']?.toString().trim() == codigoBarras.trim(),
        orElse: () => null,
      );

      if (produtoEncontrado != null) {
        return Map<String, dynamic>.from(produtoEncontrado);
      }

      return null;
    } catch (e) {
      debugPrint("Erro ao buscar produto no JSON do mercado: $e");
      return null;
    }
  }

  Future<List<Produto>> buscarProdutosGlobais({String termo = ""}) async {
    try {
      var query = _supabase.from('produtos').select();

      if (termo.isNotEmpty) {
        query = query.or('nome.ilike.%$termo%,codigo_barras.ilike.%$termo%');
      }

      final response = await query.order('nome', ascending: true);

      return (response as List)
          .map((map) => Produto.fromMap(map['id'], map))
          .toList();
    } catch (e) {
      debugPrint("Erro ao buscar produtos globais: $e");
      return [];
    }
  }

  Future<void> adicionarItemAoInventario(
      String mercadoId, ItemMercado novoItem) async {
    try {
      // 1. Busca os itens atuais do mercado
      final res = await _supabase
          .from('mercados')
          .select('itens')
          .eq('id', mercadoId)
          .single();

      List itens = res['itens'] ?? [];

      // 2. Adiciona o novo item (convertido para Map)
      itens.add(novoItem.toMap());

      // 3. Atualiza a tabela mercados
      await _supabase
          .from('mercados')
          .update({'itens': itens}).eq('id', mercadoId);
    } catch (e) {
      debugPrint("Erro ao adicionar item ao inventário: $e");
      rethrow;
    }
  }
}
