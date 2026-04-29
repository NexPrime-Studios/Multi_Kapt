import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/mercado.dart';
import '../../../models/horario_mercado.dart';
import '../../../enums/produto_enums.dart';
import '../../../services/lojista/lojista_provider.dart';
import '../../../services/shared/imagem_service.dart';
import '../../shared/global_widgets/campo_texto_widget.dart';
import '../../shared/global_widgets/campo_telefone_widget.dart';
import '../widgets/grade_horarios_widget.dart';

class TelaPerfilMercado extends StatefulWidget {
  final Mercado? mercado;

  const TelaPerfilMercado({super.key, this.mercado});

  @override
  State<TelaPerfilMercado> createState() => _TelaPerfilMercadoState();
}

class _TelaPerfilMercadoState extends State<TelaPerfilMercado> {
  final _formKey = GlobalKey<FormState>();
  final ImagemService _imagemService = ImagemService();

  bool _editando = false;
  bool _salvando = false;

  Uint8List? _novaLogoBytes;
  Uint8List? _novaCapaBytes;

  late TextEditingController _nomeController;
  late TextEditingController _telController;
  late TextEditingController _endController;
  late TextEditingController _cidadeController;
  late TextEditingController _estadoController;
  late TextEditingController _taxaController;
  late TextEditingController _minimoController;
  late TextEditingController _tempoController;

  late List<CategoriaProduto> _categoriasSelecionadas;
  late List<PagamentosAceitos> _pagamentosSelecionados;
  late Map<String, DiaFuncionamento> _gradeHorarios;

  @override
  void initState() {
    super.initState();
    final m = widget.mercado ?? context.read<LojistaProvider>().mercado!;
    _inicializarControllers(m);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telController.dispose();
    _endController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _taxaController.dispose();
    _minimoController.dispose();
    _tempoController.dispose();
    super.dispose();
  }

  void _inicializarControllers(Mercado m) {
    _nomeController = TextEditingController(text: m.nome);
    _telController = TextEditingController(text: m.telefone);
    _endController = TextEditingController(text: m.endereco);
    _cidadeController = TextEditingController(text: m.cidade);
    _estadoController = TextEditingController(text: m.estado);
    _taxaController = TextEditingController(text: m.taxaEntrega.toString());
    _minimoController = TextEditingController(text: m.pedidoMinimo.toString());
    _tempoController = TextEditingController(text: m.tempoEntrega);

    _categoriasSelecionadas = List.from(m.categorias);
    _pagamentosSelecionados = List.from(m.pagamentosAceitos);
    _gradeHorarios = Map.from(m.gradeHorarios);
    _novaLogoBytes = null;
    _novaCapaBytes = null;
  }

  Future<void> _pickImage(bool isLogo) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          if (isLogo) {
            _novaLogoBytes = bytes;
          } else {
            _novaCapaBytes = bytes;
          }
        });
      }
    } catch (e) {
      debugPrint("Erro ao selecionar imagem: $e");
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    final provider = context.read<LojistaProvider>();
    final mOriginal = provider.mercado!;

    try {
      String logoUrl = mOriginal.logoUrl;
      String capaUrl = mOriginal.capaUrl;

      if (_novaLogoBytes != null) {
        final res = await _imagemService.uploadMercadoImageWeb(
          bytes: _novaLogoBytes!,
          mercadoId: mOriginal.id,
          isLogo: true,
        );
        if (res != null) logoUrl = res;
      }

      if (_novaCapaBytes != null) {
        final res = await _imagemService.uploadMercadoImageWeb(
          bytes: _novaCapaBytes!,
          mercadoId: mOriginal.id,
          isLogo: false,
        );
        if (res != null) capaUrl = res;
      }

      final mercadoAtu = mOriginal.copyWith(
        nome: _nomeController.text.trim(),
        logoUrl: logoUrl,
        capaUrl: capaUrl,
        cidade: _cidadeController.text.trim(),
        estado: _estadoController.text.trim(),
        endereco: _endController.text.trim(),
        telefone: _telController.text.trim(),
        taxaEntrega:
            double.tryParse(_taxaController.text.replaceAll(',', '.')) ?? 0.0,
        pedidoMinimo:
            double.tryParse(_minimoController.text.replaceAll(',', '.')) ?? 0.0,
        tempoEntrega: _tempoController.text.trim(),
        gradeHorarios: _gradeHorarios,
        categorias: _categoriasSelecionadas,
        pagamentosAceitos: _pagamentosSelecionados,
      );

      await provider.atualizarPerfil(mercadoAtu);

      if (mounted) {
        setState(() => _editando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: Colors.green),
        );
      }
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
    final mercado = context.watch<LojistaProvider>().mercado;
    if (mercado == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_editando ? "Editar Perfil" : "Configurações da Loja"),
        actions: [
          if (!_editando)
            IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _editando = true))
          else if (!_salvando) ...[
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _inicializarControllers(mercado);
                  setState(() => _editando = false);
                }),
            IconButton(icon: const Icon(Icons.check), onPressed: _salvar),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCapaEHeader(mercado),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 60),
                child: Column(
                  children: [
                    _tituloSecao("DADOS LOCAL", Icons.location_on),
                    _itemDinamico(
                        Icons.store, "Nome Fantasia", _nomeController),
                    _itemDinamico(
                        Icons.phone, "WhatsApp (Vendas)", _telController,
                        isTelefone: true),
                    _itemDinamico(Icons.map, "Endereço", _endController),
                    Row(
                      children: [
                        Expanded(
                            child: _itemDinamico(Icons.location_city, "Cidade",
                                _cidadeController)),
                        const SizedBox(width: 15),
                        Expanded(
                            child: _itemDinamico(
                                Icons.flag, "Estado", _estadoController)),
                      ],
                    ),
                    const Divider(height: 50),
                    _tituloSecao("CATEGORIAS", Icons.category),
                    _buildCategoriasSecao(),
                    const Divider(height: 50),
                    _tituloSecao("LOGÍSTICA", Icons.delivery_dining),
                    Row(
                      children: [
                        Expanded(
                            child: _itemDinamico(Icons.attach_money,
                                "Taxa Entrega", _taxaController,
                                isNumero: true)),
                        const SizedBox(width: 15),
                        Expanded(
                            child: _itemDinamico(
                                Icons.shopping_bag, "Mínimo", _minimoController,
                                isNumero: true)),
                      ],
                    ),
                    _itemDinamico(Icons.timer, "Tempo Médio", _tempoController),
                    const Divider(height: 50),
                    _tituloSecao("PAGAMENTOS ACEITOS", Icons.payments),
                    _buildPagamentosSecao(),
                    const Divider(height: 50),
                    _tituloSecao(
                        "HORÁRIOS DE FUNCIONAMENTO", Icons.access_time),
                    _buildHorariosSecao(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemDinamico(
      IconData icone, String label, TextEditingController controller,
      {bool isNumero = false, bool isTelefone = false}) {
    if (_editando) {
      if (isTelefone) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CampoTelefoneWidget(controller: controller, label: label),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CampoTextoWidget(
          controller: controller,
          label: label,
        ),
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icone, color: Theme.of(context).primaryColor),
      title:
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(
          controller.text.isEmpty ? "Não informado" : controller.text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCategoriasSecao() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CategoriaProduto.values.map((cat) {
        final sel = _categoriasSelecionadas.contains(cat);
        return FilterChip(
          label: Text(cat.name),
          selected: sel,
          onSelected: _editando
              ? (v) {
                  setState(() => v
                      ? _categoriasSelecionadas.add(cat)
                      : _categoriasSelecionadas.remove(cat));
                }
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildPagamentosSecao() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PagamentosAceitos.values.map((p) {
        final sel = _pagamentosSelecionados.contains(p);
        return FilterChip(
          label: Text(p.name),
          selected: sel,
          onSelected: _editando
              ? (v) {
                  setState(() => v
                      ? _pagamentosSelecionados.add(p)
                      : _pagamentosSelecionados.remove(p));
                }
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildHorariosSecao() {
    if (_editando) {
      return GradeHorariosWidget(
        grade: _gradeHorarios,
        onToggleDia: (dia, val) => setState(() {
          _gradeHorarios[dia] = _gradeHorarios[dia]!.copyWith(aberto: val);
        }),
        onSelecionarHora: (dia, abr) async {
          final time = await showTimePicker(
              context: context, initialTime: TimeOfDay.now());
          if (time != null) {
            final formatted =
                "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
            setState(() {
              _gradeHorarios[dia] = abr
                  ? _gradeHorarios[dia]!.copyWith(abertura: formatted)
                  : _gradeHorarios[dia]!.copyWith(fechamento: formatted);
            });
          }
        },
      );
    }
    return Column(
      children: _gradeHorarios.entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        e.value.aberto
                            ? "${e.value.abertura} - ${e.value.fechamento}"
                            : "Fechado",
                        style: TextStyle(
                            color: e.value.aberto ? Colors.black : Colors.red)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _tituloSecao(String texto, IconData icone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icone, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 10),
          Text(texto,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }

  Widget _buildCapaEHeader(Mercado mercado) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _editando ? () => _pickImage(false) : null,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              image: _novaCapaBytes != null
                  ? DecorationImage(
                      image: MemoryImage(_novaCapaBytes!), fit: BoxFit.cover)
                  : (mercado.capaUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(mercado.capaUrl),
                          fit: BoxFit.cover)
                      : null),
            ),
            child: _editando
                ? const Center(
                    child:
                        Icon(Icons.camera_alt, color: Colors.white, size: 40))
                : null,
          ),
        ),
        Positioned(
          bottom: -35,
          left: 25,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _editando ? () => _pickImage(true) : null,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 47,
                    backgroundImage: _novaLogoBytes != null
                        ? MemoryImage(_novaLogoBytes!)
                        : (mercado.logoUrl.isNotEmpty
                            ? NetworkImage(mercado.logoUrl)
                            : null) as ImageProvider?,
                    child: _novaLogoBytes == null && mercado.logoUrl.isEmpty
                        ? const Icon(Icons.store)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              if (!_editando)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text(mercado.nome,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 5, color: Colors.black)
                          ])),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
