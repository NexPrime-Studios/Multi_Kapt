// models/produto_enum.dart

enum CategoriaProduto {
  mercearia,
  bebidas,
  limpeza,
  higiene,
  hortifruti,
  acougue,
  padaria,
  frios,
  petshop,
  doces,
  outros,
}

enum UnidadeMedida {
  unidade, // un
  quilograma, // kg
  grama, // g
  litro, // l
  mililitro, // ml
  fardo, // fdo
  caixa, // cx
  pacote, // pct
  bandeja, // bdj
  duzia, // dz
  garrafa, // gf
  lata, // lt
  pote // pt
}

extension UnidadeMedidaExt on UnidadeMedida {
  String get sigla {
    switch (this) {
      case UnidadeMedida.unidade:
        return 'un';
      case UnidadeMedida.quilograma:
        return 'kg';
      case UnidadeMedida.grama:
        return 'g';
      case UnidadeMedida.litro:
        return 'l';
      case UnidadeMedida.mililitro:
        return 'ml';
      case UnidadeMedida.fardo:
        return 'fdo';
      case UnidadeMedida.caixa:
        return 'cx';
      case UnidadeMedida.pacote:
        return 'pct';
      case UnidadeMedida.bandeja:
        return 'bdj';
      case UnidadeMedida.duzia:
        return 'dz';
      case UnidadeMedida.garrafa:
        return 'gf';
      case UnidadeMedida.lata:
        return 'lt';
      case UnidadeMedida.pote:
        return 'pt';
    }
  }

  // Verifica se o item deve ser vendido por peso (passo de 0.1 no seletor)
  bool get ehPeso =>
      this == UnidadeMedida.quilograma || this == UnidadeMedida.grama;
}
