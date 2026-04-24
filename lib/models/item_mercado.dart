// lib/models/item_mercado.dart

class ItemMercado {
  final String produtoId;
  final String produtoNome;
  final String produtoImagem;
  final String produtoCategoria;
  final String codigoBarras;

  final double preco;
  final double? precoPromocional;
  final DateTime? inicioPromocao;
  final DateTime? fimPromocao;
  final bool disponivel;

  ItemMercado({
    required this.produtoId,
    required this.produtoNome,
    required this.produtoImagem,
    required this.produtoCategoria,
    required this.codigoBarras,
    required this.preco,
    this.precoPromocional,
    this.inicioPromocao,
    this.fimPromocao,
    required this.disponivel,
  });

  bool get emPromocao {
    final agora = DateTime.now();
    if (precoPromocional == null || precoPromocional! >= preco) return false;
    if (inicioPromocao == null || fimPromocao == null) return false;
    return agora.isAfter(inicioPromocao!) && agora.isBefore(fimPromocao!);
  }

  factory ItemMercado.fromMap(Map<String, dynamic> map) {
    return ItemMercado(
      produtoId: map['produto_id'] ?? '',
      produtoNome: map['produto_nome'] ?? 'Produto sem nome',
      produtoImagem: map['produto_imagem'] ?? '',
      produtoCategoria: map['produto_categoria'] ?? '',
      codigoBarras: map['codigo_barras'] ?? '',
      preco: (map['preco'] ?? 0.0).toDouble(),
      precoPromocional: map['preco_promocional']?.toDouble(),
      inicioPromocao: map['inicio__promocao'] != null
          ? DateTime.parse(map['inicio_promocao'])
          : null,
      fimPromocao: map['fim_promocao'] != null
          ? DateTime.parse(map['fim_promocao'])
          : null,
      disponivel: map['disponivel'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produto_id': produtoId,
      'produto_nome': produtoNome,
      'produto_imagem': produtoImagem,
      'produto_categoria': produtoCategoria,
      'codigo_barras': codigoBarras,
      'preco': preco,
      'preco_promocional': precoPromocional,
      'inicio_promocao': inicioPromocao?.toIso8601String(),
      'fim_promocao': fimPromocao?.toIso8601String(),
      'disponivel': disponivel,
    };
  }

  ItemMercado copyWith({
    String? produtoId,
    String? produtoNome,
    String? produtoImagem,
    String? produtoCategoria,
    String? codigoBarras,
    double? preco,
    double? precoPromocional,
    DateTime? inicioPromocao,
    DateTime? fimPromocao,
    bool? disponivel,
  }) {
    return ItemMercado(
      produtoId: produtoId ?? this.produtoId,
      produtoNome: produtoNome ?? this.produtoNome,
      produtoImagem: produtoImagem ?? this.produtoImagem,
      produtoCategoria: produtoCategoria ?? this.produtoCategoria,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      preco: preco ?? this.preco,
      precoPromocional: precoPromocional ?? this.precoPromocional,
      inicioPromocao: inicioPromocao ?? this.inicioPromocao,
      fimPromocao: fimPromocao ?? this.fimPromocao,
      disponivel: disponivel ?? this.disponivel,
    );
  }
}
