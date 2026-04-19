import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/mercado.dart';
import '../../../models/horario_mercado.dart';
import '../../../models/produto_enums.dart';
import '../../../services/lojista_service.dart';
import '../../../services/lojista_provider.dart';
import '../../../services/imagem_service.dart';
import '../widgets/campo_formulario.dart';
import '../widgets/grade_horarios_widget.dart';

class TelaPerfilMercado extends StatefulWidget {
  final Mercado? mercado;

  const TelaPerfilMercado({super.key, this.mercado});

  @override
  State<TelaPerfilMercado> createState() => _TelaPerfilMercadoState();
}

class _TelaPerfilMercadoState extends State<TelaPerfilMercado> {
  final _formKey = GlobalKey<FormState>();

  // Inicialização direta para evitar o LateInitializationError e redundâncias
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
  late TextEditingController _latController;
  late TextEditingController _lngController;

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
    _latController.dispose();
    _lngController.dispose();
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
    _latController = TextEditingController(text: m.latitude.toString());
    _lngController = TextEditingController(text: m.longitude.toString());

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

  double _paraDouble(dynamic valor) {
    if (valor == null) return 0.0;
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0.0;
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

      final mercadoAtu = Mercado(
        id: mOriginal.id,
        nome: _nomeController.text.trim(),
        logoUrl: logoUrl,
        capaUrl: capaUrl,
        cidade: _cidadeController.text.trim(),
        estado: _estadoController.text.trim(),
        endereco: _endController.text.trim(),
        telefone: _telController.text.trim(),
        estrelas: mOriginal.estrelas,
        taxaEntrega: _paraDouble(_taxaController.text),
        pedidoMinimo: _paraDouble(_minimoController.text),
        tempoEntrega: _tempoController.text.trim(),
        estaAberto: mOriginal.estaAberto,
        itens: mOriginal.itens,
        gradeHorarios: _gradeHorarios,
        categorias: _categoriasSelecionadas,
        pagamentosAceitos: _pagamentosSelecionados,
        latitude: _paraDouble(_latController.text),
        longitude: _paraDouble(_lngController.text),
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
      debugPrint("Erro detalhado ao salvar: $e");
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
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
                child: Column(
                  children: [
                    _tituloSecao("DADOS LOCAL", Icons.location_on),
                    _itemDinamico(
                        Icons.store, "Nome Fantasia", _nomeController),
                    _itemDinamico(Icons.map, "Endereço", _endController),
                    Row(
                      children: [
                        Expanded(
                            child: _itemDinamico(Icons.location_city, "Cidade",
                                _cidadeController)),
                        const SizedBox(width: 20),
                        Expanded(
                            child: _itemDinamico(
                                Icons.flag, "Estado (UF)", _estadoController)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _itemDinamico(
                                Icons.gps_fixed, "Latitude", _latController,
                                numero: true)),
                        const SizedBox(width: 20),
                        Expanded(
                            child: _itemDinamico(
                                Icons.gps_fixed, "Longitude", _lngController,
                                numero: true)),
                      ],
                    ),
                    const Divider(height: 50),
                    _tituloSecao("LOGÍSTICA", Icons.delivery_dining),
                    _itemDinamico(Icons.phone, "WhatsApp", _telController),
                    Row(
                      children: [
                        Expanded(
                            child: _itemDinamico(Icons.attach_money,
                                "Taxa Entrega", _taxaController,
                                numero: true)),
                        const SizedBox(width: 20),
                        Expanded(
                            child: _itemDinamico(Icons.shopping_bag,
                                "Pedido Mínimo", _minimoController,
                                numero: true)),
                      ],
                    ),
                    _itemDinamico(
                        Icons.timer, "Tempo Entrega", _tempoController),
                    const Divider(height: 50),
                    _tituloSecao("PAGAMENTOS", Icons.payments),
                    _buildPagamentosSecao(),
                    const Divider(height: 50),
                    _tituloSecao("HORÁRIOS", Icons.access_time),
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

  Widget _buildCapaEHeader(Mercado mercado) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _editando ? () => _pickImage(false) : null,
          child: Container(
            width: double.infinity,
            height: 220,
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
                ? Container(
                    color: Colors.black26,
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 40))
                : null,
          ),
        ),
        Positioned(
          bottom: -40,
          left: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _editando ? () => _pickImage(true) : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 51,
                        backgroundColor: Colors.grey[100],
                        backgroundImage: _novaLogoBytes != null
                            ? MemoryImage(_novaLogoBytes!)
                            : (mercado.logoUrl
                                    .isNotEmpty // Removida checagem null redundante
                                ? NetworkImage(mercado.logoUrl)
                                : null) as ImageProvider?,
                        child: _novaLogoBytes == null && mercado.logoUrl.isEmpty
                            ? const Icon(Icons.store, size: 35)
                            : null,
                      ),
                    ),
                    if (_editando)
                      const CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.black26,
                          child: Icon(Icons.edit, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Padding(
                padding: const EdgeInsets.only(bottom: 45),
                child: Text(
                  _nomeController.text,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold, // Negrito
                    color: Colors.white, // Cor branca
                    shadows: [
                      Shadow(
                        blurRadius: 10.0, // Intensidade do borrão
                        color: Colors.black54, // Cor da sombra
                        offset: Offset(2.0, 2.0), // Posição (x, y)
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _itemDinamico(
      IconData icone, String titulo, TextEditingController controller,
      {bool numero = false}) {
    if (_editando) {
      return CampoFormulario(
          controller: controller,
          titulo: titulo,
          label: "",
          icone: icone,
          isNumero: numero);
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icone, color: Theme.of(context).colorScheme.primary),
      title: Text(titulo,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(
          controller.text.isEmpty ? "Não informado" : controller.text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPagamentosSecao() {
    String formatar(PagamentosAceitos p) {
      if (p == PagamentosAceitos.dinheiro) return "Dinheiro";
      if (p == PagamentosAceitos.pix) return "Pix";
      if (p == PagamentosAceitos.cartao) return "Cartão";
      return "Vale";
    }

    if (_editando) {
      return Wrap(
        spacing: 10,
        children: PagamentosAceitos.values.map((p) {
          final sel = _pagamentosSelecionados.contains(p);
          return FilterChip(
            label: Text(formatar(p)),
            selected: sel,
            onSelected: (v) => setState(() => v
                ? _pagamentosSelecionados.add(p)
                : _pagamentosSelecionados.remove(p)),
          );
        }).toList(),
      );
    }
    return Text(_pagamentosSelecionados.isEmpty
        ? "Nenhum selecionado"
        : _pagamentosSelecionados.map((p) => formatar(p)).join(" • "));
  }

  Widget _buildHorariosSecao() {
    final dias = [
      'segunda',
      'terca',
      'quarta',
      'quinta',
      'sexta',
      'sabado',
      'domingo',
      'feriado'
    ];
    if (_editando) {
      return GradeHorariosWidget(
        grade: _gradeHorarios,
        onToggleDia: (dia, val) => setState(() {
          final atual = _gradeHorarios[dia]!;
          _gradeHorarios[dia] = DiaFuncionamento(
              aberto: val,
              abertura: atual.abertura,
              fechamento: atual.fechamento);
        }),
        onSelecionarHora: (dia, abr) async {
          final info = _gradeHorarios[dia]!;
          final time = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 8, minute: 0));
          if (time != null) {
            setState(() {
              final formatted =
                  "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
              _gradeHorarios[dia] = DiaFuncionamento(
                  aberto: info.aberto,
                  abertura: abr ? formatted : info.abertura,
                  fechamento: abr ? info.fechamento : formatted);
            });
          }
        },
      );
    }
    return Column(
      children: dias.map((dia) {
        final info = _gradeHorarios[dia]!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dia.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  info.aberto
                      ? "${info.abertura} às ${info.fechamento}"
                      : "Fechado",
                  style: TextStyle(
                      color: info.aberto ? Colors.black : Colors.red)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _tituloSecao(String texto, IconData icone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icone, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Text(texto,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}
