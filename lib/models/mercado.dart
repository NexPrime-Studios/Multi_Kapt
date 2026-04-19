// lib/models/mercado.dart
import 'item_mercado.dart';
import 'horario_mercado.dart';
import 'produto_enums.dart';

// Definindo o enum aqui como você sugeriu
enum PagamentosAceitos { dinheiro, cartao, pix, vale }

class Mercado {
  final String id;
  final String nome;
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

  // ALTERADO: De List<String> para List<PagamentosAceitos>
  final List<PagamentosAceitos> pagamentosAceitos;

  final double latitude;
  final double longitude;

  Mercado({
    required this.id,
    required this.nome,
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

  Mercado copyWith({
    String? id,
    String? nome,
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
    List<PagamentosAceitos>? pagamentosAceitos, // Alterado aqui também
    double? latitude,
    double? longitude,
  }) {
    return Mercado(
      id: id ?? this.id,
      nome: nome ?? this.nome,
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

  factory Mercado.fromMap(String id, Map<String, dynamic> map) {
    return Mercado(
      id: id,
      nome: map['nome'] ?? '',
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

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
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
      'itens': itens.map((i) => i.toMap()).toList(),
      'grade_horarios': gradeHorarios.map((k, v) => MapEntry(k, v.toMap())),
      'categorias': categorias.map((c) => c.name).toList(),
      'pagamentos_aceitos': pagamentosAceitos.map((p) => p.name).toList(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
