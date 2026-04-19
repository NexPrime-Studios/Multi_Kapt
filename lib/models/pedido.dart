enum StatusPedido {
  pendente,
  preparando,
  pronto,
  saiuParaEntrega,
  entregue,
  cancelado
}

class Pedido {
  final String idPedido;
  final String mercadoId;
  final String nomeMercado;
  final String clienteId;
  final String nomeCliente;
  final String telefoneCliente;
  final String enderecoEntrega;
  final double latitude;
  final double longitude;

  final List<Map<String, dynamic>> itens;
  final double total;
  final String formaPagamento;
  final String taxa;
  final StatusPedido status;
  final DateTime dataCriacao;
  final Map<String, DateTime?> horarios;

  final String? coletorId;
  final String? nomeColetor;
  final String? entregadorId;
  final String? nomeEntregador;

  Pedido({
    required this.idPedido,
    required this.mercadoId,
    required this.nomeMercado,
    required this.clienteId,
    required this.nomeCliente,
    required this.telefoneCliente,
    required this.enderecoEntrega,
    required this.latitude,
    required this.longitude,
    required this.itens,
    required this.total,
    required this.formaPagamento,
    required this.taxa,
    required this.dataCriacao,
    required this.status,
    required this.horarios,
    this.coletorId,
    this.nomeColetor,
    this.entregadorId,
    this.nomeEntregador,
  });

  Map<String, dynamic> toMap() {
    return {
      'mercado_id': mercadoId,
      'nome_mercado': nomeMercado,
      'cliente_id': clienteId,
      'nome_cliente': nomeCliente,
      'telefone_cliente': telefoneCliente,
      'endereco_entrega': enderecoEntrega,
      'latitude': latitude,
      'longitude': longitude,
      'itens': itens,
      'total': total,
      'forma_pagamento': formaPagamento,
      'taxa': taxa,
      'data': dataCriacao.toIso8601String(),
      'status': status.name,
      'horarios':
          horarios.map((key, value) => MapEntry(key, value?.toIso8601String())),
      'coletor_id': coletorId,
      'nome_coletor': nomeColetor,
      'entregador_id': entregadorId,
      'nome_entregador': nomeEntregador,
    };
  }

  factory Pedido.fromMap(String id, Map<String, dynamic> map) {
    Map<String, dynamic> horariosRaw = map['horarios'] ?? {};

    return Pedido(
      idPedido: id,
      mercadoId: map['mercado_id'] ?? '',
      nomeMercado: map['nome_mercado'] ?? 'Mercado',
      clienteId: map['cliente_id'] ?? '',
      nomeCliente: map['nome_cliente'] ?? 'Cliente',
      telefoneCliente: map['telefone_cliente'] ?? '',
      enderecoEntrega: map['endereco_entrega'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      itens: (map['itens'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      total: (map['total'] ?? 0.0).toDouble(),
      formaPagamento: map['forma_pagamento'] ?? 'Não informado',
      taxa: map['taxa']?.toString() ?? '0.00',
      dataCriacao:
          map['data'] != null ? DateTime.parse(map['data']) : DateTime.now(),
      status: StatusPedido.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pendente'),
        orElse: () => StatusPedido.pendente,
      ),
      horarios: horariosRaw.map((key, value) =>
          MapEntry(key, value != null ? DateTime.parse(value) : null)),
      coletorId: map['coletor_id'],
      nomeColetor: map['nome_coletor'],
      entregadorId: map['entregador_id'],
      nomeEntregador: map['nome_entregador'],
    );
  }

  Pedido copyWith({
    StatusPedido? status,
    Map<String, DateTime?>? horarios,
    String? coletorId,
    String? nomeColetor,
    String? entregadorId,
    String? nomeEntregador,
  }) {
    return Pedido(
      idPedido: idPedido,
      mercadoId: mercadoId,
      nomeMercado: nomeMercado,
      clienteId: clienteId,
      nomeCliente: nomeCliente,
      telefoneCliente: telefoneCliente,
      enderecoEntrega: enderecoEntrega,
      latitude: latitude,
      longitude: longitude,
      itens: itens,
      total: total,
      formaPagamento: formaPagamento,
      taxa: taxa,
      dataCriacao: dataCriacao,
      status: status ?? this.status,
      horarios: horarios ?? this.horarios,
      coletorId: coletorId ?? this.coletorId,
      nomeColetor: nomeColetor ?? this.nomeColetor,
      entregadorId: entregadorId ?? this.entregadorId,
      nomeEntregador: nomeEntregador ?? this.nomeEntregador,
    );
  }
}
