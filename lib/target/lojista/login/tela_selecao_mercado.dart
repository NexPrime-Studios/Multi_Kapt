import 'package:flutter/material.dart';
import '../../../services/lojista_service.dart';
import '../../../models/funcionario.dart';
import '../../lojista/login/widgets/card_mercado_vinculo.dart';
import 'tela_cadastro_mercado.dart';
import '../pages/tela_homepage_lojista.dart';

class TelaSelecaoMercado extends StatefulWidget {
  const TelaSelecaoMercado({super.key});

  @override
  State<TelaSelecaoMercado> createState() => _TelaSelecaoMercadoState();
}

class _TelaSelecaoMercadoState extends State<TelaSelecaoMercado> {
  final LojistaService _lojistaService = LojistaService();

  bool _carregando = true;
  List<Map<String, dynamic>> _vinculos = [];

  @override
  void initState() {
    super.initState();
    _carregarMercadosVinculados();
  }

  CargoAcesso _converterStringParaCargo(String? cargo) {
    if (cargo == null) return CargoAcesso.coletorEntregador;

    switch (cargo.toLowerCase()) {
      case 'dono':
        return CargoAcesso.dono;
      case 'gerente':
        return CargoAcesso.gerente;
      default:
        return CargoAcesso.coletorEntregador;
    }
  }

  Future<void> _carregarMercadosVinculados() async {
    setState(() => _carregando = true);

    try {
      // Busca os mercados vinculados ao email do utilizador atual
      final resultados = await _lojistaService.buscarMercadosPorEmail();

      if (mounted) {
        setState(() {
          _vinculos = resultados;
          _carregando = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar vínculos: $e");
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cores.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: cores.onPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            child: FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CadastroMercadoPage()),
                );
                _carregarMercadosVinculados();
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text("Novo Mercado"),
              style: FilledButton.styleFrom(
                backgroundColor: cores.onPrimary.withOpacity(0.15),
                foregroundColor: cores.onPrimary,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarMercadosVinculados,
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_rounded,
                    size: 80, color: cores.onPrimary),
                const SizedBox(height: 24),
                Text(
                  "Acessar Unidade",
                  style: TextStyle(
                    color: cores.onPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                if (_carregando)
                  CircularProgressIndicator(color: cores.onPrimary)
                else if (_vinculos.isEmpty)
                  _buildAvisoVazio(cores)
                else
                  _buildVisualLista(cores),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualLista(ColorScheme cores) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: _vinculos.map((item) {
          // Extração segura dos dados aninhados
          final mercadoMap = item['mercados'] as Map?;
          final nomeMercado = mercadoMap?['nome']?.toString() ?? 'Mercado';
          final mercadoId = item['mercado_id']?.toString() ?? '';

          // Conversão da String para o Enum exigido pelo CardMercadoVinculo
          final cargoEnum =
              _converterStringParaCargo(item['funcao']?.toString());

          return CardMercadoVinculo(
            nomeMercado: nomeMercado,
            cargo: cargoEnum, // Agora passa o tipo correto (CargoAcesso)
            onTap: () {
              if (mercadoId.isNotEmpty) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HomePageLojista()),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvisoVazio(ColorScheme cores) {
    return Column(
      children: [
        Icon(Icons.info_outline_rounded,
            size: 60, color: cores.onPrimary.withOpacity(0.6)),
        const SizedBox(height: 16),
        Text(
          "Nenhum mercado vinculado ao seu e-mail.",
          style: TextStyle(color: cores.onPrimary, fontSize: 16),
        ),
      ],
    );
  }
}
