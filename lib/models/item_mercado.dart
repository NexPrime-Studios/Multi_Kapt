class ItemMercado {
  final String produtoId;
  final String mercadoId;
  final double preco;
  final double? precoPromocional;
  final DateTime? inicioPromocao;
  final DateTime? fimPromocao;
  final bool disponivel;

  ItemMercado({
    required this.produtoId,
    required this.mercadoId,
    required this.preco,
    required this.disponivel,
    this.precoPromocional,
    this.inicioPromocao,
    this.fimPromocao,
  });

  /// Verifica se o item está em promoção ativa no momento atual
  bool get emPromocao {
    final agora = DateTime.now();
    if (precoPromocional == null || precoPromocional! >= preco) return false;
    if (inicioPromocao == null || fimPromocao == null) return false;
    return agora.isAfter(inicioPromocao!) && agora.isBefore(fimPromocao!);
  }

  factory ItemMercado.fromMap(Map<String, dynamic> map) {
    return ItemMercado(
      produtoId: map['produto_id'] ?? '',
      mercadoId: map['mercado_id'] ?? '',
      preco: (map['preco'] ?? 0.0).toDouble(),
      precoPromocional: map['preco_promocional']?.toDouble(),
      inicioPromocao: map['inicio_promocao'] != null
          ? DateTime.tryParse(map['inicio_promocao'].toString())
          : null,
      fimPromocao: map['fim_promocao'] != null
          ? DateTime.tryParse(map['fim_promocao'].toString())
          : null,
      disponivel: map['disponivel'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produto_id': produtoId,
      'mercado_id': mercadoId,
      'preco': preco,
      'preco_promocional': precoPromocional,
      'inicio_promocao': inicioPromocao?.toIso8601String(),
      'fim_promocao': fimPromocao?.toIso8601String(),
      'disponivel': disponivel,
    };
  }

  ItemMercado copyWith({
    String? produtoId,
    String? mercadoId,
    double? preco,
    double? precoPromocional,
    DateTime? inicioPromocao,
    DateTime? fimPromocao,
    bool? disponivel,
  }) {
    return ItemMercado(
      produtoId: produtoId ?? this.produtoId,
      mercadoId: mercadoId ?? this.mercadoId,
      preco: preco ?? this.preco,
      precoPromocional: precoPromocional ?? this.precoPromocional,
      inicioPromocao: inicioPromocao ?? this.inicioPromocao,
      fimPromocao: fimPromocao ?? this.fimPromocao,
      disponivel: disponivel ?? this.disponivel,
    );
  }
}
