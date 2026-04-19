class ItemPedido {
  final String id;
  final String nome;
  final String? codigoBarras;
  final double quantidade;
  final double preco;
  final bool podeSubstituir;

  // Campos que podem mudar durante a coleta
  double quantidadeColetada;
  double precoFinal;
  bool emFalta;
  bool substituido;

  ItemPedido({
    required this.id,
    required this.nome,
    this.codigoBarras,
    required this.quantidade,
    required this.preco,
    this.podeSubstituir = false,
    this.quantidadeColetada = 0.0,
    this.precoFinal = 0.0,
    this.emFalta = false,
    this.substituido = false,
  });

  // Método copyWith para criar cópias alterando campos específicos
  ItemPedido copyWith({
    String? id,
    String? nome,
    String? codigoBarras,
    double? quantidade,
    double? preco,
    bool? podeSubstituir,
    double? quantidadeColetada,
    double? precoFinal,
    bool? emFalta,
    bool? substituido,
  }) {
    return ItemPedido(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      quantidade: quantidade ?? this.quantidade,
      preco: preco ?? this.preco,
      podeSubstituir: podeSubstituir ?? this.podeSubstituir,
      quantidadeColetada: quantidadeColetada ?? this.quantidadeColetada,
      precoFinal: precoFinal ?? this.precoFinal,
      emFalta: emFalta ?? this.emFalta,
      substituido: substituido ?? this.substituido,
    );
  }

  double get precoUnitario => preco / (quantidade > 0 ? quantidade : 1);

  bool get foiAlterado {
    if (emFalta) return false;
    return (quantidadeColetada - quantidade).abs() > 0.001 &&
        quantidadeColetada > 0;
  }

  double get quantidadeExibicao =>
      (quantidadeColetada > 0 || emFalta) ? quantidadeColetada : quantidade;

  double get precoExibicao => (precoFinal > 0 || emFalta) ? precoFinal : preco;

  factory ItemPedido.fromMap(Map<String, dynamic> map) {
    return ItemPedido(
      id: map['produto_id'] ?? map['id'] ?? '',
      nome: map['produto_nome'] ?? map['nome'] ?? 'Item sem nome',
      codigoBarras: map['codigo_barras'],
      quantidade:
          (map['quantidade_original'] ?? map['quantidade'] ?? 0.0).toDouble(),
      preco: (map['preco_original'] ?? map['preco'] ?? 0.0).toDouble(),
      podeSubstituir: map['pode_substituir'] ?? false,
      quantidadeColetada:
          (map['quantidade_coletada'] ?? map['quantidade'] ?? 0.0).toDouble(),
      precoFinal: (map['preco_final'] ?? map['preco'] ?? 0.0).toDouble(),
      emFalta: map['em_falta'] ?? false,
      substituido: map['substituido'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'produto_id': id,
      'produto_nome': nome,
      'codigo_barras': codigoBarras,
      'quantidade_original': quantidade,
      'preco_original': preco,
      'pode_substituir': podeSubstituir,
      'quantidade_coletada': quantidadeColetada,
      'preco_final': precoFinal,
      'em_falta': emFalta,
      'substituido': substituido,
      'quantidade': emFalta
          ? 0.0
          : (quantidadeColetada > 0 ? quantidadeColetada : quantidade),
      'preco': emFalta ? 0.0 : (precoFinal > 0 ? precoFinal : preco),
    };
  }
}
