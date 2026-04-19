import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app_theme.dart';
import '../../../services/funcionario_service.dart';
import '../../../services/funcionario_provider.dart';
import '../../../models/item_pedido.dart';
import '../widgets/scanner_barcode_page.dart';
import '../widgets/item_coleta_widget.dart';

class ColetaPedidoPage extends StatefulWidget {
  const ColetaPedidoPage({super.key});

  @override
  State<ColetaPedidoPage> createState() => _ColetaPedidoPageState();
}

class _ColetaPedidoPageState extends State<ColetaPedidoPage> {
  final FuncionarioService _service = FuncionarioService();
  final Map<int, bool?> _statusItens = {};
  bool _processando = false;
  String? _ultimoPedidoId;

  // Sincroniza o estado dos checkboxes com a lista de itens do pedido atual
  void _sincronizarChecks(Map<String, dynamic>? pedido) {
    if (pedido == null) {
      _statusItens.clear();
      _ultimoPedidoId = null;
      return;
    }
    if (_ultimoPedidoId != pedido['id'].toString()) {
      _statusItens.clear();
      final List itens = pedido['itens'] ?? [];
      for (int i = 0; i < itens.length; i++) {
        // null = não mexeu, true = coletado, false = em falta
        _statusItens[i] = null;
      }
      _ultimoPedidoId = pedido['id'].toString();
    }
  }

  void _abrirScanner(List itens) async {
    final String? codigoLido = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerBarcodePage()),
    );

    if (codigoLido == null || !mounted) return;

    bool encontrado = false;
    for (int i = 0; i < itens.length; i++) {
      final itemModel = ItemPedido.fromMap(itens[i]);

      if (itemModel.codigoBarras == codigoLido) {
        if (_statusItens[i] == true) {
          _mostrarSnack("Item já coletado!", Colors.orange);
        } else {
          setState(() {
            _statusItens[i] = true;
            itemModel.emFalta = false;
            itemModel.quantidadeColetada = itemModel.quantidade;
            itemModel.precoFinal = itemModel.preco;
            itens[i] = itemModel.toMap();
          });
          HapticFeedback.mediumImpact();
          _mostrarSnack("Coletado: ${itemModel.nome}", Colors.green);
        }
        encontrado = true;
        break;
      }
    }
    if (!encontrado) {
      HapticFeedback.vibrate();
      _mostrarSnack("Produto não pertence a este pedido!", Colors.red);
    }
  }

  void _mostrarSnack(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: cor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _concluirColeta(Map<String, dynamic> pedido) async {
    final funcProv = context.read<FuncionarioProvider>();
    setState(() => _processando = true);

    try {
      // O service muda o status para 'pronto' no Firebase
      await _service.finalizarSeparacaoPedido(
        pedidoId: pedido['id'].toString(),
        itensAtualizados: pedido['itens'],
      );

      HapticFeedback.heavyImpact();

      if (mounted) {
        _mostrarSnack(
            "Coleta finalizada! Pedido enviado para Entrega.", Colors.green);

        // Limpa o pedido atual do Provider. Isso fará a tela voltar
        // para o estado de "Nenhuma coleta ativa" automaticamente.
        Future.delayed(const Duration(milliseconds: 300), () {
          funcProv.setPedidoEmColeta(null);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processando = false);
        _mostrarSnack("Erro ao salvar: $e", Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final funcProv = context.watch<FuncionarioProvider>();
    final pedido = funcProv.pedidoEmColeta;

    // Se não houver pedido sendo coletado, mostra aviso
    if (pedido == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text("Coleta Atual"), backgroundColor: Colors.orange),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_basket_outlined,
                  size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text("Nenhuma coleta ativa no momento.",
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    _sincronizarChecks(pedido);
    final List itens = pedido['itens'] ?? [];

    // O botão FINALIZAR só habilita se todos os itens tiverem um veredito (OK ou FALTA)
    final bool todosProcessados =
        !_statusItens.values.contains(null) && itens.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text("Separação de Itens"),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          _buildHeaderCompacto(pedido),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: itens.length,
              itemBuilder: (context, index) {
                return ItemColetaWidget(
                  index: index,
                  item: itens[index],
                  status: _statusItens[index],
                  onStatusChanged: (idx, novoStatus) {
                    setState(() {
                      _statusItens[idx] = novoStatus;
                      final itemModel = ItemPedido.fromMap(itens[idx]);

                      if (novoStatus == false) {
                        itemModel.emFalta = true;
                        itemModel.quantidadeColetada = 0.0;
                        itemModel.precoFinal = 0.0;
                      } else if (novoStatus == true) {
                        itemModel.emFalta = false;
                        if (itemModel.quantidadeColetada == 0) {
                          itemModel.quantidadeColetada = itemModel.quantidade;
                          itemModel.precoFinal = itemModel.preco;
                        }
                      }
                      itens[idx] = itemModel.toMap();
                    });
                  },
                  onValueUpdated: (idx, novaQtd) {
                    setState(() {
                      final itemModel = ItemPedido.fromMap(itens[idx]);
                      itemModel.quantidadeColetada = novaQtd;
                      itemModel.precoFinal = (itemModel.preco /
                              (itemModel.quantidade == 0
                                  ? 1
                                  : itemModel.quantidade)) *
                          novaQtd;

                      if (novaQtd > 0) {
                        itemModel.emFalta = false;
                        _statusItens[idx] = true;
                      } else {
                        itemModel.emFalta = true;
                        _statusItens[idx] = false;
                      }
                      itens[idx] = itemModel.toMap();
                    });
                  },
                  onSolicitarScanSubstituicao: () => _iniciarScanSubstituicao(
                      index, itens, pedido['mercado_id']),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBarraAcoes(todosProcessados, pedido, itens),
    );
  }

  Widget _buildHeaderCompacto(Map<String, dynamic> pedido) {
    final String idStr = pedido['id'].toString();
    final String idCurto =
        idStr.length > 5 ? idStr.substring(0, 5).toUpperCase() : idStr;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Pedido: #$idCurto",
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
            child: Text(
              "Cli: ${pedido['nome_cliente']}",
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraAcoes(
      bool habilitado, Map<String, dynamic> pedido, List itens) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _abrirScanner(itens),
                icon: const Icon(Icons.qr_code_scanner, color: Colors.orange),
                label: const Text("BIPAR",
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: habilitado ? Colors.green : Colors.grey[300],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (habilitado && !_processando)
                    ? () => _concluirColeta(pedido)
                    : null,
                child: _processando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text("FINALIZAR",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                habilitado ? Colors.white : Colors.grey[600])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _iniciarScanSubstituicao(
      int indexOriginal, List itensDaLista, String mercadoId) async {
    final String? codigoBipado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerBarcodePage()),
    );

    if (codigoBipado != null) {
      try {
        final novoProdutoMap =
            await _service.buscarProdutoPorCodigo(codigoBipado, mercadoId);

        if (novoProdutoMap != null) {
          setState(() {
            final itemOriginal =
                ItemPedido.fromMap(itensDaLista[indexOriginal]);
            final itemOriginalEmFalta = itemOriginal.copyWith(
              emFalta: true,
              quantidadeColetada: 0.0,
              precoFinal: 0.0,
            );
            itensDaLista[indexOriginal] = itemOriginalEmFalta.toMap();
            _statusItens[indexOriginal] = false;

            final novoItemSubstituto = ItemPedido(
              id: "sub_${novoProdutoMap['id']}_${DateTime.now().millisecondsSinceEpoch}",
              nome: "${novoProdutoMap['produtoNome']}",
              codigoBarras: novoProdutoMap['codigo_barras']?.toString(),
              preco: (novoProdutoMap['preco'] as num).toDouble(),
              quantidade: itemOriginal.quantidade,
              substituido: true,
              emFalta: false,
            );

            final String unidade =
                novoProdutoMap['unidade']?.toString().toLowerCase() ?? 'un';
            ItemPedido itemFinal;

            if (unidade != 'kg') {
              itemFinal = novoItemSubstituto.copyWith(
                quantidadeColetada: novoItemSubstituto.quantidade,
                precoFinal:
                    novoItemSubstituto.preco * novoItemSubstituto.quantidade,
              );
            } else {
              itemFinal = novoItemSubstituto;
            }

            itensDaLista.insert(indexOriginal + 1, itemFinal.toMap());
            _statusItens[indexOriginal + 1] = (unidade != 'kg') ? true : null;
          });

          _mostrarSnack("Substituição adicionada!", Colors.blue);
        } else {
          _mostrarSnack("Produto não encontrado neste mercado.", Colors.red);
        }
      } catch (e) {
        _mostrarSnack("Erro ao substituir: $e", Colors.red);
      }
    }
  }
}
