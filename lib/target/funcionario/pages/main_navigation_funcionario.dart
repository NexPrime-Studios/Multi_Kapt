// lib/target/funcionario/pages/main_navigation_funcionario.dart

import 'package:flutter/material.dart';
import 'package:mercado_app/target/funcionario/pages/tela_itens.dart';
import '../../../app_theme.dart';
import '../widgets/bottom_bar_widget.dart';
import 'tela_dashboard.dart';
import 'tela_pedidos_funcionario.dart';
import 'tela_coleta_pedido.dart';
import 'tela_entregas.dart';

class MainNavigationFuncionario extends StatefulWidget {
  const MainNavigationFuncionario({super.key});

  @override
  State<MainNavigationFuncionario> createState() =>
      _MainNavigationFuncionarioState();
}

class _MainNavigationFuncionarioState extends State<MainNavigationFuncionario> {
  int _abaSelecionada = 0;

  void _mudarAba(int index) {
    setState(() {
      _abaSelecionada = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> paginas = [
      const DashboardPageFuncionario(),
      PedidosFuncionarioPage(
        aoAceitarPedido: (statusAcao) {
          if (statusAcao == 'pendente') {
            _mudarAba(2);
          } else if (statusAcao == 'pronto') {
            _mudarAba(3);
          }
        },
      ),
      const ColetaPedidoPage(),
      const EntregasPage(),
      const TelaItensMercado(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: IndexedStack(
        index: _abaSelecionada,
        children: paginas,
      ),
      bottomNavigationBar: BottomBarFuncionario(
        indiceAtual: _abaSelecionada,
        aoMudarDeAba: _mudarAba,
      ),
    );
  }
}
