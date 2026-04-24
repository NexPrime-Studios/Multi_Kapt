import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importação das Etapas
import 'widgets/etapa_geral.dart';
import 'widgets/etapa_localizacao.dart';
import 'widgets/etapa_regras.dart';
import 'widgets/etapa_horarios.dart';

// Models e Services
import '../../../models/mercado.dart';
import '../../../models/funcionario.dart';
import '../../../models/horario_mercado.dart';
import '../../../models/produto_enums.dart';
import '../../../services/lojista/lojista_service.dart';
import '../../../services/lojista/lojista_provider.dart';
import '../pages/tela_homepage_lojista.dart';
import '../../../services/shared/imagem_service.dart';

class CadastroMercadoPage extends StatefulWidget {
  const CadastroMercadoPage({super.key});

  @override
  State<CadastroMercadoPage> createState() => _CadastroMercadoPageState();
}

class _CadastroMercadoPageState extends State<CadastroMercadoPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = LojistaService();
  final _imagemService = ImagemService();

  int _indexAtual = 0;
  bool _carregando = false;

  // Estados de Imagem em Bytes para compatibilidade com Web/PC
  Uint8List? _logoBytes;
  Uint8List? _capaBytes;

  late final Map<String, TextEditingController> _controllers;
  final List<CategoriaProduto> _categoriasSelecionadas = [];
  final List<PagamentosAceitos> _pagamentosSelecionados = [];

  final Map<String, DiaFuncionamento> _grade = {
    'segunda':
        DiaFuncionamento(aberto: true, abertura: "08:00", fechamento: "20:00"),
    'terca':
        DiaFuncionamento(aberto: true, abertura: "08:00", fechamento: "20:00"),
    'quarta':
        DiaFuncionamento(aberto: true, abertura: "08:00", fechamento: "20:00"),
    'quinta':
        DiaFuncionamento(aberto: true, abertura: "08:00", fechamento: "20:00"),
    'sexta':
        DiaFuncionamento(aberto: true, abertura: "08:00", fechamento: "20:00"),
    'sabado':
        DiaFuncionamento(aberto: true, abertura: "08:00", fechamento: "18:00"),
    'domingo': DiaFuncionamento(aberto: false),
    'feriado': DiaFuncionamento(aberto: false),
  };

  @override
  void initState() {
    super.initState();
    _controllers = {
      'nomeDono': TextEditingController(),
      'nome': TextEditingController(),
      'tel': TextEditingController(),
      'logo': TextEditingController(),
      'capa': TextEditingController(),
      'end': TextEditingController(),
      'cidade': TextEditingController(),
      'estado': TextEditingController(),
      'lat': TextEditingController(text: "0.0"),
      'lng': TextEditingController(text: "0.0"),
      'taxa': TextEditingController(),
      'minimo': TextEditingController(),
      'tempo': TextEditingController(text: "30-50 min"),
    };
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _paraDouble(String texto) {
    String limpo = texto.replaceAll(',', '.').trim();
    return double.tryParse(limpo) ?? 0.0;
  }

  Future<void> _selecionarHora(String dia, bool isAbertura) async {
    final infoAtual = _grade[dia]!;
    final horaParts =
        (isAbertura ? infoAtual.abertura : infoAtual.fechamento).split(':');
    final TimeOfDay? novoTempo = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: int.parse(horaParts[0]), minute: int.parse(horaParts[1])),
    );
    if (novoTempo != null) {
      setState(() {
        final horaFormatada =
            "${novoTempo.hour.toString().padLeft(2, '0')}:${novoTempo.minute.toString().padLeft(2, '0')}";
        _grade[dia] = DiaFuncionamento(
          aberto: infoAtual.aberto,
          abertura: isAbertura ? horaFormatada : infoAtual.abertura,
          fechamento: isAbertura ? infoAtual.fechamento : horaFormatada,
        );
      });
    }
  }

  void _salvarMercado() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      final user = _service.supabase.auth.currentUser;
      if (user == null) throw "Usuário não identificado.";

      String logoUrl = "";
      String capaUrl = "";

      if (_logoBytes != null) {
        final res = await _imagemService.uploadMercadoImageWeb(
          bytes: _logoBytes!,
          mercadoId: user.id,
          isLogo: true,
        );
        if (res == null) {
          throw "Erro ao carregar o Logo."; // Garante que não prossegue sem a URL
        }
        logoUrl = res;
      }

      if (_capaBytes != null) {
        final res = await _imagemService.uploadMercadoImageWeb(
          bytes: _capaBytes!,
          mercadoId: user.id,
          isLogo: false,
        );
        if (res == null) throw "Erro ao carregar a Capa.";
        capaUrl = res;
      }

      final novoMercado = Mercado(
        id: '',
        adminUid: '',
        nome: _controllers['nome']!.text.trim(),
        logoUrl: logoUrl,
        capaUrl: capaUrl,
        cidade: _controllers['cidade']!.text.trim(),
        estado: _controllers['estado']!.text.trim(),
        endereco: _controllers['end']!.text.trim(),
        telefone: _controllers['tel']!.text.trim(),
        estrelas: 5.0,
        taxaEntrega: _paraDouble(_controllers['taxa']!.text),
        pedidoMinimo: _paraDouble(_controllers['minimo']!.text),
        tempoEntrega: _controllers['tempo']!.text.trim(),
        estaAberto: true,
        itens: [],
        gradeHorarios: _grade,
        categorias: _categoriasSelecionadas,
        pagamentosAceitos: _pagamentosSelecionados,
        latitude: _paraDouble(_controllers['lat']!.text),
        longitude: _paraDouble(_controllers['lng']!.text),
      );

      final novoMercadoId = await _service.adicionarMercado(novoMercado);

      // 2. Cria o registro do Funcionário (Dono) vinculado a este mercado
      final novoFuncionario = Funcionario(
        id: '',
        nome: _controllers['nomeDono']!.text.trim(),
        email: user.email ?? "",
        cargo: CargoAcesso.dono,
        mercadoId: novoMercadoId,
        ativo: true,
        codigoSenha: "",
      );

      // 3. Salva o funcionário através do serviço existente
      await _service.salvarFuncionario(novoFuncionario);

      if (!mounted) return;
      context.read<LojistaProvider>().inicializar(user.id);
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePageLojista()),
          (route) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: const Color(0xFFFF4B4B)));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget _buildPassoAtivo() {
    switch (_indexAtual) {
      case 0:
        return EtapaGeral(
          key: const PageStorageKey("etapa_identidade"),
          controllers: _controllers,
          logoBytes: _logoBytes,
          capaBytes: _capaBytes,
          onLogoSelecionado: (bytes) => setState(() => _logoBytes = bytes),
          onCapaSelecionada: (bytes) => setState(() => _capaBytes = bytes),
        );
      case 1:
        return EtapaLocalizacao(controllers: _controllers);
      case 2:
        return EtapaRegras(
            controllers: _controllers,
            categorias: _categoriasSelecionadas,
            pagamentos: _pagamentosSelecionados);
      case 3:
        return EtapaHorarios(
          grade: _grade,
          onSelecionarHora: _selecionarHora,
          onToggleDia: (dia, val) =>
              setState(() => _grade[dia] = DiaFuncionamento(
                    aberto: val,
                    abertura: _grade[dia]!.abertura,
                    fechamento: _grade[dia]!.fechamento,
                  )),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBg = Color(0xFF121212);
    const Color darkCard = Color(0xFF1E1E1E);
    const Color neonBlue = Color(0xFF00D2FF);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('Configuração da Loja',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: neonBlue))
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    _buildBarraProgresso(neonBlue),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Card(
                          color: darkCard,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme: InputDecorationTheme(
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelStyle:
                                      const TextStyle(color: Colors.black54),
                                  prefixIconColor: Colors.black45,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              child: Form(
                                  key: _formKey, child: _buildPassoAtivo()),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildAcoesNavegacao(neonBlue),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBarraProgresso(Color corAtiva) {
    List<String> titulos = ["Identidade", "Localização", "Regras", "Horários"];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        children: List.generate(4, (index) {
          bool ativo = index <= _indexAtual;
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: ativo ? corAtiva : Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  titulos[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                    color: ativo ? corAtiva : Colors.white38,
                  ),
                )
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAcoesNavegacao(Color corPrimaria) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 10, 32, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_indexAtual > 0)
            TextButton(
              onPressed: () => setState(() => _indexAtual--),
              style: TextButton.styleFrom(minimumSize: const Size(100, 44)),
              child: const Text("VOLTAR",
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (_indexAtual < 3) {
                  setState(() => _indexAtual++);
                } else {
                  _salvarMercado();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Preencha todos os campos obrigatórios!")));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: corPrimaria,
              foregroundColor: const Color(0xFF1A1A1A),
              minimumSize: const Size(160, 48),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _indexAtual == 3 ? "FINALIZAR" : "PRÓXIMO",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
