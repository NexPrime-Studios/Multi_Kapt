import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Imports de navegação e modelos
import '../../cliente/pages/main_navigation.dart';
import '../../lojista/login/tela_selecao_mercado.dart';
import '../../../models/usuario.dart';
import '../../../services/shared/usuario_provider.dart';
import '../../../services/shared/auth_service.dart';

// Componentes de UI
import '../global_widgets/botao_selecionar_localizacao_widget.dart';
import '../global_widgets/campo_cep_widget.dart';
import '../global_widgets/campo_senha_widget.dart';
import '../global_widgets/campo_texto_widget.dart';
import '../global_widgets/campo_cpf_widget.dart';
import '../global_widgets/campo_telefone_widget.dart';
import '../global_widgets/campo_data_nascimento_widget.dart';

class CadastroUsuario extends StatefulWidget {
  const CadastroUsuario({super.key});

  @override
  State<CadastroUsuario> createState() => _CadastroUsuarioState();
}

class _CadastroUsuarioState extends State<CadastroUsuario> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _semNumero = false; // Controle do "Sem Número"

  // Controllers Dados de Acesso e Pessoais
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _nascimentoController = TextEditingController();

  // Controllers para a classe Endereco
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _complementoController = TextEditingController();

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

      final response = await _authService.signUp(email, _senhaController.text);
      final userId = response.user?.id;

      if (userId != null) {
        final cpfLimpo = UtilBrasilFields.removeCaracteres(_cpfController.text);

        // Lógica para salvar "S/N" ou o número digitado
        final String numeroFinal =
            _semNumero ? "S/N" : _numeroController.text.trim();

        final novoEndereco = Endereco(
          cep: _cepController.text.trim(),
          rua: _ruaController.text.trim(),
          numero: numeroFinal,
          bairro: _bairroController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _estadoController.text.trim(),
          complemento: _complementoController.text.trim(),
        );

        final novoUsuario = Usuario(
          uid: userId,
          nome: _nomeController.text.trim(),
          email: email,
          cpf: cpfLimpo,
          telefone: _telefoneController.text.trim(),
          dataNascimento: _nascimentoController.text.trim(),
          endereco: novoEndereco,
          latitude: _lat,
          longitude: _lng,
        );

        await context
            .read<UsuarioProvider>()
            .salvarEAtualizarPerfil(novoUsuario);

        if (mounted) {
          _mostrarSucesso("Cadastro realizado com sucesso!");
          Widget proximaTela = kIsWeb
              ? const TelaSelecaoMercado()
              : const MainNavigationCliente();
          Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => proximaTela), (route) => false);
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
        SnackBar(content: Text(mensagem), backgroundColor: Colors.red));
  }

  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.green));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _nascimentoController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _complementoController.dispose();
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
          foregroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24)),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                              child: Text("Criar sua Conta",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(height: 32),
                          _buildSecaoTitulo("Dados de Acesso"),
                          CampoTextoWidget(
                              label: "E-mail",
                              controller: _emailController,
                              icon: Icons.email_outlined,
                              type: TextInputType.emailAddress),
                          CampoSenhaWidget(
                              label: "Senha", controller: _senhaController),
                          CampoSenhaWidget(
                              label: "Confirmar Senha",
                              controller: _confirmarSenhaController),
                          const SizedBox(height: 24),
                          _buildSecaoTitulo("Dados Pessoais"),
                          CampoTextoWidget(
                              label: "Nome Completo",
                              icon: Icons.person_outline,
                              controller: _nomeController),
                          CampoCpfWidget(controller: _cpfController),
                          CampoTelefoneWidget(
                              controller: _telefoneController,
                              label: "WhatsApp"),
                          CampoDataNascimentoWidget(
                              controller: _nascimentoController),
                          const SizedBox(height: 24),
                          _buildSecaoTitulo("Endereço"),
                          CampoCepWidget(controller: _cepController),
                          CampoTextoWidget(
                              label: "Estado",
                              controller: _estadoController,
                              icon: Icons.location_on_outlined),
                          CampoTextoWidget(
                              label: "Cidade",
                              controller: _cidadeController,
                              icon: Icons.location_city_sharp),
                          CampoTextoWidget(
                              label: "Rua/Logradouro",
                              controller: _ruaController,
                              icon: Icons.map_outlined),
                          CampoTextoWidget(
                              label: "Bairro",
                              controller: _bairroController,
                              icon: Icons.business_outlined),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CampoTextoWidget(
                                  label: "Número",
                                  controller: _numeroController,
                                  enabled: !_semNumero, // Desativa se for S/N
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                children: [
                                  const Text("Sem nº",
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                  Checkbox(
                                    value: _semNumero,
                                    onChanged: (val) {
                                      setState(() {
                                        _semNumero = val ?? false;
                                        if (_semNumero) {
                                          _numeroController.clear();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          CampoTextoWidget(
                              label: "Complemento (Opcional)",
                              controller: _complementoController,
                              icon: Icons.info_outline,
                              validator: (valor) => null),
                          const SizedBox(height: 10),
                          CampoSelecionarLocalizacaoWidget(
                            latitude: _lat,
                            longitude: _lng,
                            onLocationSelected: (LatLng posicao) {
                              setState(() {
                                _lat = posicao.latitude;
                                _lng = posicao.longitude;
                              });
                            },
                          ),
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
}
