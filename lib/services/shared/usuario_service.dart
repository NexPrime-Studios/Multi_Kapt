import 'package:flutter/material.dart';
import 'package:mercado_app/models/produto_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/mercado.dart';
import '../../models/produto.dart';
import '../../models/pedido.dart';
import '../../models/carrinho_item.dart';
import '../../models/unidade_medida_enums.dart';
import '../../models/usuario.dart';
import '../../models/item_pedido.dart';

class UsuarioService {
  final _supabase = Supabase.instance.client;

  // --- CONSUMO DE DADOS ---

  Stream<List<Mercado>> buscarMercadosPorLocalizacao({
    required String cidade,
    required String estado,
  }) {
    return _supabase.from('mercados').stream(primaryKey: ['id']).map((lista) =>
        lista
            .where((map) =>
                map['cidade'] == cidade.toLowerCase().trim() &&
                map['estado'] == estado.toUpperCase().trim())
            .map((map) => Mercado.fromMap(map['id'] as String, map))
            .toList());
  }

  Future<List<Produto>> buscarDetalhesDosProdutos(List<String> ids) async {
    if (ids.isEmpty) return [];
    final response =
        await _supabase.from('produtos').select().filter('id', 'in', ids);

    final lista = response as List<dynamic>;
    return lista
        .map((map) => Produto.fromMap(map['id'] as String, map))
        .toList();
  }

  Future<Mercado?> buscarMercadoPorId(String id) async {
    try {
      final response =
          await _supabase.from('mercados').select().eq('id', id).single();

      return Mercado.fromMap(response['id'], response);
    } catch (e) {
      debugPrint("Erro ao buscar mercado no ClienteService: $e");
      return null;
    }
  }

  // --- PEDIDOS ---

  Future<void> realizarPedido(Pedido pedido) async {
    await _supabase.from('pedidos').insert(pedido.toMap());
  }

  Stream<List<Pedido>> acompanharMeusPedidos(String clienteId) {
    return _supabase
        .from('pedidos')
        .stream(primaryKey: ['id'])
        .eq('cliente_id', clienteId)
        .map((lista) => lista
            .map((map) => Pedido.fromMap(map['id'] as String, map))
            .toList()
          ..sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao)));
  }

  Future<List<Produto>> pesquisarProdutosNoSupabase(String termo) async {
    if (termo.isEmpty) return [];
    String busca = termo.toLowerCase().trim();
    final response = await _supabase
        .from('produtos')
        .select()
        .ilike('nome', '%$busca%')
        .limit(20);

    final lista = response as List<dynamic>;
    return lista
        .map((map) => Produto.fromMap(map['id'] as String, map))
        .toList();
  }

  Stream<List<Pedido>> buscarHistoricoPedidos(String clienteId) {
    return _supabase
        .from('pedidos')
        .stream(primaryKey: ['id'])
        .eq('cliente_id', clienteId)
        .order('data', ascending: false)
        .map((data) =>
            data.map((map) => Pedido.fromMap(map['id'], map)).toList());
  }

  Future<void> finalizarPedidoMultimercado({
    required Map<String, List<CarrinhoItem>> agrupamento,
    required Map<String, String> pagamentos,
    required Map<String, double> taxas,
    required Usuario cliente,
  }) async {
    final now = DateTime.now();

    final endereco = cliente.endereco;
    final String enderecoFormatado =
        "${endereco.rua}, ${endereco.numero}${endereco.complemento.isNotEmpty ? ' - ${endereco.complemento}' : ''}. "
        "${endereco.bairro}, ${endereco.cidade} - ${endereco.estado}. CEP: ${endereco.cep}";

    for (var mercadoId in agrupamento.keys) {
      final itensDoMercado = agrupamento[mercadoId]!;
      final formaPgto = pagamentos[mercadoId] ?? 'Não selecionado';

      final double valorTaxaNumerico = taxas[mercadoId] ?? 0.0;
      final String taxaFormatada = valorTaxaNumerico.toStringAsFixed(2);

      final nomeLoja = itensDoMercado.first.nomeMercado;

      final List<Map<String, dynamic>> itensProcessados =
          itensDoMercado.map((i) {
        final itemModel = ItemPedido(
          id: i.produto.id,
          nome: i.produto.nome,
          codigoBarras: i.produto.codigoBarras,
          quantidade: i.quantidade,
          preco: i.precoUnitario,
          quantidadeColetada: i.quantidade,
          precoFinal: i.total,
          emFalta: false,
          substituido: false,
          podeSubstituir: i.aceitaSubstituicao,
        );

        var itemMap = itemModel.toMap();
        itemMap['unidade'] = i.produto.unidadeMedida.sigla;
        itemMap['observacao'] = i.observacao;

        return itemMap;
      }).toList();

      double subtotalProdutos =
          itensDoMercado.fold(0, (sum, item) => sum + item.total);

      final novoPedido = Pedido(
        idPedido: '',
        mercadoId: mercadoId,
        nomeMercado: nomeLoja,
        clienteId: cliente.uid,
        nomeCliente: cliente.nome,
        telefoneCliente: cliente.telefone,
        enderecoEntrega: enderecoFormatado,
        latitude: cliente.latitude ?? 0.0,
        longitude: cliente.longitude ?? 0.0,
        itens: itensProcessados,
        total: subtotalProdutos + valorTaxaNumerico,
        formaPagamento: formaPgto,
        taxa: taxaFormatada,
        status: StatusPedido.pendente,
        dataCriacao: now,
        horarios: {'pendente': now},
      );

      await _supabase.from('pedidos').insert(novoPedido.toMap());
    }
  }
}
