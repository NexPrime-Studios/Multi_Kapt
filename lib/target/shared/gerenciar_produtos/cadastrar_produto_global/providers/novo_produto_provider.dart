import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../../models/produto.dart';
import '../../../../../enums/unidade_medida_enums.dart';
import '../../../../../services/shared/imagem_service.dart';
import '../../../../../services/shared/mercado_shared_provider.dart';
import '../../../../../services/shared/open_router_service.dart';
import 'categoria_provider.dart';

class NovoProdutoProvider extends ChangeNotifier {
  final _mercadoService = MercadoSharedProvider();
  final _imagemService = ImagemService();

  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final codigoBarrasController = TextEditingController();
  final marcaController = TextEditingController();
  final ncmController = TextEditingController();
  final quantidadeConteudoController = TextEditingController(text: "1");
  final pesoEstimadoController = TextEditingController();

  // Estados de Dados
  TipoProduto tipoSelecionado = TipoProduto.industrial;
  UnidadeMedida unidadeMedida = UnidadeMedida.unidade;
  List<String> tagsSelecionadas = [];
  Uint8List? imagemBytes;
  bool semImagem = false;

  // Características (Booleanos editáveis diretamente)
  bool isVegano = false;
  bool isSemGluten = false;
  bool isPerecivel = false;
  bool isSemAcucar = false;
  bool isZeroLactose = false;

  // Estados de UI
  bool estaSalvando = false;
  bool carregandoIA = false;
  bool tagErro = false;

  Future<void> inicializarBuscaIA(String ean) async {
    if (tipoSelecionado != TipoProduto.industrial || ean.isEmpty) return;

    carregandoIA = true;
    notifyListeners();

    try {
      final service = OpenRouterService();
      final produto = await service.buscarProdutoPorEan(ean);

      if (produto != null) {
        nomeController.text = produto.nome;
        descricaoController.text = produto.descricao;
        marcaController.text = produto.marca.toUpperCase();
        ncmController.text = produto.ncm;
      }
    } catch (e) {
      debugPrint("Erro ao buscar dados na IA: $e");
    } finally {
      carregandoIA = false;
      notifyListeners();
    }
  }

  void updateEstado(VoidCallback acao) {
    acao();
    notifyListeners();
  }

  Future<void> selecionarImagemLocal(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    ImageSource? source;

    if (tipoSelecionado == TipoProduto.interno) {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tirar Foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    } else {
      source = ImageSource.gallery;
    }

    if (source != null) {
      final photo = await picker.pickImage(source: source);
      if (photo != null) {
        imagemBytes = await photo.readAsBytes();
        notifyListeners();
      }
    }
  }

  // --- LÓGICA DE SALVAMENTO ---

  Future<void> salvarProduto(BuildContext context) async {
    final catProv = context
        .read<CategoriaProvider>(); // Lê a classificação diretamente daqui

    // Validação simplificada
    final bool temNome = nomeController.text.trim().isNotEmpty;
    final bool temCategoria = catProv.categoriaSelecionada != null;
    final bool temTags = tagsSelecionadas.isNotEmpty;

    updateEstado(() {
      tagErro = !temTags;
    });

    if (!temNome || !temCategoria || !temTags) {
      HapticFeedback.heavyImpact();
      mostrarAlerta(context, "⚠️ Verifique os campos obrigatórios.");
      return;
    }

    updateEstado(() => estaSalvando = true);

    try {
      String? fotoUrl = "semimagem";
      if (!semImagem && imagemBytes != null) {
        fotoUrl = await _imagemService.uploadProdutoImage(
            bytes: imagemBytes!,
            produtoId: DateTime.now().millisecondsSinceEpoch.toString());
      }

      final novoProduto = Produto(
        id: '',
        tipo: tipoSelecionado,
        categoria: catProv.categoriaSelecionada?.label ?? "",
        produtoBase: catProv.produtoBaseSelecionado == "ADICIONAR_NOVA"
            ? catProv.produtoBaseManualController.text
            : (catProv.produtoBaseSelecionado ?? ""),
        variacao: catProv.variacaoSelecionada == "ADICIONAR_NOVA"
            ? catProv.variacaoManualController.text
            : (catProv.variacaoSelecionada ?? ""),
        nome: nomeController.text.trim(),
        descricao: descricaoController.text.trim(),
        fotoUrl: fotoUrl ?? "semimagem",
        marca: marcaController.text.toUpperCase(),
        codigoBarras: tipoSelecionado == TipoProduto.industrial
            ? codigoBarrasController.text
            : null,
        ncm: ncmController.text.trim(),
        unidadeMedida: unidadeMedida,
        quantidadeConteudo: double.tryParse(
                quantidadeConteudoController.text.replaceAll(',', '.')) ??
            0.0,
        tags: tagsSelecionadas,
        isVegano: isVegano,
        isSemGluten: isSemGluten,
        isPerecivel: isPerecivel,
        isSemAcucar: isSemAcucar,
        isZeroLactose: isZeroLactose,
        pesoEstimadoUnidade:
            double.tryParse(pesoEstimadoController.text.replaceAll(',', '.')),
      );

      await _mercadoService.cadastrarProdutoGlobal(novoProduto);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) mostrarAlerta(context, "❌ Erro ao salvar: $e");
    } finally {
      updateEstado(() => estaSalvando = false);
    }
  }

  void mostrarAlerta(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  void dispose() {
    for (var c in [
      nomeController,
      descricaoController,
      codigoBarrasController,
      marcaController,
      quantidadeConteudoController,
      pesoEstimadoController
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
