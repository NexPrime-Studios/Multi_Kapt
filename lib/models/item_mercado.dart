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
      produtoId: map['produtoId'] ??
          map['id'] ??
          '', // Fallback para 'id' se necessário
      produtoNome: map['produtoNome'] ?? map['nome'] ?? 'Produto sem nome',
      produtoImagem: map['produtoImagem'] ?? map['imagem_url'] ?? '',
      produtoCategoria: map['produtoCategoria'] ?? map['categoria'] ?? '',
      codigoBarras: map['codigo_barras'] ?? map['codigoBarras'] ?? '',
      preco: (map['preco'] ?? 0.0).toDouble(),
      precoPromocional: map['precoPromocional']?.toDouble() ??
          map['preco_promocional']?.toDouble(),
      inicioPromocao: map['inicioPromocao'] != null
          ? DateTime.parse(map['inicioPromocao'])
          : (map['inicio_promocao'] != null
              ? DateTime.parse(map['inicio_promocao'])
              : null),
      fimPromocao: map['fimPromocao'] != null
          ? DateTime.parse(map['fimPromocao'])
          : (map['fim_promocao'] != null
              ? DateTime.parse(map['fim_promocao'])
              : null),
      disponivel: map['disponivel'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produtoId': produtoId,
      'produtoNome': produtoNome,
      'produtoImagem': produtoImagem,
      'produtoCategoria': produtoCategoria,
      'codigo_barras': codigoBarras,
      'preco': preco,
      'precoPromocional': precoPromocional,
      'inicioPromocao': inicioPromocao?.toIso8601String(),
      'fimPromocao': fimPromocao?.toIso8601String(),
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
