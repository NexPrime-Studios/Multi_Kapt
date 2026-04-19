import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/lojista_provider.dart';
import '../widgets/relogio_widget.dart';
import '../widgets/card_pedido_lojista.dart';
import '../../../models/pedido.dart';

class TelaPedidosRecebidos extends StatefulWidget {
  final String mercadoId;

  const TelaPedidosRecebidos({super.key, required this.mercadoId});

  @override
  State<TelaPedidosRecebidos> createState() => _TelaPedidosRecebidosState();
}

class _TelaPedidosRecebidosState extends State<TelaPedidosRecebidos> {
  StatusPedido? _filtroSelecionado;

  @override
  Widget build(BuildContext context) {
    final lojistaProvider = context.watch<LojistaProvider>();
    final cores = Theme.of(context).colorScheme;

    // Lógica de Filtragem Reativa
    final pedidosFiltrados = lojistaProvider.pedidosAtivos.where((p) {
      if (p.status == StatusPedido.entregue) return false;
      if (_filtroSelecionado != null) return p.status == _filtroSelecionado;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("PAINEL DE EXPEDIÇÃO",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
        backgroundColor: cores.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [_buildStatusBadge(lojistaProvider)],
      ),
      body: Column(
        children: [
          _buildSuperBarraInformativa(lojistaProvider, cores),
          Expanded(
            child: pedidosFiltrados.isEmpty
                ? _buildEmptyState(_filtroSelecionado != null)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12), // Removi o padding horizontal
                    itemCount: pedidosFiltrados.length,
                    itemBuilder: (context, index) {
                      // Agora o card ocupa 100% da largura do Expanded
                      return CardPedidoLojista(
                          pedido: pedidosFiltrados[index],
                          mercadoId: widget.mercadoId);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperBarraInformativa(
      LojistaProvider provider, ColorScheme cores) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // 1. ESQUERDA: RELÓGIO DIGITAL
          const RelogioDigital(),

          const Spacer(),

          // 2. MEIO: FILTROS ESTILO SEGMENTED CONTROL
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _itemFiltroMini(
                    "Todos", null, Icons.grid_view_rounded, cores.secondary),
                _itemFiltroMini("Pendentes", StatusPedido.pendente, Icons.bolt,
                    Colors.blue),
                _itemFiltroMini("Preparando", StatusPedido.preparando,
                    Icons.timer_outlined, Colors.orange),
                _itemFiltroMini("Prontos", StatusPedido.pronto, Icons.check_box,
                    Colors.green),
              ],
            ),
          ),

          const Spacer(),

          // 3. DIREITA: ALERTAS INTUITIVOS
          _cardAlerta(
            label: "PEDIDOS HOJE",
            valor: "${provider.pedidosAtivos.length}",
            cor: Colors.blueGrey[800]!,
            icone: Icons.assessment_outlined,
          ),
          const SizedBox(width: 12),
          _cardAlerta(
            label: "PENDENTES",
            valor: "${provider.totalPendentes}",
            cor: provider.totalPendentes > 0
                ? Colors.redAccent
                : Colors.grey[400]!,
            icone: Icons.notification_important,
            isAlerta: provider.totalPendentes > 0,
          ),
        ],
      ),
    );
  }

  Widget _itemFiltroMini(
      String label, StatusPedido? status, IconData icone, Color cor) {
    final selecionado = _filtroSelecionado == status;
    return GestureDetector(
      onTap: () => setState(() => _filtroSelecionado = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: selecionado
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icone,
                size: 16, color: selecionado ? cor : Colors.blueGrey[300]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
                color: selecionado ? Colors.black87 : Colors.blueGrey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardAlerta({
    required String label,
    required String valor,
    required Color cor,
    required IconData icone,
    bool isAlerta = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isAlerta ? cor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlerta ? cor : Colors.black12,
          width: isAlerta ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isAlerta ? cor : Colors.blueGrey,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isAlerta ? cor : Colors.black87,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(LojistaProvider provider) {
    final aberto = provider.mercado!.estaAberto;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: aberto
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: aberto ? Colors.greenAccent : Colors.redAccent, width: 1.5),
      ),
      child: Center(
        child: Text(
          aberto ? "LOJA ONLINE" : "LOJA OFFLINE",
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool comFiltro) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_motion, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 20),
          Text(
              comFiltro ? "Nenhum pedido neste filtro" : "Tudo limpo por aqui!",
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
