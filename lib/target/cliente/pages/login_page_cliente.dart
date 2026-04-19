import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; //
import 'cadastro_page_cliente.dart';
import '../../../models/cliente.dart'; //
import '../../../services/cliente_provider.dart'; //

class LoginPageCliente extends StatefulWidget {
  final VoidCallback? aoPular;
  const LoginPageCliente({super.key, this.aoPular});

  @override
  State<LoginPageCliente> createState() => _LoginPageClienteState();
}

class _LoginPageClienteState extends State<LoginPageCliente> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _loading = false;

  void _mostrarErroPopup(String mensagem) {
    final cores = Theme.of(context).colorScheme;
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: cores.error),
            const SizedBox(width: 10),
            const Text("Ops!"),
          ],
        ),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ENTENDI",
                style: TextStyle(
                    color: cores.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _fazerLogin() async {
    if (_emailController.text.isEmpty || _senhaController.text.isEmpty) {
      _mostrarErroPopup("Preencha o e-mail e a senha para entrar.");
      return;
    }

    setState(() => _loading = true);
    try {
      // 1. Realiza a autenticação
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      if (response.user != null && mounted) {
        // 2. Busca os dados do perfil na tabela 'clientes' imediatamente após o login
        final dados = await Supabase.instance.client
            .from('clientes')
            .select()
            .eq('uid', response.user!.id)
            .single();

        // 3. Converte para o modelo e alimenta o Provider
        final cliente = Cliente.fromMap(dados);
        if (mounted) {
          context.read<ClienteProvider>().atualizarCliente(cliente);
        }

        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
    } on AuthException catch (e) {
      _mostrarErroPopup(e.message);
    } catch (e) {
      _mostrarErroPopup("Erro ao buscar dados do perfil. Tente novamente.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.shopping_bag, size: 80, color: cores.primary),
              const SizedBox(height: 16),
              const Text("Bem-vindo!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: "E-mail", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Senha", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              _loading
                  ? CircularProgressIndicator(color: cores.secondary)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cores.secondary,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _fazerLogin,
                      child: const Text("ENTRAR",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CadastroPageCliente())),
                child: Text("Não tem conta? Cadastre-se aqui",
                    style: TextStyle(color: cores.primary)),
              ),
              if (widget.aoPular != null) ...[
                const SizedBox(height: 20),
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
    );
  }
}
