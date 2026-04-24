import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mercado_app/models/produto.dart';
import '../../models/mercado.dart';
import '../../models/item_mercado.dart';
import 'mercado_shared_service.dart';

class MercadoSharedProvider with ChangeNotifier {
  final MercadoSharedService _service = MercadoSharedService();
  StreamSubscription<Mercado>? _mercadoSubscription;

  Mercado? _mercado;
  String? _mercadoId;

  /// Lista de itens/produtos vinculados a este mercado
  List<ItemMercado> _itensMercado = [];

  Mercado? get mercado => _mercado;
  String? get mercadoId => _mercadoId;
  List<ItemMercado> get itensMercado => _itensMercado;

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - INICIAR/GERENCIAR MERCADO
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Future<void> inicializarComMercado(String id) async {
    if (_mercadoId == id && _mercadoSubscription != null) return;

    _mercadoId = id;

    await _mercadoSubscription?.cancel();

    _mercadoSubscription = _service.streamMercado(id).listen(
      (mercadoAtualizado) {
        _mercado = mercadoAtualizado;
        _itensMercado = mercadoAtualizado.itens;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Erro no stream: $error");
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _mercadoSubscription?.cancel();
    super.dispose();
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - GESTÃO DE PRODUTOS GLOBAIS
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Future<void> cadastrarProdutoGlobal(Produto produto) async {
    try {
      await _service.salvarProdutoGlobal(produto);
    } catch (e) {
      debugPrint("Erro no Provider ao cadastrar global: $e");
      rethrow;
    }
  }

  Future<Produto?> buscarProdutoGlobal(String ean) async {
    try {
      return await _service.buscarProdutoGlobal(ean);
    } catch (e) {
      debugPrint("Erro no Provider ao buscar produto global: $e");
      return null;
    }
  }

  Future<List<Produto>> buscarProdutosGlobaisPorTermo(String termo) async {
    try {
      return await _service.buscarProdutosGlobaisPorTermo(termo);
    } catch (e) {
      debugPrint("Erro no Provider ao buscar produtos: $e");
      return [];
    }
  }

  Future<List<Produto>> listarProdutosGlobais() async {
    try {
      return await _service.listarProdutosGlobais();
    } catch (e) {
      debugPrint("Erro no Provider ao listar produtos aleatórios: $e");
      return [];
    }
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - GESTÃO DE INVENTÁRIO
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Future<void> adicionarProduto(ItemMercado item) async {
    if (_mercadoId == null) return;
    try {
      await _service.adicionarItemAoInventario(_mercadoId!, item);
    } catch (e) {
      debugPrint("Erro ao adicionar produto no Provider: $e");
      rethrow;
    }
  }

  Future<void> atualizarItem(ItemMercado item) async {
    if (_mercadoId == null) return;
    try {
      await _service.atualizarItemNoInventario(_mercadoId!, item);
    } catch (e) {
      debugPrint("Erro ao atualizar item no Provider: $e");
      rethrow;
    }
  }

  Future<void> removerItem(String codigoBarras) async {
    if (_mercadoId == null) return;
    try {
      await _service.removerItemDoInventario(_mercadoId!, codigoBarras);
    } catch (e) {
      debugPrint("Erro ao remover item no Provider: $e");
      rethrow;
    }
  }
}
