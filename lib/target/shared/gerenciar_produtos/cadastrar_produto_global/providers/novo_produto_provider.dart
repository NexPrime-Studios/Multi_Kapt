import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../models/produto.dart';
import '../../../../../models/unidade_medida_enums.dart';
import '../../../../../services/shared/imagem_service.dart';
import '../../../../../services/shared/mercado_shared_provider.dart';
import '../../../../funcionario/novo_produto_global/buscar_dados_ia_produto.dart';
import '../buscar_imagem_produto.dart';
import '../../../../funcionario/novo_produto_global/buscar_nome_produto.dart';

class NovoProdutoProvider extends ChangeNotifier {
  final _mercadoService = MercadoSharedProvider();
  final _imagemService = ImagemService();
  final _buscarDadosIA = BuscarDadosIAProduto();
  final _buscarNomeWeb = BuscarNomeProduto();

  // Controllers
  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final classeController = TextEditingController();
  final subclasseController = TextEditingController();
  final produtoBaseController = TextEditingController();
  final variacaoController = TextEditingController();
  final ncmController = TextEditingController();
  final codigoBarrasController = TextEditingController();
  final marcaController = TextEditingController();
  final quantidadeConteudoController = TextEditingController(text: "1");
  final pesoEstimadoController = TextEditingController();

  // Estados
  TipoProduto tipoSelecionado = TipoProduto.industrial;
  String categoriaSelecionada = "Selecione uma categoria";
  UnidadeMedida unidadeMedida = UnidadeMedida.unidade;
  List<String> tagsSelecionadas = [];
  Uint8List? imagemBytes;
  bool semImagem = false;

  // Características
  bool isVegano = false;
  bool isSemGluten = false;
  bool isPerecivel = false;
  bool isSemAcucar = false;
  bool isZeroLactose = false;

  // Estados de UI e Validação
  bool estaSalvando = false;
  bool tagErro = false;
  bool imagemErro = false;

  void updateEstado(VoidCallback acao) {
    acao();
    notifyListeners();
  }

  Future<void> processarBuscaImagem(BuildContext context,
      {String? nomeManual}) async {
    if (semImagem) return;

    if (tipoSelecionado == TipoProduto.interno) {
      await selecionarImagemLocal(context); // Implementar usando ImagePicker
      return;
    }

    estaSalvando = true;
    notifyListeners();

    try {
      String termoPesquisa;
      if (tipoSelecionado == TipoProduto.industrial) {
        termoPesquisa = codigoBarrasController.text;
      } else {
        termoPesquisa = nomeManual ?? nomeController.text;
      }

      if (termoPesquisa.isEmpty) {
        mostrarAlerta(
            context, "Informe o código ou nome para buscar a imagem.");
        return;
      }

      final Uint8List? imagem = await BuscarImagemProduto().buscarProduto(
        context,
        termoPesquisa,
        tipoSelecionado == TipoProduto.industrial,
      );

      if (imagem != null) {
        imagemBytes = imagem;
        semImagem = false;
        imagemErro = false;
      }
    } catch (e) {
      imagemErro = true;
      mostrarAlerta(context, "Erro ao buscar imagem: $e");
    } finally {
      estaSalvando = false;
      notifyListeners();
    }
  }

  Future<void> selecionarImagemLocal(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      imagemBytes = await photo.readAsBytes();
      notifyListeners();
    }
    print("Abrir seletor de galeria");
  }

  Future<void> buscarNomeIA(BuildContext context) async {
    final nome = await _buscarDadosIA.selecionarDado(
        context, codigoBarrasController.text, true);
    if (nome != null) {
      nomeController.text = nome;
      notifyListeners();
    }
  }

  Future<void> buscarNomeWeb(BuildContext context) async {
    final nome =
        await _buscarNomeWeb.buscarNome(context, codigoBarrasController.text);
    if (nome != null) {
      nomeController.text = nome;
      notifyListeners();
    }
  }

  Future<void> buscarDescricaoIA(BuildContext context) async {
    final desc = await _buscarDadosIA.selecionarDado(
        context, codigoBarrasController.text, false);
    if (desc != null) {
      descricaoController.text = desc;
      notifyListeners();
    }
  }

  void setCategoria(String? valor) {
    if (valor != null) {
      categoriaSelecionada = valor;
      classeController.text = (valor == "Selecione uma categoria") ? "" : valor;
      tagsSelecionadas.clear();
      tagErro = false;
      notifyListeners();
    }
  }

  void mostrarAlerta(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.orangeAccent.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> salvarProduto(BuildContext context) async {
    final bool temNome = nomeController.text.trim().isNotEmpty;
    final bool temCategoria = categoriaSelecionada != "Selecione uma categoria";
    final bool temTags = tagsSelecionadas.isNotEmpty;
    final bool imagemFaltando = !semImagem && imagemBytes == null;

    tagErro = !temTags;
    imagemErro = imagemFaltando;
    notifyListeners();

    if (!temNome || !temCategoria || !temTags || imagemFaltando) {
      HapticFeedback.heavyImpact();
      String msg = "⚠️ Verifique os campos obrigatórios";
      if (!temNome) {
        msg = "⚠️ O nome do produto é obrigatório.";
      } else if (!temCategoria) {
        msg = "⚠️ Selecione uma categoria válida.";
      } else if (tagErro) {
        msg = "⚠️ Selecione ao menos uma tag de busca.";
      } else if (imagemErro) {
        msg = "⚠️ Adicione uma foto ou marque 'Sem imagem'.";
      }

      mostrarAlerta(context, msg);
      return;
    }

    estaSalvando = true;
    notifyListeners();

    try {
      String? fotoUrl = "semimagem";
      String idGerado = DateTime.now().millisecondsSinceEpoch.toString();

      if (!semImagem && imagemBytes != null) {
        fotoUrl = await _imagemService.uploadProdutoImage(
          bytes: imagemBytes!,
          produtoId: idGerado,
        );
      }

      final novoProduto = Produto(
        id: '',
        tipo: tipoSelecionado,
        categoria: classeController.text.trim(),
        subcategoria: subclasseController.text.trim(),
        produtoBase: produtoBaseController.text.trim(),
        variacao:
            variacaoController.text.isNotEmpty ? variacaoController.text : null,
        nome: nomeController.text.trim(),
        descricao: descricaoController.text.trim(),
        fotoUrl: fotoUrl ?? "semimagem",
        marca: marcaController.text.toUpperCase(),
        codigoBarras: tipoSelecionado == TipoProduto.industrial
            ? codigoBarrasController.text
            : null,
        ncm: ncmController.text,
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

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("✅ Produto Cadastrado com Sucesso!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) mostrarAlerta(context, "❌ Erro ao salvar: $e");
    } finally {
      estaSalvando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    classeController.dispose();
    subclasseController.dispose();
    produtoBaseController.dispose();
    variacaoController.dispose();
    codigoBarrasController.dispose();
    marcaController.dispose();
    quantidadeConteudoController.dispose();
    pesoEstimadoController.dispose();
    ncmController.dispose();
    super.dispose();
  }
}
