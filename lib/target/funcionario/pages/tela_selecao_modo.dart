import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/funcionario/funcionario_provider.dart';
import 'main_navigation_funcionario.dart';
import '../../cliente/pages/main_navigation.dart';

class SelecaoModoPage extends StatelessWidget {
  const SelecaoModoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Acessamos as cores do tema definido em app_theme.dart
    final cores = Theme.of(context).colorScheme;
    final funcProv = context.read<FuncionarioProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cores.primary, const Color(0xFF0D0D0D)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined,
                size: 80, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              "Bem-vindo de volta!",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Como deseja acessar o app hoje?",
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Botão Modo Funcionário (Trabalho)
            _buildCardOpcao(
              context: context,
              titulo: "MODO TRABALHO",
              subtitulo: "Gerenciar pedidos e estoque",
              icone: Icons.assignment_ind_rounded,
              cor: cores.secondary, // Azul neon do tema
              onTap: () {
                // Notifica o provider que o usuário entrou no modo trabalho
                funcProv.entrarNoModo();

                // O PlatformSelector no main.dart reagirá à mudança
                // mas usamos o replacement para limpar a pilha de navegação atual
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MainNavigationFuncionario()));
              },
            ),

            const SizedBox(height: 20),

            // Botão Modo Cliente
            _buildCardOpcao(
              context: context,
              titulo: "MODO CLIENTE",
              subtitulo: "Fazer compras nos mercados",
              icone: Icons.shopping_bag_outlined,
              cor: Colors.white,
              onTap: () {
                // Ao entrar como cliente, mantemos o mostrarSelecao como true
                // para que, se ele fechar e abrir o app, volte para esta tela
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MainNavigationCliente()));
              },
            ),

            const SizedBox(height: 40),

            // Opção para desvincular totalmente (útil caso outro funcionário vá usar o celular)
            TextButton(
              onPressed: () => _confirmarDesvinculo(context, funcProv),
              child: const Text(
                "DESVINCULAR CONTA",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarDesvinculo(
      BuildContext context, FuncionarioProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remover Vínculo?"),
        content: const Text(
            "Isso removerá seu acesso de funcionário deste aparelho. Você precisará ler o QR Code novamente."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR")),
          TextButton(
              onPressed: () {
                provider.desvincular(); // Limpa SharedPreferences
                Navigator.pop(context);
              },
              child:
                  const Text("REMOVER", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildCardOpcao({
    required BuildContext context,
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cor.withOpacity(0.5), width: 2),
        ),
        child: Row(
          children: [
            Icon(icone, color: cor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(
                          color: cor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(subtitulo,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cor),
          ],
        ),
      ),
    );
  }
}
