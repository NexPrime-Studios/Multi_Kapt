import 'package:supabase_flutter/supabase_flutter.dart';
import '../../enums/unidade_medida_enums.dart';
import '../../models/carrinho_item.dart';
import '../../models/item_pedido.dart';
import '../../models/mercado.dart';
import '../../models/pedido.dart';
import '../../models/usuario.dart';
import '../../supabase_keys.dart';

class ClienteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - MERCADO
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Future<List<Mercado>> buscarMercadosPorLocalizacao({
    required String cidade,
    required String estado,
  }) async {
    try {
      final List<dynamic> response = await _supabase
          .from(SupabaseKeys.tbMercados)
          .select()
          .eq('cidade', cidade.toLowerCase().trim())
          .eq('estado', estado.toUpperCase().trim());

      return response
          .map((map) => Mercado.fromMap(map['id'] as String, map))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - PEDIDO
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
        taxa: valorTaxaNumerico,
        status: StatusPedido.pendente,
        dataCriacao: now,
        horarios: {'pendente': now},
      );

      await _supabase.from('pedidos').insert(novoPedido.toMap());
    }
  }
}
