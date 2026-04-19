import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../services/funcionario_provider.dart';
import '../../../services/funcionario_service.dart';
import '../../../models/funcionario.dart';
import '../../../models/item_pedido.dart';

class EntregasPage extends StatefulWidget {
  const EntregasPage({super.key});

  @override
  State<EntregasPage> createState() => _EntregasPageState();
}

class _EntregasPageState extends State<EntregasPage> {
  final _service = FuncionarioService();
  Funcionario? _funcionarioLogado;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      final provider = context.read<FuncionarioProvider>();
      final dados =
          await _service.buscarDadosFuncionario(provider.funcionarioId ?? '');
      if (mounted) {
        setState(() {
          _funcionarioLogado = dados;
          _carregando = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar perfil: $e");
    }
  }

  String _formatarNumero(String? telefone) {
    if (telefone == null) return "";
    String apenasNumeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!apenasNumeros.startsWith('55') && apenasNumeros.length >= 10) {
      apenasNumeros = '55$apenasNumeros';
    }
    return apenasNumeros;
  }

  Future<void> _abrirWhatsApp(String? telefone) async {
    final numero = _formatarNumero(telefone);
    if (numero.isEmpty) return;
    final uri = Uri.parse("https://wa.me/$numero");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _fazerLigacao(String? telefone) async {
    final numero = _formatarNumero(telefone);
    if (numero.isEmpty) return;
    final uri = Uri.parse("tel:$numero");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _abrirMapa(double lat, double lng) async {
    final uri =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // NOVA FUNÇÃO: FINALIZAR E LIMPAR INTERFACE
  Future<void> _finalizarEntrega(Map<String, dynamic> pedido) async {
    if (_funcionarioLogado == null) return;

    // Diálogo de confirmação
    bool confirmar = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirmar Entrega"),
            content: const Text("Você confirma que o pedido foi entregue?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("NÃO")),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("SIM, ENTREGUE"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    setState(() => _carregando = true);

    try {
      await _service.atualizarStatusPedido(
        pedidoId: pedido['id']?.toString() ?? '',
        novoStatus: 'entregue',
        funcionarioNome: _funcionarioLogado!.nome,
        funcionarioCodigo: _funcionarioLogado!.codigoSenha,
      );

      if (mounted) {
        final provider = context.read<FuncionarioProvider>();
        provider.setPedidoAtual(null);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Entrega finalizada!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Erro ao finalizar: $e");
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final funcionarioProv = context.watch<FuncionarioProvider>();
    final pedidoAtual = funcionarioProv.pedidoEmEntrega;

    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Detalhes da Entrega",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: pedidoAtual == null
          ? _buildEmptyState()
          : SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCardCliente(pedidoAtual),
                    const SizedBox(height: 12),
                    _buildCardEndereco(pedidoAtual),
                    const SizedBox(height: 12),
                    _buildCardItens(pedidoAtual),
                    const SizedBox(height: 12),
                    _buildCardFinanceiro(pedidoAtual),
                    const SizedBox(height: 24),
                    _buildBotaoFinalizar(pedidoAtual),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCardCliente(Map<String, dynamic> pedido) {
    final String telefone = pedido['telefone_cliente'] ?? 'Sem telefone';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pedido['nome_cliente'] ?? 'Cliente',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text("CONTATO",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    telefone,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                ),
                _buildBotaoContato(
                  onPressed: () => _fazerLigacao(telefone),
                  icon: Icons.phone,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildBotaoContato(
                  onPressed: () => _abrirWhatsApp(telefone),
                  icon: FontAwesomeIcons.whatsapp,
                  color: const Color(0xFF25D366),
                ),
              ],
            ),
            const Divider(height: 32),
            Text("Mercado: ${pedido['nome_mercado'] ?? 'Loja'}",
                style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoContato(
      {required VoidCallback onPressed,
      required IconData icon,
      required Color color}) {
    return SizedBox(
      height: 35,
      width: 45,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: FaIcon(icon, size: 18),
      ),
    );
  }

  Widget _buildCardEndereco(Map<String, dynamic> pedido) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ENDEREÇO",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(pedido['endereco_entrega'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _abrirMapa(
                    pedido['latitude'] ?? 0, pedido['longitude'] ?? 0),
                icon: const Icon(Icons.map),
                label: const Text("ABRIR GPS"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItens(Map<String, dynamic> pedido) {
    final List itensRaw = pedido['itens'] as List? ?? [];
    final List<ItemPedido> itens =
        itensRaw.map((i) => ItemPedido.fromMap(i)).toList();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Text("${itens.length} Itens no Pedido"),
        children: itens
            .map((i) => ListTile(
                title: Text(i.nome),
                trailing: Text("${i.quantidade.toStringAsFixed(0)}x")))
            .toList(),
      ),
    );
  }

  Widget _buildCardFinanceiro(Map<String, dynamic> pedido) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("VALOR TOTAL:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text("R\$ ${pedido['total']?.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoFinalizar(Map<String, dynamic> pedido) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () => _finalizarEntrega(pedido),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        child: const Text("FINALIZAR ENTREGA",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("Nenhuma entrega ativa.",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
