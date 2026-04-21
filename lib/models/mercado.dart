import 'item_mercado.dart';
import 'horario_mercado.dart';
import 'produto_enums.dart';

enum PagamentosAceitos { dinheiro, cartao, pix, vale }

class Mercado {
  final String id;
  final String adminUid;
  final String nome;
  final String? cnpj;
  final String? email;
  final String logoUrl;
  final String capaUrl;
  final String cidade;
  final String estado;
  final String endereco;
  final String telefone;
  final double estrelas;
  final double taxaEntrega;
  final double pedidoMinimo;
  final String tempoEntrega;
  final bool estaAberto;
  final List<ItemMercado> itens;
  final Map<String, DiaFuncionamento> gradeHorarios;
  final List<CategoriaProduto> categorias;
  final List<PagamentosAceitos> pagamentosAceitos;
  final double latitude;
  final double longitude;

  Mercado({
    required this.id,
    required this.adminUid,
    required this.nome,
    this.cnpj,
    this.email,
    required this.logoUrl,
    required this.capaUrl,
    required this.cidade,
    required this.estado,
    required this.endereco,
    required this.telefone,
    required this.estrelas,
    required this.taxaEntrega,
    required this.pedidoMinimo,
    required this.tempoEntrega,
    required this.estaAberto,
    required this.itens,
    required this.gradeHorarios,
    required this.categorias,
    required this.pagamentosAceitos,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'admin_uid': adminUid,
      'nome': nome,
      'cnpj': cnpj,
      'email': email,
      'logo_url': logoUrl,
      'capa_url': capaUrl,
      'cidade': cidade.toLowerCase().trim(),
      'estado': estado.toUpperCase().trim(),
      'endereco': endereco,
      'telefone': telefone,
      'estrelas': estrelas,
      'taxa_entrega': taxaEntrega,
      'pedido_minimo': pedidoMinimo,
      'tempo_entrega': tempoEntrega,
      'esta_aberto': estaAberto,
      'itens': itens.map((i) => i.toMap()).toList(), // Coluna JSONB
      'grade_horarios': gradeHorarios.map((k, v) => MapEntry(k, v.toMap())),
      'categorias': categorias.map((c) => c.name).toList(),
      'pagamentos_aceitos': pagamentosAceitos.map((p) => p.name).toList(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Mercado.fromMap(String id, Map<String, dynamic> map) {
    return Mercado(
      id: id,
      adminUid: map['admin_uid'] ?? '',
      nome: map['nome'] ?? '',
      cnpj: map['cnpj'],
      email: map['email'],
      logoUrl: map['logo_url'] ?? '',
      capaUrl: map['capa_url'] ?? '',
      cidade: map['cidade'] ?? '',
      estado: map['estado'] ?? '',
      endereco: map['endereco'] ?? '',
      telefone: map['telefone'] ?? '',
      estrelas: (map['estrelas'] ?? 0.0).toDouble(),
      taxaEntrega: (map['taxa_entrega'] ?? 0.0).toDouble(),
      pedidoMinimo: (map['pedido_minimo'] ?? 0.0).toDouble(),
      tempoEntrega: map['tempo_entrega'] ?? '',
      estaAberto: map['esta_aberto'] ?? true,
      itens: (map['itens'] as List? ?? [])
          .map((item) => ItemMercado.fromMap(item))
          .toList(),
      gradeHorarios: (map['grade_horarios'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, DiaFuncionamento.fromMap(value)),
      ),
      categorias: (map['categorias'] as List? ?? [])
          .map((c) => CategoriaProduto.values.byName(c))
          .toList(),
      pagamentosAceitos: (map['pagamentos_aceitos'] as List? ?? [])
          .map((p) => PagamentosAceitos.values.byName(p))
          .toList(),
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }

  Mercado copyWith({
    String? id,
    String? adminUid,
    String? nome,
    String? cnpj,
    String? email,
    String? logoUrl,
    String? capaUrl,
    String? cidade,
    String? estado,
    String? endereco,
    String? telefone,
    double? estrelas,
    double? taxaEntrega,
    double? pedidoMinimo,
    String? tempoEntrega,
    bool? estaAberto,
    List<ItemMercado>? itens,
    Map<String, DiaFuncionamento>? gradeHorarios,
    List<CategoriaProduto>? categorias,
    List<PagamentosAceitos>? pagamentosAceitos,
    double? latitude,
    double? longitude,
  }) {
    return Mercado(
      id: id ?? this.id,
      adminUid: adminUid ?? this.adminUid,
      nome: nome ?? this.nome,
      cnpj: cnpj ?? this.cnpj,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      capaUrl: capaUrl ?? this.capaUrl,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      endereco: endereco ?? this.endereco,
      telefone: telefone ?? this.telefone,
      estrelas: estrelas ?? this.estrelas,
      taxaEntrega: taxaEntrega ?? this.taxaEntrega,
      pedidoMinimo: pedidoMinimo ?? this.pedidoMinimo,
      tempoEntrega: tempoEntrega ?? this.tempoEntrega,
      estaAberto: estaAberto ?? this.estaAberto,
      itens: itens ?? this.itens,
      gradeHorarios: gradeHorarios ?? this.gradeHorarios,
      categorias: categorias ?? this.categorias,
      pagamentosAceitos: pagamentosAceitos ?? this.pagamentosAceitos,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
