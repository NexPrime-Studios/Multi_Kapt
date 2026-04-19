import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'funcionario_service.dart';
import '../models/funcionario.dart'; //

class FuncionarioProvider extends ChangeNotifier {
  final FuncionarioService _service = FuncionarioService();
  StreamSubscription? _pedidosSubscription;

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

      final Funcionario? f =
          await _service.buscarDadosFuncionario(_funcionarioId!);

      if (f != null) {
        _codigoFuncionario = f.codigoSenha;
        iniciarMonitoramentoPedidos();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Erro ao inicializar dados do funcionário: $e");
    }
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

  /// Vínculo simplificado: Guarda apenas o ID. O código é baixado logo a seguir.
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

    // Aciona o download dos dados para obter o Código Senha
    await _inicializarDadosFuncionario();
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

  @override
  void dispose() {
    pararMonitoramento();
    super.dispose();
  }
}
