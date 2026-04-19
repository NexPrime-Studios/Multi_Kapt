import 'produto.dart';

class CarrinhoItem {
  final Produto produto;
  double quantidade;
  final double precoUnitario;
  final String mercadoId;
  final String nomeMercado;
  String observacao;
  bool aceitaSubstituicao;

  CarrinhoItem({
    required this.produto,
    required this.quantidade,
    required this.precoUnitario,
    required this.mercadoId,
    required this.nomeMercado,
    this.observacao = '',
    this.aceitaSubstituicao = true,
  });

  // Calcula o valor total deste item no carrinho
  double get total => precoUnitario * quantidade;

  CarrinhoItem copyWith({
    double? quantidade,
    String? observacao,
    bool? aceitaSubstituicao,
  }) {
    return CarrinhoItem(
      produto: produto,
      quantidade: quantidade ?? this.quantidade,
      precoUnitario: precoUnitario,
      mercadoId: mercadoId,
      nomeMercado: nomeMercado,
      observacao: observacao ?? this.observacao,
      aceitaSubstituicao: aceitaSubstituicao ?? this.aceitaSubstituicao,
    );
  }

  factory CarrinhoItem.fromMap(Map<String, dynamic> map, Produto produto) {
    return CarrinhoItem(
      produto: produto,
      quantidade: (map['quantidade'] ?? 1.0).toDouble(),
      precoUnitario: (map['precoUnitario'] ?? 0.0).toDouble(),
      mercadoId: map['mercadoId'] ?? '',
      nomeMercado: map['nomeMercado'] ?? 'Mercado Desconhecido',
      observacao: map['observacao'] ?? '',
      aceitaSubstituicao: map['aceitaSubstituicao'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtoId': produto.id,
      'quantidade': quantidade,
      'precoUnitario': precoUnitario,
      'mercadoId': mercadoId,
      'nomeMercado': nomeMercado,
      'observacao': observacao,
      'aceitaSubstituicao': aceitaSubstituicao,
    };
  }
}
