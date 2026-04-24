import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mercado_app/services/shared/mercado_shared_provider.dart';
import '../../models/mercado.dart';
import '../../models/pedido.dart';
import '../../models/funcionario.dart';
import '../../models/item_mercado.dart';
import 'lojista_service.dart';

class LojistaProvider extends ChangeNotifier {
  final LojistaService _service = LojistaService();
  MercadoSharedProvider mercadoSharedProvider;

  LojistaProvider({
    required this.mercadoSharedProvider,
  });

  String? _mercadoIdAtivo;
  CargoAcesso? _cargoAtual;
  Mercado? _mercado;
  List<Pedido> _pedidosAtivos = [];
  List<Funcionario> _equipe = [];
  List<ItemMercado> _promocoes = [];
  bool _carregando = true;

  // Variáveis para controlar e cancelar as conexões ativas
  StreamSubscription? _subMercado;
  StreamSubscription? _subPedidos;
  StreamSubscription? _subEquipe;

  // Getters
  String? get mercadoIdAtivo => _mercadoIdAtivo;
  CargoAcesso? get cargoAtual => _cargoAtual;
  LojistaService get service => _service;
  Mercado? get mercado => _mercado;
  List<Pedido> get pedidosAtivos => _pedidosAtivos;
  List<Funcionario> get equipe => _equipe;
  List<ItemMercado> get promocoes => _promocoes;
  bool get estaCarregando => _carregando;

  int get totalPendentes =>
      _pedidosAtivos.where((p) => p.status == StatusPedido.pendente).length;

  /// Método principal de entrada
  void inicializar(String adminUid) {
    _carregando = true;

    // CANCELA subscrições existentes para evitar erro de múltiplas streams/contexto
    _subMercado?.cancel();
    _subPedidos?.cancel();
    _subEquipe?.cancel();

    notifyListeners();

    // Ouvinte para dados do Mercado (Perfil)
    _subMercado = _service
        .streamMercadoPorAdmin(adminUid)
        .listen((mercadoEncontrado) async {
      _mercado = mercadoEncontrado;

      if (mercadoEncontrado != null) {
        await mercadoSharedProvider.inicializarComMercado(mercadoEncontrado.id);

        _ouvirPedidos(mercadoEncontrado.id);
        _ouvirEquipe(mercadoEncontrado.id);
        _processarPromocoes();
      }

      _carregando = false;
      notifyListeners();
    });
  }

  void selecionarMercadoAtivo(
      {required String mercadoId, required CargoAcesso cargo}) {
    _mercadoIdAtivo = mercadoId;
    _cargoAtual = cargo;
    notifyListeners();
  }

  /// Escuta pedidos que não foram entregues
  void _ouvirPedidos(String mercadoId) {
    _subPedidos?.cancel(); // Limpa antes de criar nova escuta
    _subPedidos =
        _service.buscarPedidosAtivos(mercadoId).listen((listaPedidos) {
      _pedidosAtivos = listaPedidos;
      notifyListeners();
    });
  }

  /// Escuta a lista de funcionários do mercado
  void _ouvirEquipe(String mercadoId) {
    _subEquipe?.cancel(); // Limpa antes de criar nova escuta
    _subEquipe =
        _service.listarFuncionarios(mercadoId).listen((listaFuncionarios) {
      _equipe = listaFuncionarios;
      notifyListeners();
    });
  }

  Future<String?> salvarFuncionarioCompleto({
    String? id,
    required String mercadoId,
    required String codigoId,
    required String nome,
    required String funcao,
    required bool ativo,
  }) async {
    try {
      final Map<String, dynamic> dados = {
        'mercado_id': mercadoId,
        'codigo_id': codigoId.toUpperCase(),
        'nome': nome,
        'funcao': funcao,
        'ativo': ativo,
      };

      if (id != null) dados['id'] = id;

      final res = await _service.supabase
          .from('funcionarios')
          .upsert(dados)
          .select()
          .single();

      return res['id'];
    } catch (e) {
      debugPrint("Erro ao salvar funcionário no Provider: $e");
      rethrow;
    }
  }

  Future<void> excluirFuncionario(String id) async {
    try {
      await _service.supabase.from('funcionarios').delete().eq('id', id);
    } catch (e) {
      debugPrint("Erro ao excluir funcionário no Provider: $e");
      rethrow;
    }
  }

  void _processarPromocoes() {
    if (_mercado == null) return;

    final agora = DateTime.now();
    _promocoes = _mercado!.itens.where((item) {
      if (item.precoPromocional == null || item.fimPromocao == null) {
        return false;
      }
      return item.fimPromocao!.isAfter(agora);
    }).toList();
  }

  Future<void> alternarStatusLoja() async {
    if (_mercado == null) return;
    final novoStatus = !_mercado!.estaAberto;
    await _service.atualizarStatusMercado(_mercado!.id, novoStatus);
  }

  Future<void> atualizarPerfil(Mercado mercadoAtualizado) async {
    await _service.atualizarMercado(mercadoAtualizado);
  }

  Future<void> removerItem(ItemMercado item) async {
    if (_mercado == null) return;
    await _service.removerItemDoInventario(_mercado!.id, item);
  }

  Future<void> adicionarItem(ItemMercado novoItem) async {
    if (_mercado == null) return;
    await _service.adicionarItemAoInventario(_mercado!.id, novoItem);
  }

  Future<void> toggleDisponibilidade(ItemMercado item, bool valor) async {
    if (_mercado == null) return;

    try {
      await _service.atualizarDisponibilidadeItem(
          _mercado!.id, item.produtoId, valor);
    } catch (e) {
      debugPrint("Erro ao alternar disponibilidade: $e");
      rethrow;
    }
  }

  Future<void> atualizarItem(ItemMercado itemAtualizado) async {
    if (_mercado == null) return;

    try {
      final List<ItemMercado> novosItens = List.from(_mercado!.itens);

      final index =
          novosItens.indexWhere((i) => i.produtoId == itemAtualizado.produtoId);
      if (index != -1) {
        novosItens[index] = itemAtualizado;
        final mercadoAtualizado = _mercado!.copyWith(itens: novosItens);
        await _service.atualizarMercado(mercadoAtualizado);
      }
    } catch (e) {
      debugPrint("Erro ao atualizar item no Provider: $e");
      rethrow;
    }
  }

  Future<void> salvarFuncionario(Funcionario f) async {
    await _service.salvarFuncionario(f);
  }

  Future<void> alternarStatusFuncionario(String id, bool ativo) async {
    await _service.alternarStatusFuncionario(id, ativo);
  }

  Future<void> removerFuncionario(String id) async {
    await _service.supabase.from('funcionarios').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> buscarHistoricoPedidosPaginados({
    required String mercadoId,
    required DateTime dataLimite,
    required int offset,
    int limit = 20,
  }) async {
    try {
      final resultados = await _service.buscarHistoricoPedidosPaginados(
        mercadoId: mercadoId,
        dataLimite: dataLimite,
        offset: offset,
        limit: limit,
      );

      return resultados;
    } catch (e) {
      debugPrint("Erro no LojistaProvider (buscarHistorico): $e");
      rethrow;
    }
  }

  void limpar() {
    _subMercado?.cancel();
    _subPedidos?.cancel();
    _subEquipe?.cancel();
    _mercado = null;
    _pedidosAtivos = [];
    _equipe = [];
    _promocoes = [];
    _carregando = true;
    notifyListeners();
  }

  @override
  void dispose() {
    // Garante que todas as conexões sejam fechadas quando o provider sair da memória
    _subMercado?.cancel();
    _subPedidos?.cancel();
    _subEquipe?.cancel();
    super.dispose();
  }
}
