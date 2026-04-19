import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/cliente_service.dart';
import '../../../services/cliente_provider.dart';
import '../../../models/mercado.dart';
import '../widgets/card_mercado_pesquisa.dart';
import '../widgets/search_bar_widget.dart';

class PesquisaPage extends StatefulWidget {
  const PesquisaPage({super.key});

  @override
  State<PesquisaPage> createState() => _PesquisaPageState();
}

class _PesquisaPageState extends State<PesquisaPage> {
  final ClienteService _service = ClienteService();
  final TextEditingController _searchController = TextEditingController();
  String _termo = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c');
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final p = context.read<ClienteProvider>();
    final cidade = p.cliente?.cidade ?? "Edéia";
    final estado = p.cliente?.estado ?? "GO";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchBarWidget(
                controller: _searchController,
                onChanged: (val) {
                  setState(() => _termo = val);
                },
              ),
            ),
            Expanded(
              child: _termo.isEmpty
                  ? _buildEmptyState(cores)
                  : _buildResultadosBusca(cores, cidade, estado),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadosBusca(
      ColorScheme cores, String cidade, String estado) {
    return StreamBuilder<List<Mercado>>(
      stream: _service.buscarMercadosPorLocalizacao(
        cidade: cidade,
        estado: estado,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: cores.secondary));
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Erro ao carregar mercados."));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text("Nenhum mercado disponível em $cidade-$estado."));
        }

        final termoNormalizado = _normalizar(_termo);

        final mercados = snapshot.data!.where((m) {
          return _normalizar(m.nome).contains(termoNormalizado);
        }).toList();

        if (mercados.isEmpty) return _buildNoResults();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: mercados.length,
          itemBuilder: (context, index) => CardMercadoPesquisa(
            mercado: mercados[index],
          ),
        );
      },
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text(
            "Nenhum mercado encontrado.",
            style:
                TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cores) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.storefront,
                size: 80, color: cores.primary.withOpacity(0.2)),
          ),
          const SizedBox(height: 16),
          const Text(
            "O que você procura hoje?",
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const Text(
            "Digite o nome de um mercado acima",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
