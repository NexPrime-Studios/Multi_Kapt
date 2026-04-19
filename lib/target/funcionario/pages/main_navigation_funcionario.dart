// lib/target/funcionario/pages/main_navigation_funcionario.dart

import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../widgets/bottom_bar_widget.dart';
import 'dashboard_funcionario.dart';
import 'pedidos_funcionario_page.dart';
import 'coleta_pedido_page.dart';
import 'entregas_page.dart';
// Verifique se o caminho do import da página de itens está correto abaixo:
// import 'itens_mercado_page.dart';

class MainNavigationFuncionario extends StatefulWidget {
  const MainNavigationFuncionario({super.key});

  @override
  State<MainNavigationFuncionario> createState() =>
      _MainNavigationFuncionarioState();
}

class _MainNavigationFuncionarioState extends State<MainNavigationFuncionario> {
  int _abaSelecionada = 0;

  // Método para mudar a aba e garantir a atualização da UI
  void _mudarAba(int index) {
    setState(() {
      _abaSelecionada = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // A ordem aqui DEVE ser a mesma da BottomBarFuncionario
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
      const Center(child: Text("Página de Itens")),
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
