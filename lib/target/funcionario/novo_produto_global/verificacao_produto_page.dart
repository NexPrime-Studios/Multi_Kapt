import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/produto.dart';
import '../../../models/produto_enums.dart'; // Importante para o TipoProduto
import '../../../services/shared/mercado_shared_provider.dart';
import '../../shared/gerenciar_produtos/cadastrar_produto_global/novo_produto_page.dart';
import '../../shared/global_widgets/campo_texto_widget.dart';
import 'scanner_codigo_barras.dart';

class VerificacaoProdutoPage extends StatefulWidget {
  const VerificacaoProdutoPage({super.key});

  @override
  State<VerificacaoProdutoPage> createState() => _VerificacaoProdutoPageState();
}

class _VerificacaoProdutoPageState extends State<VerificacaoProdutoPage> {
  final _codigoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _mercadorSharedProvider = MercadoSharedProvider();

  String? _codigoSalvo;

  // --- Lógica de Verificação de Tipo de Produto ---
  TipoProduto _identificarTipoPeloCodigo(String codigo) {
    // Se começa com '2', é item de balança (Pesável)
    if (codigo.startsWith('2')) return TipoProduto.pesavel;
    // Se for muito curto, consideramos produção interna/serviço
    if (codigo.length < 8) return TipoProduto.interno;
    // Caso contrário, segue o fluxo industrial global
    return TipoProduto.industrial;
  }

  Future<void> _abrirScanner() async {
    final String? codigoCapturado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerCodigoDeBarrasPage()),
    );

    if (codigoCapturado != null && codigoCapturado.isNotEmpty) {
      _codigoController.text = codigoCapturado;
      _processarCodigoManual(); // Processa automaticamente após o scan
    }
  }

  Future<void> _processarCodigoManual() async {
    if (_formKey.currentState!.validate()) {
      final codigoDigitado = _codigoController.text.trim();
      final tipoIdentificado = _identificarTipoPeloCodigo(codigoDigitado);

      try {
        // Só buscamos no banco global se for tipo Industrial
        if (tipoIdentificado == TipoProduto.industrial) {
          final Produto? produtoExistente =
              await _mercadorSharedProvider.buscarProdutoGlobal(codigoDigitado);

          if (!mounted) return;

          if (produtoExistente != null) {
            _codigoController.clear();
            _mostrarAvisoProdutoExistente(
                codigoDigitado, produtoExistente.nome);
            return;
          }
        }

        // Se o produto não existe ou é local/peso, avança para o cadastro
        if (!mounted) return;
        _irParaCadastro(codigoDigitado, tipoIdentificado);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _irParaCadastro(String codigo, TipoProduto tipo) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NovoProdutoPage(
          codigoBarrasInicial: codigo,
          tipoDefinido: tipo, // Passa o tipo identificado ou escolhido
        ),
      ),
    );

    if (resultado == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Verificar Produto"),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- CARD PRINCIPAL (SCANNER E CÓDIGO) ---
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded,
                          size: 50, color: cores.primary),
                      const SizedBox(height: 16),
                      const Text(
                        "Identificação Rápida",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Use o scanner ou digite o código de barras para verificar se o produto já existe.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _abrirScanner,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(color: cores.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text("ESCANEAR AGORA"),
                      ),
                      const SizedBox(height: 16),
                      CampoTextoWidget(
                        label: "Código de Barras",
                        controller: _codigoController,
                        icon: Icons.edit_note,
                        type: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Digite o código" : null,
                      ),
                      ElevatedButton(
                        onPressed: _processarCodigoManual,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("VERIFICAR CÓDIGO"),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            _buildDivisor("OU CADASTRO MANUAL"),
            const SizedBox(height: 24),

            // --- CARDS INFERIORES SEPARADOS ---
            _buildCardManual(
              titulo: "Novo Item por Peso",
              descricao:
                  "Para itens de balança (Hortifruti, Açougue, Padaria).",
              icon: Icons.scale_rounded,
              cor: Colors.teal,
              onTap: () => _irParaCadastro("", TipoProduto.pesavel),
            ),
            const SizedBox(height: 16),
            _buildCardManual(
              titulo: "Produção Interna",
              descricao: "Itens fabricados no mercado com preço fixo.",
              icon: Icons.restaurant_menu_rounded,
              cor: Colors.deepPurple,
              onTap: () => _irParaCadastro("", TipoProduto.interno),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCardManual({
    required String titulo,
    required String descricao,
    required IconData icon,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: cor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: cor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(descricao,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: cor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivisor(String texto) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(texto,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }

  // Mantenha sua função _mostrarAvisoProdutoExistente igual...
  void _mostrarAvisoProdutoExistente(String codigo, String nomeProduto) {
    // ... (mesmo código do seu script original)
  }
}
