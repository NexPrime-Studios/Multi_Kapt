import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mercado_app/models/item_mercado.dart';
import 'package:mercado_app/services/shared/mercado_shared_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'funcionario_service.dart';
import '../../models/funcionario.dart';

class FuncionarioProvider extends ChangeNotifier {
  final FuncionarioService _service = FuncionarioService();
  MercadoSharedProvider mercadoSharedProvider;
  StreamSubscription? _pedidosSubscription;

  Funcionario? _funcionario;
  bool _isFuncionario;
  String? _mercadoId;
  String? _funcionarioId;
  String? _codigoFuncionario;

  bool _mostrarSelecao = false;
  bool _estaOcupado = false;
  int _quantidadePedidosAtivos = 0;
  Map<String, dynamic>? _pedidoEmColeta;
  Map<String, dynamic>? _pedidoEmEntrega;

  FuncionarioProvider({
    required bool isFuncionario,
    required this.mercadoSharedProvider,
    String? mercadoId,
    String? funcionarioId,
  })  : _isFuncionario = isFuncionario,
        _mercadoId = mercadoId,
        _funcionarioId = funcionarioId {
    if (_isFuncionario && _funcionarioId != null) {
      _inicializarDadosFuncionario();
    }
  }

  // Getters
  Funcionario? get funcionario => _funcionario;
  bool get isFuncionario => _isFuncionario;
  String? get mercadoId => _mercadoId;
  String? get funcionarioId => _funcionarioId;
  String? get codigoFuncionario => _codigoFuncionario;
  bool get mostrarSelecao => _mostrarSelecao;
  bool get estaOcupado => _estaOcupado;
  int get quantidadePedidosAtivos => _quantidadePedidosAtivos;
  Map<String, dynamic>? get pedidoEmColeta => _pedidoEmColeta;
  Map<String, dynamic>? get pedidoEmEntrega => _pedidoEmEntrega;

  Future<void> _inicializarDadosFuncionario() async {
    try {
      if (_funcionarioId == null) return;

      _funcionario = await _service.buscarDadosFuncionario(_funcionarioId!);

      if (_funcionario != null) {
        _codigoFuncionario = _funcionario?.codigoSenha;

        if (_mercadoId != null) {
          await mercadoSharedProvider.inicializarComMercado(_mercadoId!);
        }

        iniciarMonitoramentoPedidos();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erro ao inicializar dados do funcionário: $e");
    }
  }

  Future<void> vincularFuncionario(
      String mercadoId, String funcionarioId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('is_funcionario', true);
    await prefs.setString('mercado_vinculado_id', mercadoId);
    await prefs.setString('funcionario_id', funcionarioId);

    _isFuncionario = true;
    _mercadoId = mercadoId;
    _funcionarioId = funcionarioId;
    _mostrarSelecao = false;

    await mercadoSharedProvider.inicializarComMercado(mercadoId);
    await _inicializarDadosFuncionario();
  }

  /// Inicia a escuta em tempo real do Supabase
  void iniciarMonitoramentoPedidos() {
    _pedidosSubscription?.cancel();

    if (_mercadoId == null || _codigoFuncionario == null) return;

    _pedidosSubscription =
        _service.streamPedidos(_mercadoId!).listen((todosPedidos) {
      _sincronizarEstadoGeral(todosPedidos);
    });
  }

  void _sincronizarEstadoGeral(List<Map<String, dynamic>> todosPedidos) {
    // 1. Filtra pedido em Coleta usando o código descarregado
    final meuPedidoColeta =
        todosPedidos.cast<Map<String, dynamic>?>().firstWhere(
              (p) =>
                  p?['status'] == 'preparando' &&
                  p?['coletor_id'] == _codigoFuncionario,
              orElse: () => null,
            );

    // 2. Filtra pedido em Entrega usando o código descarregado
    final meuPedidoEntrega =
        todosPedidos.cast<Map<String, dynamic>?>().firstWhere(
              (p) =>
                  p?['status'] == 'saiu_para_entrega' &&
                  p?['entregador_id'] == _codigoFuncionario,
              orElse: () => null,
            );

    _pedidoEmColeta = meuPedidoColeta != null
        ? Map<String, dynamic>.from(meuPedidoColeta)
        : null;

    _pedidoEmEntrega = meuPedidoEntrega != null
        ? Map<String, dynamic>.from(meuPedidoEntrega)
        : null;

    _estaOcupado = (_pedidoEmColeta != null || _pedidoEmEntrega != null);

    _quantidadePedidosAtivos = todosPedidos.where((p) {
      final status = p['status'];
      return status == 'pendente' || status == 'pronto';
    }).length;

    notifyListeners();
  }

  void pararMonitoramento() {
    _pedidosSubscription?.cancel();
    _pedidosSubscription = null;
  }

  void irParaSelecao() {
    _mostrarSelecao = true;
    notifyListeners();
  }

  void entrarNoModo() {
    _mostrarSelecao = false;
    notifyListeners();
  }

  void setPedidoEmColeta(Map<String, dynamic>? pedido) {
    _pedidoEmColeta = pedido;
    _estaOcupado = (pedido != null);
    notifyListeners();
  }

  void setPedidoAtual(Map<String, dynamic>? pedido) {
    _pedidoEmEntrega = pedido;
    notifyListeners();
  }

  void setFuncionarioId(String id) {
    _funcionarioId = id;
    notifyListeners();
  }

  Future<void> desvincular() async {
    final prefs = await SharedPreferences.getInstance();
    pararMonitoramento();

    await prefs.remove('is_funcionario');
    await prefs.remove('mercado_vinculado_id');
    await prefs.remove('funcionario_id');

    _isFuncionario = false;
    _mercadoId = null;
    _funcionarioId = null;
    _codigoFuncionario = null;
    _mostrarSelecao = false;
    _estaOcupado = false;
    _pedidoEmColeta = null;
    _pedidoEmEntrega = null;

    notifyListeners();
  }

  Future<void> adicionarItemAoMercado(ItemMercado novoItem) async {
    if (mercadoId == null) return;

    await _service.adicionarItemAoInventario(mercadoId.toString(), novoItem);
    notifyListeners();
  }

  @override
  void dispose() {
    pararMonitoramento();
    super.dispose();
  }
}
