import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_theme.dart';
import '../../../models/funcionario.dart';
import '../../../services/funcionario/funcionario_provider.dart';
import '../../../services/shared/mercado_shared_provider.dart';

class DashboardPageFuncionario extends StatefulWidget {
  const DashboardPageFuncionario({super.key});

  @override
  State<DashboardPageFuncionario> createState() =>
      _DashboardPageFuncionarioState();
}

class _DashboardPageFuncionarioState extends State<DashboardPageFuncionario> {
  bool _mostrarSenha = false;

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
    final funcProv = context.watch<FuncionarioProvider>();
    final mercadoShared = context.watch<MercadoSharedProvider>();

    final mercado = mercadoShared.mercado;
    final funcionario = funcProv.funcionario;

    if (funcProv.codigoFuncionario == null || mercado == null) {
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
        // Alterado para Primary Color conforme solicitado
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        elevation: 0,
        // Botão removido da AppBar conforme solicitado
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabeçalho
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: mercado.logoUrl != "" && mercado.logoUrl.isNotEmpty
                        ? Image.network(mercado.logoUrl, fit: BoxFit.cover)
                        : const Icon(Icons.storefront,
                            color: AppTheme.secondaryColor),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mercado.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        funcionario?.cargo.label.toUpperCase() ?? "FUNCIONÁRIO",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.secondaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // 3. Métricas
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

            // 4. Card do Código Senha
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
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                      _mostrarSenha ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Botão Trocar Modo (Movido para cá e estilizado)
            _buildBotaoTrocarModo(context),

            const SizedBox(height: 15),

            // 5. Botão Desvincular
            _buildBotaoDesvincular(context, funcProv),
          ],
        ),
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

  Widget _buildBotaoTrocarModo(BuildContext context) {
    return InkWell(
      onTap: () => _confirmarSaida(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded,
                color: AppTheme.primaryColor, size: 20),
            SizedBox(width: 10),
            Text("TROCAR PARA MODO CLIENTE",
                style: TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoDesvincular(
      BuildContext context, FuncionarioProvider prov) {
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
            Text("RETIRAR CONTA FUNCIONARIO",
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
