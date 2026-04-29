import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/pedido.dart';
import '../../../services/shared/usuario_service.dart';
import '../../../services/shared/user_provider.dart';
import '../widgets/card_pedido_cliente.dart';

class HistoricoPedidosCliente extends StatefulWidget {
  const HistoricoPedidosCliente({super.key});

  @override
  State<HistoricoPedidosCliente> createState() =>
      _HistoricoPedidosClienteState();
}

class _HistoricoPedidosClienteState extends State<HistoricoPedidosCliente> {
  Key _streamKey = UniqueKey();

  void _atualizarLista() {
    setState(() {
      _streamKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<UserProvider>();
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Meus Pedidos",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        // 1. Mudança para a cor secundária do tema
        backgroundColor: cores.secondary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        // 2. Botão de atualizar na direita
        actions: [
          IconButton(
            onPressed: _atualizarLista,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: "Atualizar pedidos",
          ),
        ],
      ),
      body: !p.temPerfil
          ? const Center(child: Text("Faça login para ver seu histórico."))
          : StreamBuilder<List<Pedido>>(
              key:
                  _streamKey, // Usamos a key aqui para o botão de atualizar funcionar
              stream: UsuarioService().acompanharMeusPedidos(p.usuario!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.red));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Erro ao carregar dados. Tente atualizar."),
                  );
                }

                final pedidos = snapshot.data ?? [];

                if (pedidos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("Você ainda não fez pedidos",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    return CardPedidoCliente(pedido: pedidos[index]);
                  },
                );
              },
            ),
    );
  }
}
