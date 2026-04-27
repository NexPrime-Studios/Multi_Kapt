import 'package:flutter/material.dart';
import '../../../../../models/produto_enums.dart';
import '../../../../../services/shared/categorias_produto_service.dart';

class CategoriaProvider extends ChangeNotifier {
  final _service = CategoriasProdutoService();

  List<dynamic> _cacheDadosCategoria = [];

  CategoriaProduto? categoriaSelecionada;
  String? subcategoriaSelecionada;
  String? produtoBaseSelecionado;
  String? variacaoSelecionada;

  // Variáveis para armazenar texto manual (caso não exista no banco)
  String subcategoriaManual = "";
  String produtoBaseManual = "";
  String variacaoManual = "";

  List<String> listaSubcategorias = [];
  List<String> listaProdutosBase = [];
  List<String> listaVariacoes = [];

  bool carregandoSub = false;

  Future<void> setCategoria(CategoriaProduto? categoria) async {
    if (categoria == categoriaSelecionada) return;

    categoriaSelecionada = categoria;
    _resetarNiveisAbaixo(resetaSub: true);

    if (categoria != null) {
      carregandoSub = true;
      notifyListeners();

      _cacheDadosCategoria =
          await _service.fetchDadosCompletosDaCategoria(categoria);

      listaSubcategorias = _cacheDadosCategoria
          .map((e) => e['subcategoria'].toString())
          .toList();

      carregandoSub = false;
    }
    notifyListeners();
  }

  void setSubcategoria(String? subNome) {
    subcategoriaSelecionada = subNome;
    subcategoriaManual = "";
    _resetarNiveisAbaixo(resetaProd: true);

    if (subNome != null && subNome != "ADICIONAR_NOVA") {
      final dadosSub = _cacheDadosCategoria.firstWhere(
        (e) => e['subcategoria'] == subNome,
        orElse: () => null,
      );

      if (dadosSub != null) {
        final List itens = dadosSub['itens'] ?? [];
        listaProdutosBase =
            itens.map((i) => i['produtoBase'].toString()).toList();
      }
    }
    notifyListeners();
  }

  void setProdutoBase(String? prodNome) {
    produtoBaseSelecionado = prodNome;
    produtoBaseManual = "";
    _resetarNiveisAbaixo(resetaVar: true);

    if (prodNome != null && prodNome != "ADICIONAR_NOVA") {
      final dadosSub = _cacheDadosCategoria.firstWhere(
        (e) => e['subcategoria'] == subcategoriaSelecionada,
      );

      final List itens = dadosSub['itens'] ?? [];
      final item = itens.firstWhere(
        (i) => i['produtoBase'] == prodNome,
        orElse: () => null,
      );

      if (item != null) {
        listaVariacoes = List<String>.from(item['variacoes'] ?? []);
      }
    }
    notifyListeners();
  }

  void setVariacao(String? valor) {
    variacaoSelecionada = valor;
    if (valor != "ADICIONAR_NOVA") variacaoManual = "";
    notifyListeners();
  }

  void _resetarNiveisAbaixo(
      {bool resetaSub = false,
      bool resetaProd = false,
      bool resetaVar = false}) {
    if (resetaSub) {
      subcategoriaSelecionada = null;
      subcategoriaManual = "";
      listaSubcategorias = [];
    }
    if (resetaSub || resetaProd) {
      produtoBaseSelecionado = null;
      produtoBaseManual = "";
      listaProdutosBase = [];
    }
    if (resetaSub || resetaProd || resetaVar) {
      variacaoSelecionada = null;
      variacaoManual = "";
      listaVariacoes = [];
    }
  }
}
