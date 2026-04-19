import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'mapa_selecao_page.dart';
import '../../../models/cliente.dart';
import '../../../services/cliente_provider.dart';

class CadastroPageCliente extends StatefulWidget {
  const CadastroPageCliente({super.key});

  @override
  State<CadastroPageCliente> createState() => _CadastroPageClienteState();
}

class _CadastroPageClienteState extends State<CadastroPageCliente> {
  final _formKeyAuth = GlobalKey<FormState>();
  final _formKeyDados = GlobalKey<FormState>();

  int _passoAtual = 0; // 0: Auth, 1: Perfil
  bool _loading = false;

  // Controllers Passo 1
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // Controllers Passo 2
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();

  double? _lat;
  double? _lng;

  // 1. Criar a Conta (Auth)
  Future<void> _criarContaAuth() async {
    if (!_formKeyAuth.currentState!.validate()) return;
    if (_senhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("As senhas não coincidem!")));
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      if (response.user != null) {
        setState(() => _passoAtual = 1);
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } finally {
      setState(() => _loading = false);
    }
  }

  // 2. Salvar Perfil, atualizar Provider e Finalizar
  Future<void> _finalizarCadastro() async {
    if (!_formKeyDados.currentState!.validate()) return;

    if (_lat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Marque sua localização no mapa!")));
      return;
    }

    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;

    try {
      final novoCliente = Cliente(
        uid: user!.id,
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        telefone: _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim(),
        estado: "", // Valor vazio conforme solicitado
        cidade: "", // Valor vazio conforme solicitado
        latitude: _lat,
        longitude: _lng,
      );

      await Supabase.instance.client
          .from('clientes')
          .upsert(novoCliente.toMap());

      if (mounted) {
        context.read<ClienteProvider>().atualizarCliente(novoCliente);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Perfil criado com sucesso!"),
            backgroundColor: Colors.green));

        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Erro ao salvar perfil: $e"),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Text(_passoAtual == 0 ? "Criar Conta" : "Completar Perfil"),
          centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _passoAtual == 0 ? _buildFormAuth() : _buildFormPerfil(),
            ),
    );
  }

  Widget _buildFormAuth() {
    return Form(
      key: _formKeyAuth,
      child: Column(
        children: [
          TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "E-mail"),
              validator: (v) => v!.isEmpty ? "Obrigatório" : null),
          const SizedBox(height: 16),
          TextFormField(
              controller: _senhaController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Senha"),
              validator: (v) =>
                  (v?.length ?? 0) < 6 ? "Mínimo 6 caracteres" : null),
          const SizedBox(height: 16),
          TextFormField(
              controller: _confirmarSenhaController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirme a Senha"),
              validator: (v) =>
                  v != _senhaController.text ? "As senhas não conferem" : null),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _criarContaAuth,
            child: const Text("PRÓXIMO PASSO",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPerfil() {
    return Form(
      key: _formKeyDados,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Estamos quase lá! Preencha seus dados de entrega:",
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 24),
          TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: "Nome Completo"),
              validator: (v) => v!.isEmpty ? "Obrigatório" : null),
          const SizedBox(height: 16),
          TextFormField(
              controller: _telefoneController,
              decoration: const InputDecoration(labelText: "Telefone"),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? "Obrigatório" : null),
          const SizedBox(height: 16),
          TextFormField(
              controller: _enderecoController,
              decoration:
                  const InputDecoration(labelText: "Endereço por Extenso"),
              maxLines: 2,
              validator: (v) => v!.isEmpty ? "Obrigatório" : null),
          const SizedBox(height: 20),
          InkWell(
            onTap: () async {
              final LatLng? res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TelaMapaSelecao(
                          posicaoInicial: LatLng(-23.55, -46.63))));
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
                color: _lat != null
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _lat != null ? Colors.green : Colors.red),
              ),
              child: Row(
                children: [
                  Icon(Icons.map,
                      color: _lat != null ? Colors.green : Colors.red),
                  const SizedBox(width: 12),
                  Text(
                      _lat != null
                          ? "Localização Marcada ✓"
                          : "Toque para marcar no Mapa *",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _lat != null ? Colors.green : Colors.red)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 55)),
            onPressed: _finalizarCadastro,
            child: const Text("FINALIZAR E ENTRAR",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
