import 'package:flutter/material.dart';
import '../../models/mercado.dart';
import '../../models/usuario.dart';
import '../../models/carrinho_item.dart';
import 'cliente_service.dart';

class ClienteProvider extends ChangeNotifier {
  final ClienteService _service = ClienteService();

  // Estado dos dados
  List<Mercado> _mercadosProximos = [];
  bool _carregando = false;
  String? _mensagemErro;

  // Getters
  List<Mercado> get mercadosProximos => _mercadosProximos;
  bool get estaCarregando => _carregando;
  String? get mensagemErro => _mensagemErro;

  // ==========================================
  // MERCADO
  // ==========================================
  Future<void> carregarMercadosPorLocalizacao({
    required String cidade,
    required String estado,
  }) async {
    _setCarregando(true);
    _limparMensagemErro();

    try {
      _mercadosProximos = await _service.buscarMercadosPorLocalizacao(
        cidade: cidade,
        estado: estado,
      );
    } catch (e) {
      _tratarErro("Não foi possível carregar os mercados da sua região.");
    } finally {
      _setCarregando(false);
    }
  }

  // ==========================================
  // PEDIDOS
  // ==========================================
  Future<bool> finalizarPedido({
    required Map<String, List<CarrinhoItem>> agrupamento,
    required Map<String, String> pagamentos,
    required Map<String, double> taxas,
    required Usuario cliente,
  }) async {
    _setCarregando(true);
    _limparMensagemErro();

    try {
      await _service.finalizarPedidoMultimercado(
        agrupamento: agrupamento,
        pagamentos: pagamentos,
        taxas: taxas,
        cliente: cliente,
      );
      return true; // Sucesso
    } catch (e) {
      _tratarErro("Erro ao processar seu pedido. Verifique sua conexão.");
      return false; // Falha
    } finally {
      _setCarregando(false);
    }
  }

  // ==========================================
  // MÉTODOS DE ESTADO E UTILITÁRIOS
  // ==========================================
  void _setCarregando(bool valor) {
    _carregando = valor;
    notifyListeners();
  }

  void _tratarErro(String mensagem) {
    _mensagemErro = mensagem;
    notifyListeners();
  }

  void _limparMensagemErro() {
    _mensagemErro = null;
  }

  void limparErroManual() {
    _mensagemErro = null;
    notifyListeners();
  }

  void limpar() {
    _mercadosProximos = [];
    _carregando = false;
    _mensagemErro = null;
    notifyListeners();
  }
}
