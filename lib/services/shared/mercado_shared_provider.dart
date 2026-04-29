import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mercado_app/models/produto.dart';
import '../../models/mercado.dart';
import '../../models/item_mercado.dart';
import 'mercado_shared_service.dart';

class MercadoSharedProvider with ChangeNotifier {
  final MercadoSharedService _service = MercadoSharedService();

  Mercado? _mercado;
  String? _mercadoId;

  /// Lista de itens/preços vinculados a este mercado na tabela produtos_mercado
  List<ItemMercado> _itensMercado = [];

  Mercado? get mercado => _mercado;
  String? get mercadoId => _mercadoId;
  List<ItemMercado> get itensMercado => _itensMercado;

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - INICIAR/GERENCIAR MERCADO
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Future<void> inicializarComMercado(String id) async {
    if (_mercadoId == id && _mercado != null) return;

    _mercadoId = id;

    try {
      _mercado = await _service.buscarMercadoPorId(id);
      await carregarItensDoMercado();
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao inicializar mercado: $e");
    }
  }

  Future<void> carregarItensDoMercado() async {
    if (_mercadoId == null) return;
    try {
      _itensMercado = await _service.listarItensDoMercado(_mercadoId!);
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao carregar itens do inventário: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - GESTÃO DE PRODUTOS GLOBAIS
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  Future<void> criarAtualizarProdutoGlobal(Produto produto) async {
    try {
      await _service.criarAtualizarProdutoGlobal(produto);
    } catch (e) {
      debugPrint("Erro no Provider ao cadastrar global: $e");
      rethrow;
    }
  }

  Future<Produto?> buscarProdutoGlobalPorEan(String ean) async {
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

  Future<List<Produto>> listarPrimeirosProdutosGlobais() async {
    try {
      return await _service.listarPrimeirosProdutosGlobais();
    } catch (e) {
      debugPrint("Erro no Provider ao listar produtos: $e");
      return [];
    }
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // MARK: - GESTÃO DE INVENTÁRIO (PRODUTOS_MERCADO)
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  Future<void> adicionarAtualizarItemNoMercado(ItemMercado item) async {
    try {
      await _service.adicionarAtualizarItemNoMercado(item);
      await carregarItensDoMercado();
    } catch (e) {
      debugPrint("Erro ao salvar item no Provider: $e");
      rethrow;
    }
  }

  /// Remove o vínculo de um produto com este mercado
  Future<void> removerItem(String produtoId) async {
    if (_mercadoId == null) return;
    try {
      await _service.removerItemDoMercado(_mercadoId!, produtoId);
      // Remove da lista local para atualizar a tela
      _itensMercado.removeWhere((i) => i.produtoId == produtoId);
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao remover item no Provider: $e");
      rethrow;
    }
  }
}
