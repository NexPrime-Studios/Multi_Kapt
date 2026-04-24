import 'package:flutter/material.dart';
import 'package:mercado_app/target/shared/pages/login_page.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/sidebar_lojista.dart';
import '../../../services/lojista/lojista_provider.dart';
import 'tela_pedidos_recebidos.dart';
import 'tela_perfil_mercado.dart';
import 'tela_inventario_mercado.dart';
import 'tela_historico_pedidos.dart';
import 'tela_metricas.dart';
import '../login/tela_selecao_mercado.dart';
import 'tela_equipe.dart';
import 'tela_promocoes.dart';

class HomePageLojista extends StatefulWidget {
  const HomePageLojista({super.key});

  @override
  State<HomePageLojista> createState() => _HomePageLojistaState();
}

class _HomePageLojistaState extends State<HomePageLojista> {
  int _indiceSelecionado = 0;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Inicia a verificação de sessão após o primeiro frame para evitar erros de BuildContext
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarSessao();
    });
  }

  void _verificarSessao() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      // Redireciona para login caso não haja usuário autenticado
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      // Inicializa o provider com os dados do administrador logado
      context.read<LojistaProvider>().inicializar(user.id);
    }
  }

  Widget _getConteudo(LojistaProvider provider) {
    // Como estaCarregando e mercado == null são tratados no build,
    // aqui o mercado já é garantido como não nulo.
    final mercado = provider.mercado!;

    switch (_indiceSelecionado) {
      case 0:
        return TelaPedidosRecebidos(mercadoId: mercado.id);
      case 1:
        return TelaPerfilMercado(mercado: mercado);
      case 2:
        // Tela de métricas agora centralizada
        return const TelaMetricas();
      case 3:
        return const TelaInventarioMercado();
      case 4:
        return TelaHistoricoPedidos(mercadoId: mercado.id);
      case 5:
        return TelaEquipeLojista(mercadoId: mercado.id);
      case 6:
        return TelaPromocoes(mercadoId: mercado.id);
      default:
        return TelaPedidosRecebidos(mercadoId: mercado.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LojistaProvider>();

    // 1. Estado de carregamento inicial
    if (provider.estaCarregando) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Se o carregamento terminou e não há mercado, exige cadastro
    if (provider.mercado == null) {
      return const TelaSelecaoMercado();
    }

    // 3. Layout principal do Dashboard
    return Scaffold(
      body: Row(
        children: [
          // Sidebar fixo na esquerda
          SidebarLojista(
            indiceSelecionado: _indiceSelecionado,
            aoSelecionar: (index) => setState(() => _indiceSelecionado = index),
          ),
          // Conteúdo dinâmico na direita
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: _getConteudo(provider),
            ),
          ),
        ],
      ),
    );
  }
}
