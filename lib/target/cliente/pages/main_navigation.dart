import 'package:flutter/material.dart';
import 'tela_home_page.dart';
import '../widgets/bottom_bar_cliente.dart';
import 'tela_pesquisa.dart';
import 'tela_carrinho.dart';
import 'tela_historico_pedidos.dart';
import 'tela_perfil.dart';

class MainNavigationCliente extends StatefulWidget {
  const MainNavigationCliente({super.key});

  @override
  State<MainNavigationCliente> createState() => _MainNavigationClienteState();
}

class _MainNavigationClienteState extends State<MainNavigationCliente> {
  int _indiceAtual = 0;

  void _aoMudarDeAba(int index) {
    setState(() {
      _indiceAtual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> paginas = [
      HomePageCliente(aoClicarNaBusca: () => _aoMudarDeAba(1)),
      const PesquisaPage(),
      CarrinhoPage(onPedidoFinalizado: () => _aoMudarDeAba(3)),
      const HistoricoPedidosCliente(),
      const PerfilPageCliente(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _indiceAtual,
        children: paginas,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomBarCliente(
        indiceAtual: _indiceAtual,
        aoMudarDeAba: _aoMudarDeAba,
      ),
    );
  }
}
