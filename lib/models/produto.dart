// models/produto.dart
import 'unidade_medida_enums.dart';

enum TipoProduto {
  industrial, // Código de barras fixo e marca (ex: Coca-Cola)
  pesavel, // Peso/balança (ex: Alcatra, Banana)
  interno // Fabricação própria (ex: Pão da casa, Bolo artesanal)
}

class Produto {
  // =========================================================
  // 1. GRUPO: COMPARTILHADO (Identidade e Taxonomia)
  // =========================================================
  final String id;
  final TipoProduto tipo;

  final String categoria; // Ex: Carnes, Padaria, Hortifruti
  final String subcategoria; // Ex: Bovinos, Pães, Frutas
  final String produtoBase; // Ex: Alcatra, Pão de Forma, Banana
  final String? variacao; // Ex: Em bifes, Integral, Nanica

  final String nome;
  final String descricao;
  final String fotoUrl;
  final String ncm; // Fiscal
  final List<String> tags; // Tags de busca e filtros

  // NOVO CAMPO: Controle de Fluxo
  final bool emRevisao;

  // =========================================================
  // 2. GRUPO: INDUSTRIAL (Código de Barras e Marca)
  // =========================================================
  final String? codigoBarras;
  final String marca;
  final double quantidadeConteudo;
  final UnidadeMedida unidadeMedida;

  final bool isVegano;
  final bool isSemGluten;
  final bool isPerecivel;
  final bool isSemAcucar;
  final bool isZeroLactose;

  // =========================================================
  // 3. GRUPO: PESO - BALANÇA (Variáveis e Estimativas)
  // =========================================================
  final double? pesoEstimadoUnidade;

  Produto({
    required this.id,
    required this.tipo,
    required this.categoria,
    required this.subcategoria,
    required this.produtoBase,
    this.variacao,
    required this.nome,
    required this.descricao,
    required this.fotoUrl,
    required this.marca,
    this.codigoBarras,
    this.ncm = '',
    required this.unidadeMedida,
    required this.quantidadeConteudo,
    required this.tags,
    this.emRevisao = true,
    this.isVegano = false,
    this.isSemGluten = false,
    this.isPerecivel = false,
    this.isSemAcucar = false,
    this.isZeroLactose = false,
    this.pesoEstimadoUnidade,
  });

  // Getters auxiliares
  bool get isPesavel => tipo == TipoProduto.pesavel;
  bool get isInterno => tipo == TipoProduto.interno;
  bool get isIndustrial => tipo == TipoProduto.industrial;

  // Fábrica para converter do Supabase (Map) para o objeto Dart
  factory Produto.fromMap(String id, Map<String, dynamic> map) {
    return Produto(
      id: id,
      tipo: TipoProduto.values.firstWhere(
        (e) => e.name == (map['tipo'] ?? 'industrial'),
        orElse: () => TipoProduto.industrial,
      ),
      categoria: map['categoria'] ?? '',
      subcategoria: map['subcategoria'] ?? '',
      produtoBase: map['produto_base'] ?? '',
      variacao: map['variacao'],
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      fotoUrl: map['foto_url'] ?? '',
      marca: map['marca'] ?? 'Própria',
      codigoBarras: map['codigo_barras'],
      ncm: map['ncm'] ?? '',
      emRevisao: map['em_revisao'] ?? true,
      quantidadeConteudo: (map['quantidade_conteudo'] ?? 0).toDouble(),
      tags: List<String>.from(map['tags'] ?? []),
      isVegano: map['is_vegano'] ?? false,
      isSemGluten: map['is_sem_gluten'] ?? false,
      isPerecivel: map['is_perecivel'] ?? false,
      isSemAcucar: map['is_sem_acucar'] ?? false,
      isZeroLactose: map['is_zero_lactose'] ?? false,
      pesoEstimadoUnidade: map['peso_estimado_unidade']?.toDouble(),
      unidadeMedida: UnidadeMedida.values.firstWhere(
        (e) => e.name == (map['unidade_medida'] ?? 'unidade'),
        orElse: () => UnidadeMedida.unidade,
      ),
    );
  }

  // Método para salvar no Supabase
  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo.name,
      'categoria': categoria,
      'subcategoria': subcategoria,
      'produto_base': produtoBase,
      'variacao': variacao,
      'nome': nome,
      'descricao': descricao,
      'foto_url': fotoUrl,
      'marca': marca,
      'codigo_barras': codigoBarras,
      'ncm': ncm,
      'em_revisao': emRevisao,
      'unidade_medida': unidadeMedida.name,
      'quantidade_conteudo': quantidadeConteudo,
      'tags': tags.map((t) => t.toLowerCase().trim()).toList(),
      'is_vegano': isVegano,
      'is_sem_gluten': isSemGluten,
      'is_perecivel': isPerecivel,
      'is_sem_acucar': isSemAcucar,
      'is_zero_lactose': isZeroLactose,
      'peso_estimado_unidade': pesoEstimadoUnidade,
    };
  }
}
