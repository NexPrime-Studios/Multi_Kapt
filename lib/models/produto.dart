// models/produto.dart
import 'produto_enums.dart';

class Produto {
  final String id;
  final String nome;
  final String descricao;
  final String fotoUrl;
  final CategoriaProduto categoria;
  final String marca;
  final String codigoBarras;
  final UnidadeMedida unidadeMedida;
  final List<String> tags;

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.fotoUrl,
    required this.categoria,
    required this.marca,
    required this.codigoBarras,
    required this.unidadeMedida,
    required this.tags,
  });

  factory Produto.fromMap(String id, Map<String, dynamic> map) {
    return Produto(
      id: id,
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      fotoUrl: map['foto_url'] ?? '',
      marca: map['marca'] ?? '',
      codigoBarras: map['codigo_barras'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      categoria: CategoriaProduto.values.firstWhere(
        (e) => e.name == (map['categoria'] ?? 'outros'),
        orElse: () => CategoriaProduto.outros,
      ),
      unidadeMedida: UnidadeMedida.values.firstWhere(
        (e) => e.name == (map['unidade_medida'] ?? 'unidade'),
        orElse: () => UnidadeMedida.unidade,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'foto_url': fotoUrl,
      'marca': marca,
      'codigo_barras': codigoBarras,
      'categoria': categoria.name,
      'unidade_medida': unidadeMedida.name,
      'tags': tags.map((t) => t.toLowerCase().trim()).toList(),
    };
  }
}
