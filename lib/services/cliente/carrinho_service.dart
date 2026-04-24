import 'package:flutter/material.dart';
import '../../models/produto.dart';
import '../../models/carrinho_item.dart';

class CarrinhoService extends ChangeNotifier {
  final List<CarrinhoItem> _itens = [];

  // Mapa para armazenar a forma de pagamento de cada mercado: {mercadoId: formaPagamento}
  final Map<String, String> _pagamentosPorMercado = {};

  List<CarrinhoItem> get itens => _itens;
  Map<String, String> get pagamentosPorMercado => _pagamentosPorMercado;

  double get valorTotal => _itens.fold(0, (sum, item) => sum + item.total);

  // --- MÉTODOS DE PAGAMENTO ---

  /// Define a forma de pagamento para um mercado específico
  void selecionarPagamento(String mercadoId, String forma) {
    _pagamentosPorMercado[mercadoId] = forma;
    notifyListeners();
  }

  /// Verifica se todos os mercados possuem forma de pagamento selecionada
  bool todosPagamentosSelecionados() {
    if (_itens.isEmpty) return false;

    final mercadosNoCarrinho = _itens.map((i) => i.mercadoId).toSet();

    return mercadosNoCarrinho
        .every((id) => _pagamentosPorMercado.containsKey(id));
  }

  // --- MÉTODOS DO CARRINHO ---

  /// Adiciona um produto ao carrinho.
  /// Agora inclui a opção de substituição na lógica de agrupamento.
  void adicionar(
    Produto produto,
    double quantidade,
    double preco,
    String mercadoId,
    String nomeMercado,
    String observacao,
    bool aceitaSubstituicao, // <--- NOVO PARÂMETRO
  ) {
    // A lógica de busca agora inclui ID, Mercado, Observação E a decisão de Substituição.
    int index = _itens.indexWhere((i) =>
        i.produto.id == produto.id &&
        i.mercadoId == mercadoId &&
        i.observacao == observacao &&
        i.aceitaSubstituicao == aceitaSubstituicao);

    if (index >= 0) {
      _itens[index].quantidade += quantidade;
    } else {
      _itens.add(CarrinhoItem(
        produto: produto,
        quantidade: quantidade,
        precoUnitario: preco,
        mercadoId: mercadoId,
        nomeMercado: nomeMercado,
        observacao: observacao,
        aceitaSubstituicao: aceitaSubstituicao, // <--- ATRIBUIÇÃO
      ));
    }
    notifyListeners();
  }

  /// Permite ao cliente mudar a opção de substituição direto na tela do carrinho
  void atualizarSubstituicao(int index, bool novoValor) {
    if (index >= 0 && index < _itens.length) {
      // Usamos o copyWith que criamos no CarrinhoItem para manter a imutabilidade se necessário
      _itens[index].aceitaSubstituicao = novoValor;
      notifyListeners();
    }
  }

  void atualizarQuantidade(int index, double novaQuantidade) {
    if (novaQuantidade <= 0) {
      remover(index);
    } else {
      _itens[index].quantidade = novaQuantidade;
      notifyListeners();
    }
  }

  void remover(int index) {
    if (index < 0 || index >= _itens.length) return;

    final itemRemovido = _itens.removeAt(index);

    // Se não houver mais nenhum item desse mercado, remove o pagamento vinculado
    bool aindaTemItensDesseMercado =
        _itens.any((i) => i.mercadoId == itemRemovido.mercadoId);
    if (!aindaTemItensDesseMercado) {
      _pagamentosPorMercado.remove(itemRemovido.mercadoId);
    }

    notifyListeners();
  }

  void limparCarrinho() {
    _itens.clear();
    _pagamentosPorMercado.clear();
    notifyListeners();
  }
}
