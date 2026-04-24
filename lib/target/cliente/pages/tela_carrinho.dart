import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/cliente/carrinho_service.dart';
import '../../../models/carrinho_item.dart';
import '../../../services/shared/usuario_service.dart';
import '../../../services/shared/usuario_provider.dart';
import '../widgets/secao_mercado_carrinho.dart';
import '../../shared/pages/login_page.dart';

class CarrinhoPage extends StatefulWidget {
  final VoidCallback? onPedidoFinalizado;
  const CarrinhoPage({super.key, this.onPedidoFinalizado});

  @override
  State<CarrinhoPage> createState() => _CarrinhoPageState();
}

class _CarrinhoPageState extends State<CarrinhoPage> {
  final UsuarioService _service = UsuarioService();
  final _supabase = Supabase.instance.client;
  bool _processando = false;

  final Map<String, bool> _valorMinimoAtingido = {};
  final Map<String, double> _taxasMercado = {};

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final carrinho = Provider.of<CarrinhoService>(context);
    final itens = carrinho.itens;

    int totalProdutos = itens.isEmpty ? 0 : itens.length;

    final Map<String, List<CarrinhoItem>> itensAgrupados = {};
    for (var item in itens) {
      itensAgrupados.putIfAbsent(item.mercadoId, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Meu Carrinho ($totalProdutos)",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        backgroundColor: cores.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _processando
          ? _buildTelaProcessando()
          : itens.isEmpty
              ? _buildCarrinhoVazio()
              : _buildListaAgrupada(carrinho, itensAgrupados),
      bottomNavigationBar:
          (itens.isEmpty || _processando) ? null : _buildResumoCompra(carrinho),
    );
  }

  Widget _buildListaAgrupada(
      CarrinhoService carrinho, Map<String, List<CarrinhoItem>> agrupamento) {
    final idsMercados = agrupamento.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: idsMercados.length,
      itemBuilder: (context, index) {
        final mercadoId = idsMercados[index];
        return SecaoMercadoCarrinho(
          mercadoId: mercadoId,
          itens: agrupamento[mercadoId]!,
          carrinho: carrinho,
          service: _service,
          onValidacaoMudou: (id, atingiu, taxa) {
            if (_valorMinimoAtingido[id] != atingiu ||
                _taxasMercado[id] != taxa) {
              Future.delayed(Duration.zero, () {
                if (mounted) {
                  setState(() {
                    _valorMinimoAtingido[id] = atingiu;
                    _taxasMercado[id] = taxa;
                  });
                }
              });
            }
          },
        );
      },
    );
  }

  Widget _buildResumoCompra(CarrinhoService carrinho) {
    bool pgtosOk = carrinho.todosPagamentosSelecionados();

    double totalTaxasAdicionais = 0;
    _taxasMercado.forEach((id, taxa) {
      if (_valorMinimoAtingido[id] == false) {
        totalTaxasAdicionais += taxa;
      }
    });

    double valorFinalComTaxas = carrinho.valorTotal + totalTaxasAdicionais;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ADIÇÃO: Aviso de transparência sobre itens pesáveis
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              "* Itens por peso (kg) podem ter o valor ajustado após a pesagem.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (totalTaxasAdicionais > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Taxas de entrega",
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold)),
                  Text("R\$ ${totalTaxasAdicionais.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Geral",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              Text("R\$ ${valorFinalComTaxas.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color.fromARGB(255, 17, 0, 255))),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: pgtosOk ? Colors.red : Colors.grey[400],
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: pgtosOk ? () => _finalizar(carrinho) : null,
            child: Text(
              pgtosOk ? "FINALIZAR PEDIDO" : "SELECIONE OS PAGAMENTOS",
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizar(CarrinhoService carrinho) async {
    final clienteProvider = context.read<UsuarioProvider>();

    if (_supabase.auth.currentUser == null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
      return;
    }

    if (!clienteProvider.temPerfil) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil do cliente não carregado.")));
      return;
    }

    setState(() => _processando = true);

    try {
      final Map<String, List<CarrinhoItem>> agrupamento = {};
      for (var item in carrinho.itens) {
        agrupamento.putIfAbsent(item.mercadoId, () => []).add(item);
      }

      final Map<String, double> taxasParaEnviar = {};
      for (var mercadoId in agrupamento.keys) {
        bool atingiuMinimo = _valorMinimoAtingido[mercadoId] ?? false;
        double taxaMercado = _taxasMercado[mercadoId] ?? 0.0;

        taxasParaEnviar[mercadoId] = atingiuMinimo ? 0.0 : taxaMercado;
      }

      // Aqui os itens são enviados para o serviço, que deve mapear
      // o código de barras e a unidade de medida para o banco de dados.
      await _service.finalizarPedidoMultimercado(
        agrupamento: agrupamento,
        pagamentos: carrinho.pagamentosPorMercado,
        taxas: taxasParaEnviar,
        cliente: clienteProvider.usuario!,
      );

      carrinho.limparCarrinho();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Pedido realizado com sucesso!"),
            backgroundColor: Colors.green));

        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }

        if (widget.onPedidoFinalizado != null) {
          widget.onPedidoFinalizado!();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erro ao finalizar: $e"),
            backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildTelaProcessando() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.red),
          SizedBox(height: 16),
          Text("Finalizando seu pedido...",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildCarrinhoVazio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_shopping_cart_outlined,
              size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("Seu carrinho está vazio",
              style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }
}
