import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/funcionario_provider.dart';
import '../../../services/funcionario_service.dart';
import '../../../models/funcionario.dart';
import '../widgets/card_pedido_funcionario.dart';
import '../../../app_theme.dart';

class PedidosFuncionarioPage extends StatefulWidget {
  final Function(String statusAcao) aoAceitarPedido;
  const PedidosFuncionarioPage({super.key, required this.aoAceitarPedido});

  @override
  State<PedidosFuncionarioPage> createState() => _PedidosFuncionarioPageState();
}

class _PedidosFuncionarioPageState extends State<PedidosFuncionarioPage> {
  final _service = FuncionarioService();
  Funcionario? _funcionarioLogado;
  bool _carregandoPerfil = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfilFuncionario();
  }

  Future<void> _carregarPerfilFuncionario() async {
    try {
      final provider = context.read<FuncionarioProvider>();
      final dados =
          await _service.buscarDadosFuncionario(provider.funcionarioId ?? '');
      if (mounted) {
        setState(() {
          _funcionarioLogado = dados;
          _carregandoPerfil = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar perfil: $e");
    }
  }

  Future<void> _processarAcaoPedido(
      String id, String statusAtual, Map<String, dynamic> dadosPedido) async {
    final funcProv = context.read<FuncionarioProvider>();

    // CORREÇÃO 1: Verificação de segurança sem usar "!"
    if (_funcionarioLogado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Erro: Dados do funcionário não carregados.")),
      );
      return;
    }

    try {
      if (statusAtual == 'pendente') {
        if (funcProv.estaOcupado) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Você já possui um pedido em coleta ou entrega!"),
                backgroundColor: Colors.orange),
          );
          return;
        }

        await _service.atualizarStatusPedido(
          pedidoId: id,
          novoStatus: 'preparando',
          funcionarioNome: _funcionarioLogado!.nome,
          funcionarioCodigo: _funcionarioLogado!.codigoSenha,
        );

        widget.aoAceitarPedido('pendente');
      } else if (statusAtual == 'pronto') {
        // CORREÇÃO 2: Verificação adicional para entregadores
        if (funcProv.estaOcupado) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Você já possui um pedido ativo!"),
                backgroundColor: Colors.orange),
          );
          return;
        }

        await _service.atualizarStatusPedido(
          pedidoId: id,
          novoStatus: 'saiu_para_entrega',
          funcionarioNome: _funcionarioLogado!.nome,
          funcionarioCodigo: _funcionarioLogado!.codigoSenha,
        );

        widget.aoAceitarPedido('pronto');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erro ao processar: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final funcionarioProv = context.watch<FuncionarioProvider>();

    if (_carregandoPerfil || _funcionarioLogado == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String minhaFuncao = _funcionarioLogado!.cargo.name;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Pedidos Disponíveis",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.streamPedidos(funcionarioProv.mercadoId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final todosPedidos = snapshot.data ?? [];

          // FILTRAGEM APENAS PARA EXIBIÇÃO NA LISTA
          final pedidosFiltrados = todosPedidos.where((p) {
            final status = p['status'];

            bool verPendentes =
                (minhaFuncao == 'coletor' || minhaFuncao == 'ambos') &&
                    status == 'pendente';

            bool verProntos =
                (minhaFuncao == 'entregador' || minhaFuncao == 'ambos') &&
                    status == 'pronto';

            return verPendentes || verProntos;
          }).toList();

          if (pedidosFiltrados.isEmpty) {
            return const Center(
                child: Text("Nenhum pedido disponível para seu cargo"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidosFiltrados.length,
            itemBuilder: (context, index) {
              final pedido = pedidosFiltrados[index];
              return CardPedidoFuncionario(
                pedido: pedido,
                onAvancar: (id, status, dados) =>
                    _processarAcaoPedido(id, status, dados),
              );
            },
          );
        },
      ),
    );
  }
}
