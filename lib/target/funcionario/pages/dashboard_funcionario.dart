import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_theme.dart';
import '../../../services/funcionario_provider.dart';
import '../../../services/funcionario_service.dart';
import '../../../models/mercado.dart';

class DashboardPageFuncionario extends StatefulWidget {
  const DashboardPageFuncionario({super.key});

  @override
  State<DashboardPageFuncionario> createState() =>
      _DashboardPageFuncionarioState();
}

class _DashboardPageFuncionarioState extends State<DashboardPageFuncionario> {
  bool _mostrarSenha = false;

  // Agora buscamos apenas o Mercado, pois o Funcionário já vem do Provider
  Future<Mercado?>? _dadosMercado;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final funcProv = context.read<FuncionarioProvider>();
    // Inicializa a busca do mercado apenas uma vez
    _dadosMercado ??=
        FuncionarioService().buscarMercadoVinculado(funcProv.mercadoId ?? '');
  }

  void _confirmarSaida(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Trocar de Modo"),
        content: const Text("Deseja voltar para a tela de seleção de modo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<FuncionarioProvider>().irParaSelecao();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text("TROCAR",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escutamos o Provider em tempo real
    final funcProv = context.watch<FuncionarioProvider>();

    // Se o Provider ainda estiver baixando o código_id ou dados do funcionário
    if (funcProv.codigoFuncionario == null) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text("Painel do Funcionário",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.secondaryColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _confirmarSaida(context),
          ),
        ],
      ),
      body: FutureBuilder<Mercado?>(
        future: _dadosMercado,
        builder: (context, snapshot) {
          // Note que não travamos a tela se o mercado demorar, usamos dados do Provider
          final mercado = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Saudação (Dados vêm do Provider via getter ou service se preferir manter o objeto)
                // Como você quer o código senha e ele já está no funcProv:
                const Text(
                  "Painel de Controle",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),

                // 2. Info Mercado e ID
                Row(
                  children: [
                    Icon(Icons.storefront, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      mercado?.nome ?? 'Carregando unidade...',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.badge_outlined,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "ID: ${funcProv.funcionarioId?.substring(0, 8)}",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 3. Métricas Reais do Provider
                Row(
                  children: [
                    _buildCardMetrica(
                        "Pedidos Disponíveis",
                        "${funcProv.quantidadePedidosAtivos}",
                        Icons.list_alt,
                        AppTheme.secondaryColor),
                    const SizedBox(width: 15),
                    _buildCardMetrica(
                        "Status",
                        funcProv.estaOcupado ? "Ocupado" : "Livre",
                        Icons.circle,
                        funcProv.estaOcupado ? Colors.orange : Colors.green),
                  ],
                ),

                const SizedBox(height: 25),

                // 4. Card do Código Senha (PEGANDO DO PROVIDER)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_open_rounded,
                          color: AppTheme.primaryColor),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Seu Código de Identificação",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(
                              _mostrarSenha
                                  ? funcProv.codigoFuncionario ?? "---"
                                  : "••••••••",
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _mostrarSenha = !_mostrarSenha),
                        icon: Icon(
                          _mostrarSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 5. Botão Desvincular
                _buildBotaoSair(context, funcProv),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardMetrica(
      String titulo, String valor, IconData icone, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor, size: 28),
            const SizedBox(height: 12),
            Text(valor,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(titulo,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoSair(BuildContext context, FuncionarioProvider prov) {
    return InkWell(
      onTap: () => _confirmarDesvinculo(context, prov),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_accounts_rounded, color: Colors.redAccent, size: 20),
            SizedBox(width: 10),
            Text("DESVINCULAR CONTA",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _confirmarDesvinculo(BuildContext context, FuncionarioProvider prov) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Desvincular conta?"),
        content: const Text(
            "Você terá que escanear o QR Code novamente para acessar."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await prov.desvincular();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text("SAIR",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
