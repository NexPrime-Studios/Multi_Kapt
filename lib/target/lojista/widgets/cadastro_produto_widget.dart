import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Adicionado
import '../../../../models/produto.dart';
import '../../../../models/produto_enums.dart';
import '../../../../models/tags_helper.dart';
import '../../../../services/lojista_service.dart';
import '../../../../services/imagem_service.dart'; // Adicionado
import '../widgets/campo_formulario.dart';

enum TelaDialog { menu, buscaEdicao, formulario }

class DialogCadastroProduto extends StatefulWidget {
  final Produto? produtoParaEditar;

  const DialogCadastroProduto({super.key, this.produtoParaEditar});

  @override
  State<DialogCadastroProduto> createState() => _DialogCadastroProdutoState();
}

class _DialogCadastroProdutoState extends State<DialogCadastroProduto> {
  final _formKey = GlobalKey<FormState>();
  final _service = LojistaService();
  final ImagemService _imagemService = ImagemService(); // Inicializado

  TelaDialog _telaAtual = TelaDialog.menu;
  String _filtroBusca = "";
  Produto? _produtoSelecionado;

  final _nomeController = TextEditingController();
  final _marcaController = TextEditingController();
  final _barrasController = TextEditingController();
  final _descController = TextEditingController();
  final _valorMedidaController = TextEditingController(text: "1");
  final _urlImagemController = TextEditingController();

  Uint8List? _novaImagemBytes; // Para armazenar a imagem selecionada localmente
  CategoriaProduto _categoria = CategoriaProduto.mercearia;
  UnidadeMedida _unidade = UnidadeMedida.unidade;
  final List<String> _tagsSelecionadas = [];
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    if (widget.produtoParaEditar != null) {
      _carregarProduto(widget.produtoParaEditar!);
    }
  }

  void _carregarProduto(Produto p) {
    setState(() {
      _produtoSelecionado = p;
      _nomeController.text = p.nome;
      _marcaController.text = p.marca;
      _descController.text = p.descricao;
      _urlImagemController.text = p.fotoUrl;
      _barrasController.text = p.codigoBarras;
      _categoria = p.categoria;
      _unidade = p.unidadeMedida;
      _tagsSelecionadas.clear();
      _tagsSelecionadas.addAll(p.tags);
      _novaImagemBytes = null; // Limpa seleção local ao carregar existente
      _telaAtual = TelaDialog.formulario;
    });
  }

  // Lógica para selecionar imagem da galeria
  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _novaImagemBytes = bytes;
      });
    }
  }

  void _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      String fotoUrl = _urlImagemController.text.trim();
      String idProduto = _produtoSelecionado?.id ??
          DateTime.now()
              .millisecondsSinceEpoch
              .toString(); // ID temporário para novo produto

      // Se houver uma nova imagem selecionada, faz o upload para o Storage
      if (_novaImagemBytes != null) {
        final resUrl = await _imagemService.uploadProdutoImage(
          bytes: _novaImagemBytes!,
          produtoId: idProduto,
        );
        if (resUrl != null) fotoUrl = resUrl;
      }

      String nomeFinal = _nomeController.text.trim();
      if (_produtoSelecionado == null &&
          _valorMedidaController.text.isNotEmpty) {
        nomeFinal += " ${_valorMedidaController.text}${_unidade.sigla}";
      }

      final produtoDados = Produto(
        id: _produtoSelecionado?.id ??
            '', // No insert o ID real será gerado pelo banco se vazio
        nome: nomeFinal,
        descricao: _descController.text.trim(),
        fotoUrl: fotoUrl,
        marca: _marcaController.text.trim(),
        codigoBarras: _barrasController.text.trim(),
        categoria: _categoria,
        unidadeMedida: _unidade,
        tags: _tagsSelecionadas,
      );

      await _service.salvarProduto(produtoDados);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_produtoSelecionado == null
              ? '✅ Produto Cadastrado!'
              : '✅ Alterações Salvas!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 850),
        child: Stack(
          children: [
            _salvando
                ? const SizedBox(
                    height: 300,
                    child: Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Processando Imagem...")
                      ],
                    )))
                : _renderizarConteudo(),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderizarConteudo() {
    switch (_telaAtual) {
      case TelaDialog.menu:
        return _buildMenu();
      case TelaDialog.buscaEdicao:
        return _buildBuscaEdicao();
      case TelaDialog.formulario:
        return _buildFormulario();
    }
  }

  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Gestão Global",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Escolha uma ação abaixo",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          _botaoOpcao(
            icon: Icons.add_circle_outline,
            label: "Novo Produto",
            sublabel: "Criar um item do zero",
            color: Colors.green,
            onTap: () => setState(() => _telaAtual = TelaDialog.formulario),
          ),
          const SizedBox(height: 16),
          _botaoOpcao(
            icon: Icons.edit_note,
            label: "Editar Existente",
            sublabel: "Alterar dados na biblioteca",
            color: Colors.blue,
            onTap: () => setState(() => _telaAtual = TelaDialog.buscaEdicao),
          ),
        ],
      ),
    );
  }

  Widget _buildBuscaEdicao() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderVoltar("Buscar para Editar"),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
                hintText: "Nome ou marca...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12))),
            onChanged: (val) => setState(() => _filtroBusca = val),
          ),
        ),
        const Divider(),
        SizedBox(
          height: 350,
          child: StreamBuilder<List<Produto>>(
            stream: _service.listarProdutosGlobais(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final produtos = snapshot.data!
                  .where((p) =>
                      p.nome
                          .toLowerCase()
                          .contains(_filtroBusca.toLowerCase()) ||
                      p.marca
                          .toLowerCase()
                          .contains(_filtroBusca.toLowerCase()))
                  .toList();
              if (produtos.isEmpty)
                return const Center(child: Text("Nenhum produto encontrado."));
              return ListView.builder(
                itemCount: produtos.length,
                itemBuilder: (context, i) => ListTile(
                  leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(produtos[i].fotoUrl,
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image))),
                  title: Text(produtos[i].nome),
                  subtitle: Text(produtos[i].marca),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _carregarProduto(produtos[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildHeaderVoltar(_produtoSelecionado == null
                ? "Novo Cadastro"
                : "Editando Produto"),
            const SizedBox(height: 10),
            _secaoTitulo("Imagem do Produto", Icons.image),
            _buildAreaUpload(),
            const SizedBox(height: 40),
            _secaoTitulo("Dados Principais", Icons.info_outline),
            CampoFormulario(
                controller: _nomeController,
                titulo: "Nome",
                label: "Ex: Sabão em Pó",
                icone: Icons.shopping_bag),
            CampoFormulario(
                controller: _marcaController,
                titulo: "Marca",
                label: "Ex: Omo",
                icone: Icons.copyright),
            CampoFormulario(
                controller: _descController,
                titulo: "Descrição",
                label: "Detalhes do produto...",
                icone: Icons.description_outlined),
            _buildDropdownCategoria(),
            const SizedBox(height: 16),
            if (_produtoSelecionado == null) ...[
              _secaoTitulo("Medida/Peso", Icons.scale),
              Row(children: [
                Expanded(
                    child: CampoFormulario(
                        controller: _valorMedidaController,
                        titulo: "Valor",
                        label: "1",
                        icone: Icons.straighten,
                        isNumero: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdownUnidadeCompacta()),
              ]),
            ],
            const Divider(height: 40),
            _secaoTitulo("Tags de Busca", Icons.label_outline),
            _buildTagChips(),
            const Divider(height: 40),
            _secaoTitulo("Rastreabilidade", Icons.qr_code),
            CampoFormulario(
                controller: _barrasController,
                titulo: "Código de Barras",
                label: "EAN-13",
                icone: Icons.qr_code_scanner,
                isNumero: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.check_circle),
                  label: Text(_produtoSelecionado == null
                      ? "CADASTRAR PRODUTO"
                      : "SALVAR ALTERAÇÕES")),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaUpload() {
    return GestureDetector(
      onTap: _selecionarImagem,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid),
        ),
        child: _novaImagemBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.memory(_novaImagemBytes!, fit: BoxFit.cover))
            : (_urlImagemController.text.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.network(_urlImagemController.text,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.broken_image)))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cloud_upload_outlined,
                          size: 40, color: Colors.blue),
                      Text("Clique para selecionar foto",
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold))
                    ],
                  )),
      ),
    );
  }

  // --- MÉTODOS DE SUPORTE MANTIDOS ---
  Widget _buildHeaderVoltar(String titulo) {
    return Row(children: [
      IconButton(
          onPressed: () => setState(() => _telaAtual = TelaDialog.menu),
          icon: const Icon(Icons.arrow_back_ios, size: 20)),
      Text(titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _botaoOpcao(
      {required IconData icon,
      required String label,
      required String sublabel,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(15),
            color: color.withOpacity(0.05)),
        child: Row(children: [
          CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(sublabel,
                style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
          ]),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.blueGrey)
        ]),
      ),
    );
  }

  Widget _secaoTitulo(String titulo, IconData icone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icone, color: Colors.blueGrey, size: 18),
        const SizedBox(width: 8),
        Text(titulo,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blueGrey))
      ]),
    );
  }

  Widget _buildDropdownCategoria() {
    return DropdownButtonFormField<CategoriaProduto>(
      value: _categoria,
      decoration: const InputDecoration(labelText: "Categoria"),
      items: CategoriaProduto.values
          .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
          .toList(),
      onChanged: (val) => setState(() {
        _categoria = val!;
        _tagsSelecionadas.clear();
      }),
    );
  }

  Widget _buildDropdownUnidadeCompacta() {
    return DropdownButtonFormField<UnidadeMedida>(
      value: _unidade,
      decoration: const InputDecoration(labelText: "Unidade"),
      items: UnidadeMedida.values
          .map((u) => DropdownMenuItem(value: u, child: Text(u.sigla)))
          .toList(),
      onChanged: (val) => setState(() => _unidade = val!),
    );
  }

  Widget _buildTagChips() {
    final sugestoes = TagsHelper.sugestoesPorCategoria[_categoria.name] ?? [];
    return Wrap(
      spacing: 8,
      children: sugestoes.map((tag) {
        final sel = _tagsSelecionadas.contains(tag);
        return FilterChip(
            label: Text(tag),
            selected: sel,
            onSelected: (v) => setState(() => v
                ? _tagsSelecionadas.add(tag)
                : _tagsSelecionadas.remove(tag)));
      }).toList(),
    );
  }
}
