import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Imports de navegação e modelos
import '../../shared/pages/mapa_selecao_page.dart';
import '../../cliente/pages/main_navigation.dart';
import '../../lojista/login/tela_selecao_mercado.dart';
import '../../../models/usuario.dart';
import '../../../services/usuario_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/usuario_service.dart';

// Componentes de UI
import '../widgets/campo_texto_widget.dart';
import '../widgets/campo_cpf_widget.dart';
import '../widgets/campo_telefone_widget.dart';

class CadastroUsuario extends StatefulWidget {
  const CadastroUsuario({super.key});

  @override
  State<CadastroUsuario> createState() => _CadastroUsuarioState();
}

class _CadastroUsuarioState extends State<CadastroUsuario> {
  final _authService = AuthService();
  final _usuarioService = UsuarioService();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();

  double? _lat;
  double? _lng;

  Future<void> _realizarCadastroCompleto() async {
    if (!_formKey.currentState!.validate()) return;

    if (_senhaController.text != _confirmarSenhaController.text) {
      _mostrarErro("As senhas não coincidem!");
      return;
    }
    if (_lat == null || _lng == null) {
      _mostrarErro("Por favor, marque sua localização no mapa!");
      return;
    }

    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim();

      final emailJaExiste = await _authService.verificarEmailExistente(email);

      if (emailJaExiste) {
        _mostrarErro("Este e-mail já está cadastrado. Faça LOGIN");
        setState(() => _loading = false);
        return;
      }

      // 2. CRIAÇÃO DA CONTA NO AUTH
      final response = await _authService.signUp(email, _senhaController.text);
      final userId = response.user?.id;

      if (userId != null) {
        final cpfLimpo = UtilBrasilFields.removeCaracteres(_cpfController.text);
        final novoUsuario = Usuario(
          uid: userId,
          nome: _nomeController.text.trim(),
          email: email,
          cpf: cpfLimpo,
          telefone: _telefoneController.text.trim(),
          endereco: _enderecoController.text.trim(),
          estado: "",
          cidade: "",
          latitude: _lat,
          longitude: _lng,
        );

        // 3. SALVAR DADOS COMPLEMENTARES
        await context
            .read<UsuarioProvider>()
            .salvarEAtualizarPerfil(novoUsuario);

        if (mounted) {
          _mostrarSucesso("Cadastro realizado com sucesso!");

          // 4. NAVEGAÇÃO CONDICIONAL: Mobile vs Web/PC
          Widget proximaTela = kIsWeb
              ? const TelaSelecaoMercado()
              : const MainNavigationCliente();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => proximaTela),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      _mostrarErro(e.message);
    } catch (e) {
      _mostrarErro("Erro ao realizar cadastro: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating),
    );
  }

  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cores.primary,
      appBar: AppBar(
        title: const Text("Cadastro"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 500), // Otimização PC/Web
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text("Criar sua Conta",
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 32),
                          _buildSecaoTitulo("Dados de Acesso"),
                          CampoTextoWidget(
                              label: "E-mail",
                              controller: _emailController,
                              type: TextInputType.emailAddress),
                          CampoTextoWidget(
                              label: "Senha",
                              controller: _senhaController,
                              obscure: true),
                          CampoTextoWidget(
                              label: "Confirmar Senha",
                              controller: _confirmarSenhaController,
                              obscure: true),
                          const SizedBox(height: 24),
                          _buildSecaoTitulo("Dados Pessoais"),
                          CampoTextoWidget(
                              label: "Nome Completo",
                              controller: _nomeController),
                          CampoCpfWidget(controller: _cpfController),
                          CampoTelefoneWidget(
                            controller: _telefoneController,
                            label: "WhatsApp",
                          ),
                          const SizedBox(height: 24),
                          _buildSecaoTitulo("Endereço"),
                          CampoTextoWidget(
                              label: "Endereço Completo",
                              controller: _enderecoController,
                              maxLines: 2),
                          const SizedBox(height: 10),
                          _buildBotaoMapa(),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _realizarCadastroCompleto,
                            child: const Text("FINALIZAR CADASTRO",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSecaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(titulo,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildBotaoMapa() {
    bool localizacaoOk = _lat != null && _lng != null;
    return InkWell(
      onTap: () async {
        final LatLng? res = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const TelaMapaSelecao(
                  posicaoInicial: LatLng(-23.55, -46.63))),
        );
        if (res != null) {
          setState(() {
            _lat = res.latitude;
            _lng = res.longitude;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: localizacaoOk
              ? Colors.green.withOpacity(0.05)
              : Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: localizacaoOk ? Colors.green : Colors.red),
        ),
        child: Row(
          children: [
            Icon(Icons.map_outlined,
                color: localizacaoOk ? Colors.green : Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizacaoOk
                    ? "Localização Marcada ✓"
                    : "Marcar Localização no Mapa *",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: localizacaoOk ? Colors.green : Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
