import 'package:flutter/material.dart';
import '../../../../../enums/produto_enums.dart';
import '../../../../../services/shared/categorias_produto_service.dart';

class CategoriaProvider extends ChangeNotifier {
  final _service = CategoriasProdutoService();

  // Estado da Seleção
  CategoriaProduto? _categoriaSelecionada;
  String? _produtoBaseSelecionado;
  String? _variacaoSelecionada;

  // Listas de Dados
  List<Map<String, dynamic>> _dadosBrutos = []; // Armazena o par base/variação
  List<String> _listaProdutosBase = [];
  List<String> _listaVariacoes = [];

  // Controle de UI
  bool _carregando = false;

  // Controllers para novos cadastros (se decidir voltar com a lógica manual)
  final produtoBaseManualController = TextEditingController();
  final variacaoManualController = TextEditingController();

  // Getters
  CategoriaProduto? get categoriaSelecionada => _categoriaSelecionada;
  String? get produtoBaseSelecionado => _produtoBaseSelecionado;
  String? get variacaoSelecionada => _variacaoSelecionada;
  List<String> get listaProdutosBase => _listaProdutosBase;
  List<String> get listaVariacoes => _listaVariacoes;
  bool get carregando => _carregando;

  /// 1. Seleciona a Categoria e busca no Supabase
  Future<void> setCategoria(CategoriaProduto? cat) async {
    _categoriaSelecionada = cat;
    _produtoBaseSelecionado = null;
    _variacaoSelecionada = null;
    _listaProdutosBase = [];
    _listaVariacoes = [];

    if (cat != null) {
      _carregando = true;
      notifyListeners();

      // Busca todos os dados daquela categoria de uma vez só para economizar requisições
      _dadosBrutos = await _service.buscarBasesEVariacoes(cat.label);

      // Extrai apenas as bases únicas para o primeiro dropdown
      _listaProdutosBase = _dadosBrutos
          .map((e) => e['produto_base'] as String)
          .toSet()
          .toList()
        ..sort();

      _carregando = false;
    }
    notifyListeners();
  }

  /// 2. Seleciona o Produto Base e filtra as variações localmente
  void setProdutoBase(String? base) {
    _produtoBaseSelecionado = base;
    _variacaoSelecionada = null;
    _listaVariacoes = [];

    if (base != null) {
      // Filtra os dados que já temos em memória
      _listaVariacoes = _dadosBrutos
          .where((e) => e['produto_base'] == base)
          .map((e) => e['variacao'] as String)
          .toSet()
          .toList()
        ..sort();
    }
    notifyListeners();
  }

  /// 3. Seleciona a Variação Final
  void setVariacao(String? variacao) {
    _variacaoSelecionada = variacao;
    notifyListeners();
  }

  /// Limpa todo o formulário
  void resetar() {
    _categoriaSelecionada = null;
    _produtoBaseSelecionado = null;
    _variacaoSelecionada = null;
    _dadosBrutos = [];
    _listaProdutosBase = [];
    _listaVariacoes = [];
    produtoBaseManualController.clear();
    variacaoManualController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    produtoBaseManualController.dispose();
    variacaoManualController.dispose();
    super.dispose();
  }
}
