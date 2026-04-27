import 'package:flutter/material.dart';

enum CategoriaProduto {
  /// Exemplos: Açúcar, chocolate, biscoitos, geleias
  merceariaDoce('Mercearia Doce', Icons.cookie),

  /// Exemplos: Arroz, feijão, macarrão, óleo, molho de tomate
  merceariaSalgada('Mercearia Salgada', Icons.inventory_2),

  /// Exemplos: Refrigerantes, sucos, água, energéticos
  bebidas('Bebidas', Icons.local_drink),

  /// Exemplos: Vinhos, cervejas artesanais, whiskys, espumantes
  adega('Adega', Icons.wine_bar),

  /// Exemplos: Queijos, presunto, iogurtes, manteiga
  friosLaticinios('Frios e Laticínios', Icons.kitchen),

  /// Exemplos: Detergente, sabão em pó, desinfetante
  limpeza('Limpeza', Icons.cleaning_services),

  /// Exemplos: Shampoo, sabonete, creme dental, desodorante
  higienePessoal('Higiene Pessoal', Icons.face),

  /// Exemplos: Frutas, legumes, verduras frescas
  hortifruti('Hortifruti', Icons.eco),

  /// Exemplos: Carne bovina, frango, suíno, linguiças
  acougue('Açougue', Icons.kebab_dining),

  /// Exemplos: Pão francês, bolos da casa, salgados assados
  padaria('Padaria', Icons.bakery_dining),

  /// Exemplos: Frango assado, lasanhas prontas, maionese
  rotisseria('Rotisseria', Icons.restaurant),

  /// Exemplos: Ração, areia sanitária, brinquedos para pets
  petShop('Pet Shop', Icons.pets),

  /// Exemplos: Pilhas, lâmpadas, fósforos, utilidades rápidas
  bazar('Bazar', Icons.shopping_bag),

  /// Exemplos: Pizzas, nuggets, sorvetes, polpas de fruta
  congelados('Congelados', Icons.ac_unit),

  /// Exemplos: Fraldas, lenços umedecidos, fórmulas infantis
  cuidadosBebe('Bebê', Icons.child_care),

  /// Exemplos: Whey protein, creatina, vitaminas
  suplementosSaude('Saúde e Suplementos', Icons.health_and_safety),

  /// Exemplos: Produtos sem glúten, diet, orgânicos, granola
  produtosNaturais('Saudáveis/Especiais', Icons.spa),

  /// Exemplos: Medicamentos isentos, curativos, termômetros
  farmacia('Farmácia', Icons.local_pharmacy),

  /// Exemplos: Maquiagem, perfumes, cremes faciais
  perfumaria('Perfumaria', Icons.auto_fix_high),

  /// Exemplos: Flores naturais, vasos, adubos
  floricultura('Floricultura', Icons.local_florist),

  /// Exemplos: Panelas, talheres, organizadores de cozinha
  casaUtensilios('Casa e Utensílios', Icons.chair),

  /// Exemplos: Cadernos, canetas, papel A4, pastas
  papelariaEscritorio('Papelaria', Icons.edit),

  /// Exemplos: Mouses, teclados, fones, pequenos eletros
  eletroInformatica('Eletro e Informática', Icons.devices),

  /// Exemplos: Ferramentas manuais, mangueiras, vasos de jardim
  ferramentasJardim('Ferramentas e Jardim', Icons.construction),

  /// Exemplos: Camisetas básicas, meias, chinelos
  vestuario('Vestuário', Icons.checkroom),

  /// Exemplos: Bonecas, carrinhos, jogos de tabuleiro
  brinquedosJogos('Brinquedos e Jogos', Icons.videogame_asset),

  /// Exemplos: Isqueiros, sedas, tabaco, carvão narguilé
  tabacaria('Tabacaria', Icons.smoking_rooms),

  /// Exemplos: Balões, descartáveis para festas, enfeites
  festasDecoracao('Festas e Decoração', Icons.celebration),

  /// Exemplos: Óleo motor, ceras, aditivos, cheirinho de carro
  automotivo('Automotivo', Icons.directions_car),

  /// Itens diversos não categorizados
  outros('Outros', Icons.more_horiz);

  final String label;
  final IconData icon;

  const CategoriaProduto(this.label, this.icon);

  /// Converte uma String (geralmente vinda do Banco de Dados) no Enum correspondente
  static CategoriaProduto fromLabel(String label) {
    return CategoriaProduto.values.firstWhere(
      (e) => e.label == label,
      orElse: () => CategoriaProduto.outros,
    );
  }

  /// Retorna uma lista com apenas os labels (útil para UI)
  static List<String> get allLabels =>
      CategoriaProduto.values.map((e) => e.label).toList();
}
