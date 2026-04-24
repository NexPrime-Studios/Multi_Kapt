import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../services/funcionario/funcionario_provider.dart';
import '../../../services/funcionario/funcionario_service.dart';
import '../../funcionario/pages/tela_selecao_modo.dart';
import '../widgets/confirmar_vinculo_dialog.dart';

class VinculoFuncionarioPage extends StatefulWidget {
  const VinculoFuncionarioPage({super.key});

  @override
  State<VinculoFuncionarioPage> createState() => _VinculoFuncionarioPageState();
}

class _VinculoFuncionarioPageState extends State<VinculoFuncionarioPage> {
  final TextEditingController _codigoController = TextEditingController();
  final FuncionarioService _service = FuncionarioService();
  bool _processando = false;

  /// 1. Processa dados vindos exclusivamente do SCANNER de QR Code
  void _processarQR(String dados) async {
    if (_processando) return;

    final partes = dados.split(':');
    // Verifica se o QR Code segue o padrão: vincular:idMercado:idFuncionario
    if (partes.length == 3 && partes[0] == 'vincular') {
      setState(() => _processando = true);
      _validarEConfirmar(
        mercadoId: partes[1],
        funcionarioId: partes[2],
      );
    } else {
      _mostrarMensagem("QR Code inválido ou incompatível.", isErro: true);
    }
  }

  /// 2. Processa dados vindos exclusivamente do BOTÃO "Vincular Manualmente"
  void _vincularViaCodigoManual() async {
    final codigo = _codigoController.text.toUpperCase().trim();
    if (codigo.isEmpty) {
      _mostrarMensagem("Digite um código válido.", isErro: false);
      return;
    }

    setState(() => _processando = true);

    try {
      // Busca direta no banco através do código literal (Ex: ABC1234)
      final dadosManual = await _service.buscarDadosPorCodigoManual(codigo);

      if (dadosManual == null) {
        throw "Código de funcionário não encontrado.";
      }

      // Se encontrado, segue para validação de nomes
      _validarEConfirmar(
        mercadoId: dadosManual['mercado_id'],
        funcionarioId: dadosManual['id'],
      );
    } catch (e) {
      _mostrarMensagem("$e", isErro: true);
      setState(() => _processando = false);
    }
  }

  /// 3. Lógica compartilhada: Busca nomes no banco e abre o Diálogo de Confirmação
  Future<void> _validarEConfirmar({
    required String mercadoId,
    required String funcionarioId,
  }) async {
    try {
      final nomeMercado = await _service.buscarNomeMercado(mercadoId);
      final nomeFuncionario = await _service.buscarNomeFuncionarioParaVinculo(
        funcionarioId,
        mercadoId,
      );

      if (nomeMercado == null || nomeFuncionario == null) {
        throw "Registro de vínculo não encontrado no sistema.";
      }

      if (mounted) {
        _mostrarConfirmacaoVinculo(
          nomeMercado: nomeMercado,
          nomeFuncionario: nomeFuncionario,
          mercadoId: mercadoId,
          funcionarioId: funcionarioId,
        );
      }
    } catch (e) {
      _mostrarMensagem("❌ $e", isErro: true);
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _mostrarConfirmacaoVinculo({
    required String nomeMercado,
    required String nomeFuncionario,
    required String mercadoId,
    required String funcionarioId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmarVinculoDialog(
        nomeMercado: nomeMercado,
        nomeFuncionario: nomeFuncionario,
        onConfirmar: () => _executarVinculoFinal(mercadoId, funcionarioId),
      ),
    );
  }

  Future<void> _executarVinculoFinal(
      String mercadoId, String funcionarioId) async {
    await context
        .read<FuncionarioProvider>()
        .vincularFuncionario(mercadoId, funcionarioId);

    if (mounted) {
      _mostrarMensagem("✅ Vínculo realizado com sucesso!");
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SelecaoModoPage()),
        (route) => false,
      );
    }
  }

  void _mostrarMensagem(String msg, {bool isErro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isErro ? Colors.red : Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vincular Funcionário"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 300,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black,
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  onDetect: (capture) {
                    for (final barcode in capture.barcodes) {
                      if (barcode.rawValue != null && !_processando) {
                        _processarQR(barcode.rawValue!);
                      }
                    }
                  },
                ),
              ),
            ),
            const Text(
              "Aponte para o QR Code gerado pelo Lojista",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Row(
                children: [
                  Expanded(child: Divider(indent: 30, endIndent: 10)),
                  Text("OU",
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                  Expanded(child: Divider(indent: 10, endIndent: 30)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CÓDIGO MANUAL",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _codigoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: "Ex: 12ABC123",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.keyboard),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _processando ? null : _vincularViaCodigoManual,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cores.primary,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _processando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "VINCULAR MANUALMENTE",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
