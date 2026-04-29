import 'package:flutter/material.dart';
import '../../models/mercado.dart';
import '../../models/pedido.dart';
import '../../models/funcionario.dart';
import 'lojista_service.dart';

class LojistaProvider extends ChangeNotifier {
  final LojistaService _service = LojistaService();

  List<Funcionario> _equipe = [];
  List<Map<String, dynamic>> _meusMercados = [];
  bool _carregando = false;
  String? _mensagemErro;

  // Getters
  List<Funcionario> get equipe => _equipe;
  List<Map<String, dynamic>> get meusMercados => _meusMercados;
  bool get estaCarregando => _carregando;
  String? get mensagemErro => _mensagemErro;

  // ==========================================
  // GESTÃO DO MERCADO
  // ==========================================
  Future<void> inicializarMercados() async {
    _setCarregando(true);
    _limparErro();
    try {
      _meusMercados = await _service.buscarMercadosPorEmail();
    } catch (e) {
      _tratarErro("Erro ao buscar seus mercados. Verifique sua conexão.");
    } finally {
      _setCarregando(false);
    }
  }

  Future<String?> cadastrarNovoMercado(Mercado mercado) async {
    _limparErro();
    try {
      return await _service.adicionarMercado(mercado);
    } catch (e) {
      _tratarErro("Falha ao cadastrar mercado. Tente novamente.");
      return null;
    }
  }

  Future<void> editarMercado(Mercado mercado) async {
    _limparErro();
    try {
      await _service.atualizarMercado(mercado);
      await inicializarMercados();
    } catch (e) {
      _tratarErro("Não foi possível atualizar os dados do mercado.");
    }
  }

  Future<void> alternarStatusLoja(String mercadoId, bool aberto) async {
    _limparErro();
    try {
      await _service.atualizarStatusMercado(mercadoId, aberto);
      notifyListeners();
    } catch (e) {
      _tratarErro("Erro ao alterar o status da loja.");
    }
  }

  // ==========================================
  // GESTÃO DE FUNCIONÁRIOS
  // ==========================================
  Future<void> carregarEquipe(String mercadoId) async {
    _setCarregando(true);
    _limparErro();
    try {
      _equipe = await _service.listarFuncionarios(mercadoId);
    } catch (e) {
      _tratarErro("Erro ao carregar a lista de funcionários.");
    } finally {
      _setCarregando(false);
    }
  }

  Future<void> salvarFuncionario(Funcionario funcionario) async {
    _limparErro();
    try {
      await _service.salvarFuncionario(funcionario);
      await carregarEquipe(funcionario.mercadoId);
    } catch (e) {
      _tratarErro("Erro ao salvar dados do funcionário.");
    }
  }

  Future<void> alternarStatusFuncionario(
      String id, bool ativo, String mercadoId) async {
    _limparErro();
    try {
      await _service.alternarStatusFuncionario(id, ativo);
      await carregarEquipe(mercadoId);
    } catch (e) {
      _tratarErro("Erro ao alterar status do funcionário.");
    }
  }

  // ==========================================
  // PEDIDOS
  // ==========================================
  Future<void> atribuirFuncionarioAoPedido({
    required String pedidoId,
    required Funcionario funcionario,
  }) async {
    _limparErro();
    try {
      await _service.atribuirFuncionarioAoPedido(
        pedidoId: pedidoId,
        funcionario: funcionario,
      );
    } catch (e) {
      _tratarErro("Falha ao atribuir funcionário ao pedido.");
    }
  }

  Future<List<Pedido>> buscarHistorico({
    required String mercadoId,
    required DateTime dataLimite,
    int offset = 0,
  }) async {
    _limparErro();
    try {
      return await _service.buscarHistoricoPedidosPaginados(
        mercadoId: mercadoId,
        dataLimite: dataLimite,
        offset: offset,
      );
    } catch (e) {
      _tratarErro("Erro ao carregar histórico de pedidos.");
      return [];
    }
  }

  // ==========================================
  // UTILITÁRIOS
  // ==========================================
  void _setCarregando(bool valor) {
    _carregando = valor;
    notifyListeners();
  }

  void _tratarErro(String mensagem) {
    _mensagemErro = mensagem;
    notifyListeners();
  }

  void _limparErro() {
    _mensagemErro = null;
  }

  void limpar() {
    _equipe = [];
    _meusMercados = [];
    _carregando = false;
    _mensagemErro = null;
    notifyListeners();
  }
}
