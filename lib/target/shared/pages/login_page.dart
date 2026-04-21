import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Services e Providers
import '../../../services/auth_service.dart';
import '../../../services/usuario_provider.dart';

// Páginas de destino
import 'cadastro_usuario_page.dart';
import '../../lojista/login/tela_selecao_mercado.dart';
import '../../cliente/pages/main_navigation.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? aoPular;
  const LoginPage({super.key, this.aoPular});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _loading = false;

  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final userProvider = context.read<UsuarioProvider>();

    if (email.isEmpty || !email.contains('@')) {
      _notificar("Por favor, insira um e-mail válido.");
      return;
    }
    if (senha.length < 6) {
      _notificar("A senha deve ter pelo menos 6 caracteres.");
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await _authService.signIn(email, senha);

      if (response.user != null && mounted) {
        final usuario = await _authService.getUsuarioData();

        if (usuario != null && mounted) {
          userProvider.atualizarUsuario(usuario);

          if (userProvider.isPC) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const TelaSelecaoMercado()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationCliente()),
              (route) => false,
            );
          }
        } else {
          _notificar("Perfil não encontrado.");
        }
      }
    } on AuthException catch (e) {
      _notificar("Erro: ${e.message}");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notificar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating, // Melhor aparência no PC
        width: context.read<UsuarioProvider>().isPC ? 400 : null,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final isPC = context.watch<UsuarioProvider>().isPC;

    return Scaffold(
      backgroundColor: isPC ? cores.primary : Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: isPC ? 450 : double.infinity,
            padding: EdgeInsets.all(isPC ? 40 : 24),
            decoration: isPC
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 10))
                    ],
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/iconb.png',
                  height: isPC ? 120 : 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.shopping_bag,
                        size: 64, color: cores.primary);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  "MULTI KAPT",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "E-mail",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                _loading
                    ? CircularProgressIndicator(color: cores.secondary)
                    : ElevatedButton(
                        onPressed: _fazerLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cores.secondary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("ENTRAR",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CadastroUsuario()),
                  ),
                  child: Text("Não tem conta? Cadastre-se aqui",
                      style: TextStyle(color: cores.primary)),
                ),
                // Botão "Pular" aparece apenas no Mobile para clientes
                if (widget.aoPular != null && !isPC) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: widget.aoPular,
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                    child: const Text("ENTRAR SEM LOGIN",
                        style: TextStyle(color: Colors.black87)),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
