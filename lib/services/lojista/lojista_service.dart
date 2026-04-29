import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../models/mercado.dart';
import '../../models/pedido.dart';
import '../../models/funcionario.dart';
import '../../supabase_keys.dart';

class LojistaService {
  final _supabase = Supabase.instance.client;

  // ==========================================
  // GESTÃO DO MERCADO (PERFIL E STATUS)
  // ==========================================
  Future<String> adicionarMercado(Mercado mercado) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) throw Exception("Usuário não autenticado");

      final dados = mercado.toMap();
      dados.remove('id');
      dados['admin_uid'] = user.id;

      final response = await _supabase
          .from(SupabaseKeys.tbMercados)
          .insert(dados)
          .select('id')
          .single();

      return response['id'].toString();
    } catch (e) {
      debugPrint("Erro ao adicionar mercado: $e");
      rethrow;
    }
  }

  Future<void> atualizarMercado(Mercado mercado) async {
    try {
      final dados = mercado.toMap();

      dados.remove('id');
      dados.remove('admin_uid');

      await _supabase
          .from(SupabaseKeys.tbMercados)
          .update(dados)
          .eq('id', mercado.id);
    } catch (e) {
      debugPrint("Erro ao atualizar mercado: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> buscarMercadosPorEmail() async {
    final user = _supabase.auth.currentUser;

    final emailUsuario = user?.email;
    if (emailUsuario == null) {
      debugPrint("Usuário não logado ou sem e-mail.");
      return [];
    }

    try {
      final response = await _supabase
          .from(SupabaseKeys.tbFuncionarios)
          .select('''mercado_id, funcao, mercados (nome, logo_url)''')
          .eq('email', emailUsuario)
          .eq('ativo', true);

      // Transformando a lista para um formato mais fácil de usar na UI
      return (response as List).map((item) {
        final mercado = item['mercados'] as Map<String, dynamic>?;
        return {
          'mercado_id': item['mercado_id'],
          'funcao': item['funcao'],
          'nome': mercado?['nome'] ?? 'Mercado s/ nome',
          'logo_url': mercado?['logo_url'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint("Erro ao buscar mercados: $e");
      return [];
    }
  }

  Future<void> atualizarStatusMercado(String mercadoId, bool aberto) async {
    try {
      await _supabase
          .from(SupabaseKeys.tbMercados)
          .update({'esta_aberto': aberto}).eq('id', mercadoId);
    } catch (e) {
      debugPrint("Erro ao atualizar status: $e");
      rethrow;
    }
  }

  // ==========================================
  // Pedidos
  // ==========================================
  Future<List<Pedido>> buscarHistoricoPedidosPaginados({
    required String mercadoId,
    required DateTime dataLimite,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseKeys.tbPedidos)
          .select()
          .eq('mercado_id', mercadoId)
          .gte('data', dataLimite.toIso8601String())
          .order('data', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((map) {
        return Pedido.fromMap(map['id'].toString(), map);
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar histórico de pedidos: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> atribuirFuncionarioAoPedido({
    required String pedidoId,
    required Funcionario funcionario,
  }) async {
    try {
      await _supabase.from(SupabaseKeys.tbPedidos).update({
        'coletor_id': funcionario.codigoSenha,
        'nome_coletor': funcionario.nome,
      }).eq('id', pedidoId);
    } on PostgrestException catch (e) {
      debugPrint("Erro Supabase (${e.code}): ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Erro desconhecido: $e");
      rethrow;
    }
  }

  // ==========================================
  // Funcionarios
  // ==========================================
  Future<void> salvarFuncionario(Funcionario funcionario) async {
    try {
      final table = _supabase.from(SupabaseKeys.tbFuncionarios);
      final dados = funcionario.toMap();

      if (funcionario.id.isEmpty) {
        dados.remove('id');
      }

      await table.upsert(dados);
    } on PostgrestException catch (e) {
      debugPrint("Erro específico do Supabase: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Erro genérico ao salvar funcionário: $e");
      rethrow;
    }
  }

  Future<void> alternarStatusFuncionario(String id, bool ativo) async {
    try {
      await _supabase
          .from(SupabaseKeys.tbFuncionarios)
          .update({'ativo': ativo}).eq('id', id);

      debugPrint("Status do funcionário $id atualizado para: $ativo");
    } on PostgrestException catch (e) {
      debugPrint("Erro ao alternar status: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Erro inesperado: $e");
      rethrow;
    }
  }

  Future<List<Funcionario>> listarFuncionarios(String mercadoId) async {
    try {
      final List<Map<String, dynamic>> data = await _supabase
          .from(SupabaseKeys.tbFuncionarios)
          .select()
          .eq('mercado_id', mercadoId)
          .order('nome');

      return data.map((map) => Funcionario.fromMap(map)).toList();
    } on PostgrestException catch (e) {
      debugPrint("Erro Supabase ao listar funcionários: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Erro ao listar funcionários: $e");
      rethrow;
    }
  }
}
