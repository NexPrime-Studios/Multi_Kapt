import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../services/cliente_service.dart';

class ClienteProvider extends ChangeNotifier {
  final ClienteService _clienteService = ClienteService();
  Cliente? _cliente;

  Cliente? get cliente => _cliente;

  // Verifica se existe um perfil carregado
  bool get temPerfil => _cliente != null;

  void atualizarCliente(Cliente novoCliente) {
    _cliente = novoCliente;

    notifyListeners();
  }

  Future<void> salvarEAtualizarPerfil(Cliente clienteEditado) async {
    try {
      // 1. Comando de atualização via Service (Banco de Dados)
      await _clienteService.atualizarDadosPerfil(clienteEditado);

      atualizarCliente(clienteEditado);
    } catch (e) {
      rethrow;
    }
  }

  void limparCliente() {
    _cliente = null;
    notifyListeners();
  }
}
