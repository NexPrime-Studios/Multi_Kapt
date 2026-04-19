import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tela_selecao_mercado.dart';

class LoginLojistaPage extends StatefulWidget {
  const LoginLojistaPage({super.key});

  @override
  State<LoginLojistaPage> createState() => _LoginLojistaPageState();
}

class _LoginLojistaPageState extends State<LoginLojistaPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLogin = true;
  bool _carregando = false;

  Future<void> _autenticar() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _mostrarErro("Por favor, insira um e-mail válido.");
      return;
    }
    if (_senhaController.text.length < 6) {
      _mostrarErro("A senha deve ter pelo menos 6 caracteres.");
      return;
    }

    setState(() => _carregando = true);
    final supabase = Supabase.instance.client;

    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _senhaController.text.trim(),
        );
      } else {
        await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _senhaController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TelaSelecaoMercado()),
        );
      }
    } on AuthException catch (e) {
      String mensagem = e.message;
      if (mensagem.contains("Invalid login credentials")) {
        mensagem = "E-mail ou senha incorretos.";
      } else if (mensagem.contains("User already registered")) {
        mensagem = "Este e-mail já está em uso.";
      }
      _mostrarErro(mensagem);
    } catch (e) {
      _mostrarErro("Ocorreu um erro inesperado.");
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            Theme.of(context).colorScheme.error, // Usa cor de erro do tema
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Acessando as cores do esquema de cores definido no seu AppTheme
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cores.primary, // Fundo baseado no tema
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cores.surface, // Fundo do card
              borderRadius: BorderRadius.circular(
                  24), // Bordas mais arredondadas seguindo padrão moderno
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "MULTI KAPT",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cores.primary, // Cor principal do tema
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? "Painel Administrativo" : "Criar conta de gestor",
                  style: TextStyle(color: cores.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon:
                        Icon(Icons.email_outlined, color: cores.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock_outline, color: cores.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
                _carregando
                    ? CircularProgressIndicator(color: cores.primary)
                    : ElevatedButton(
                        onPressed: _autenticar,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor:
                              cores.secondary, // Botão com cor primária
                          foregroundColor: cores.onPrimary, // Texto do botão
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isLogin ? "ENTRAR" : "CADASTRAR CONTA",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? "Novo por aqui? Crie sua conta"
                        : "Já possui acesso? Faça login",
                    style: TextStyle(
                        color: cores.tertiary,
                        fontWeight: FontWeight.bold), // Cor secundária
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
