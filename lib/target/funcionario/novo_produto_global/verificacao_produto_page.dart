import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/produto.dart';
import '../../../services/shared/mercado_shared_provider.dart';
import '../../shared/global_widgets/campo_texto_widget.dart';
import 'scanner_codigo_barras.dart';
import 'tela_novo_produto.dart';

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

  Future<void> _abrirScanner() async {
    // 1. Navega para a página de scanner e aguarda o resultado
    final String? codigoCapturado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerCodigoDeBarrasPage()),
    );

    // 2. Verifica se algo foi retornado
    if (codigoCapturado != null && codigoCapturado.isNotEmpty) {
      setState(() {
        _codigoController.text = codigoCapturado; // Coloca no campo de texto
        _codigoSalvo = codigoCapturado; // Salva na variável
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Código $codigoCapturado lido com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );

      // Opcional: Chamar a função de salvar/processar automaticamente após ler
      // _processarCodigoManual();
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 60, color: cores.primary),
                    const SizedBox(height: 16),
                    const Text(
                      "Identificação do Produto",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    // DESCRIÇÃO SOLICITADA
                    const Text(
                      "Para cadastrar um produto, use o código de barras, coloque manualmente ou leia pelo scanner da camera",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- SEÇÃO SCANNER ---
                    OutlinedButton.icon(
                      onPressed: _abrirScanner,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        side: BorderSide(color: cores.primary, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text(
                        "USAR SCANNER DE CÂMERA",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("OU",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // --- SEÇÃO MANUAL ---
                    CampoTextoWidget(
                      label: "Código de Barras",
                      controller: _codigoController,
                      icon: Icons.edit_note,
                      type: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Digite o código" : null,
                    ),

                    ElevatedButton.icon(
                      onPressed: _processarCodigoManual,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cores.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("VERIFICAR / AVANÇAR",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),

                    if (_codigoSalvo != null) ...[
                      const SizedBox(height: 20),
                      Text("Código de barras: $_codigoSalvo",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processarCodigoManual() async {
    if (_formKey.currentState!.validate()) {
      final codigoDigitado = _codigoController.text.trim();

      try {
        final Produto? produtoExistente =
            await _mercadorSharedProvider.buscarProdutoGlobal(codigoDigitado);

        if (!mounted) return;

        if (produtoExistente != null) {
          _codigoController.clear();
          _mostrarAvisoProdutoExistente(codigoDigitado, produtoExistente.nome);
        } else {
          setState(() => _codigoSalvo = codigoDigitado);

          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TelaNovoProduto(
                codigoBarras: codigoDigitado,
              ),
            ),
          );

          if (resultado == true && mounted) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarAvisoProdutoExistente(String codigo, String nomeProduto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
            SizedBox(height: 8),
            Text("Produto já cadastrado"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Este código de barras já consta em nossa base:"),
            const SizedBox(height: 12),
            Text(
              codigo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300)),
              child: Text(
                nomeProduto,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("ENTENDIDO"),
          ),
        ],
      ),
    );
  }
}
