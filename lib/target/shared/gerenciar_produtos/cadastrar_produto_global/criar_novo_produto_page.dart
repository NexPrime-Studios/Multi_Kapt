import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/produto.dart';
import '../../../../services/shared/mercado_shared_provider.dart';
import 'tela_cadastro_produto.dart';
import '../../global_widgets/campo_texto_widget.dart';
import '../../global_widgets/scanner_codigo_barras.dart';

class CriarNovoProdutoPage extends StatefulWidget {
  const CriarNovoProdutoPage({super.key});

  @override
  State<CriarNovoProdutoPage> createState() => _CriarNovoProdutoPageState();
}

class _CriarNovoProdutoPageState extends State<CriarNovoProdutoPage> {
  final _codigoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _mercadorSharedProvider = MercadoSharedProvider();

  TipoProduto _identificarTipoPeloCodigo(String codigo) {
    if (codigo.startsWith('2')) return TipoProduto.pesavel;
    if (codigo.length < 8) return TipoProduto.interno;
    return TipoProduto.industrial;
  }

  Future<void> _abrirScanner() async {
    final String? codigoCapturado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerCodigoDeBarrasPage()),
    );

    if (codigoCapturado != null && codigoCapturado.isNotEmpty) {
      _codigoController.text = codigoCapturado;
      _processarCodigoManual();
    }
  }

  Future<void> _processarCodigoManual() async {
    if (_formKey.currentState!.validate()) {
      final codigoDigitado = _codigoController.text.trim();
      final tipoIdentificado = _identificarTipoPeloCodigo(codigoDigitado);

      try {
        if (tipoIdentificado == TipoProduto.industrial) {
          final Produto? produtoExistente =
              await _mercadorSharedProvider.buscarProdutoGlobal(codigoDigitado);

          if (!mounted) return;

          if (produtoExistente != null) {
            _mostrarAvisoProdutoExistente(
                codigoDigitado, produtoExistente.nome);
            return;
          }
        }

        if (!mounted) return;
        _irParaCadastro(codigoDigitado, tipoIdentificado);
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Produto já existe"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Este código de barras já está vinculado a um produto:"),
            const SizedBox(height: 12),
            Text(nomeProduto,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Código: $codigo"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ENTENDIDO"),
          ),
        ],
      ),
    );
  }

  void _irParaCadastro(String codigo, TipoProduto tipo) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaCadastroNovoProduto(
          codigoBarrasInicial: codigo,
          tipoDefinido: tipo,
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
        title: const Text(
          "Cadastrar Novo Produto Na Lista Global",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Define se é "Desktop" baseado na largura da tela (ex: > 800px)
          bool isDesktop = constraints.maxWidth > 800;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: isDesktop
                  ? _buildDesktopLayout(cores)
                  : _buildMobileLayout(cores),
            ),
          );
        },
      ),
    );
  }

  // --- LAYOUT PARA CELULAR (Vertical) ---
  Widget _buildMobileLayout(ColorScheme cores) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450),
      child: Column(
        children: [
          _buildAvisoCard(),
          const SizedBox(height: 16),
          _buildFormPrincipal(cores),
          const SizedBox(height: 24),
          _buildDivisor("OU CADASTRO MANUAL"),
          const SizedBox(height: 20),
          _buildSeccaoManual(),
        ],
      ),
    );
  }

  // --- LAYOUT PARA DESKTOP (Lado a Lado) ---
  Widget _buildDesktopLayout(ColorScheme cores) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center, // Centraliza verticalmente
      children: [
        // Lado Esquerdo: Formulário
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvisoCard(),
              const SizedBox(height: 16),
              _buildFormPrincipal(cores),
            ],
          ),
        ),

        // SeparadorVertical no PC
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 80),
        ),

        // Lado Direito: Cadastro Manual
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "CADASTRO MANUAL",
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
              const SizedBox(height: 20),
              _buildSeccaoManual(),
            ],
          ),
        ),
      ],
    );
  }

  // --- COMPONENTES REUTILIZÁVEIS ---

  Widget _buildAvisoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade400, width: 0.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Evite adicionar produtos que o cliente deveria escolher pessoalmente. (Ex: Bolos de Aniversário, Roupas, Carnes com cortes específicos ou Frutas muito sensíveis).",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPrincipal(ColorScheme cores) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      size: 24, color: cores.primary),
                  const SizedBox(width: 8),
                  const Text(
                    "Identificação Rápida",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Escaneie ou digite o código para buscar o produto.",
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _abrirScanner,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: const Text("ESCANEAR AGORA"),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CampoTextoWidget(
                      label: "Código de Barras",
                      controller: _codigoController,
                      icon: Icons.edit_note,
                      type: TextInputType.number,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Obrigatório" : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: cores.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _processarCodigoManual,
                      icon: const Icon(Icons.search, color: Colors.white),
                      tooltip: "Verificar Código",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccaoManual() {
    return Column(
      children: [
        _buildCardManual(
          titulo: "Novo Item por Peso",
          descricao: "Hortifruti, Açougue, Padaria.",
          icon: Icons.scale_rounded,
          cor: Colors.teal,
          onTap: () => _irParaCadastro("", TipoProduto.pesavel),
        ),
        const SizedBox(height: 12),
        _buildCardManual(
          titulo: "Produção Interna",
          descricao: "Fabricação própria com preço fixo.",
          icon: Icons.restaurant_menu_rounded,
          cor: Colors.deepPurple,
          onTap: () => _irParaCadastro("", TipoProduto.interno),
        ),
      ],
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(descricao,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14),
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
}
