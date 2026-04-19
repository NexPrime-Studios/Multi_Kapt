import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../../models/funcionario.dart';
import '../../../services/lojista_provider.dart';

class DialogCadastroFuncionario extends StatefulWidget {
  final String mercadoId;
  final Funcionario? funcionarioParaEditar;

  const DialogCadastroFuncionario({
    super.key,
    required this.mercadoId,
    this.funcionarioParaEditar,
  });

  @override
  State<DialogCadastroFuncionario> createState() =>
      _DialogCadastroFuncionarioState();
}

class _DialogCadastroFuncionarioState extends State<DialogCadastroFuncionario> {
  final _nomeController = TextEditingController();
  final _codigoSenhaController = TextEditingController();

  // Ajustado para o novo padrão: Operador como padrão inicial
  CargoAcesso _cargoSelecionado = CargoAcesso.operador;

  bool _salvando = false;
  bool _mostrarSucesso = false;
  String? _idGerado;

  @override
  void initState() {
    super.initState();
    if (widget.funcionarioParaEditar != null) {
      _nomeController.text = widget.funcionarioParaEditar!.nome;
      _codigoSenhaController.text = widget.funcionarioParaEditar!.codigoSenha;

      // O modelo Funcionario agora já entrega o enum 'cargo' diretamente
      _cargoSelecionado = widget.funcionarioParaEditar!.cargo;
    }
  }

  bool _validarCodigoSenha(String valor) {
    if (valor.length < 4 || valor.length > 8) return false;
    final apenasLetrasNumeros = RegExp(r'^[A-Z0-9]+$').hasMatch(valor);
    final temLetra = RegExp(r'[A-Z]').hasMatch(valor);
    final temNumero = RegExp(r'[0-9]').hasMatch(valor);
    return apenasLetrasNumeros && temLetra && temNumero;
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final bool editando = widget.funcionarioParaEditar != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(32),
        child: _mostrarSucesso
            ? _buildSucesso(cores)
            : _buildCorpoPrincipal(cores, editando),
      ),
    );
  }

  Widget _buildCorpoPrincipal(ColorScheme cores, bool editando) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              !editando ? "Novo Integrante" : "Configurações",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  TextField(
                    controller: _nomeController,
                    enabled: !editando,
                    decoration: InputDecoration(
                        labelText: "Nome Completo",
                        filled: editando,
                        border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _codigoSenhaController,
                    enabled: !editando,
                    onChanged: (val) {
                      _codigoSenhaController.value =
                          _codigoSenhaController.value.copyWith(
                        text: val.toUpperCase(),
                        selection: TextSelection.collapsed(offset: val.length),
                      );
                    },
                    decoration: InputDecoration(
                        labelText: "Código Senha (Ex: ABC123)",
                        filled: editando,
                        border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  // Dropdown Corrigido
                  DropdownButtonFormField<CargoAcesso>(
                    value: _cargoSelecionado,
                    items: CargoAcesso.values.map((cargo) {
                      return DropdownMenuItem(
                        value: cargo,
                        child: Text(cargo.label), // Usa a label da Extension
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _cargoSelecionado = val);
                      }
                    },
                    decoration: const InputDecoration(
                        labelText: "Nível de Acesso",
                        border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            if (editando) ...[
              const SizedBox(width: 30),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    QrImageView(
                      data:
                          'vincular:${widget.mercadoId}:${widget.funcionarioParaEditar!.id}',
                      size: 140,
                      foregroundColor: cores.primary,
                    ),
                    const SizedBox(height: 10),
                    _buildCodigoManualBox(
                        widget.funcionarioParaEditar!.codigoSenha),
                    const Text("Código para Vínculo Manual",
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (editando)
              IconButton(
                onPressed: _confirmarExclusao,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _salvando ? null : _processarSalvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: cores.primary,
                minimumSize: const Size(150, 50),
              ),
              child: _salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(!editando ? "CADASTRAR" : "SALVAR ALTERAÇÕES",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSucesso(ColorScheme cores) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 60),
        const SizedBox(height: 16),
        const Text("Funcionário Registrado!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        if (_idGerado != null)
          QrImageView(
              data: 'vincular:${widget.mercadoId}:$_idGerado',
              size: 180,
              foregroundColor: cores.primary),
        const SizedBox(height: 10),
        _buildCodigoManualBox(_codigoSenhaController.text),
        const Text("Código para Vínculo Manual",
            style: TextStyle(
                fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CONCLUÍDO")),
        ),
      ],
    );
  }

  Widget _buildCodigoManualBox(String codigo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blueGrey[100]!)),
      child: Text(
        codigo.toUpperCase(),
        style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 3,
            color: Colors.blueGrey,
            fontFamily: 'monospace'),
      ),
    );
  }

  Future<void> _processarSalvar() async {
    final nome = _nomeController.text.trim();
    final codigo = _codigoSenhaController.text.trim().toUpperCase();
    final provider = context.read<LojistaProvider>();

    if (nome.isEmpty || codigo.isEmpty || !_validarCodigoSenha(codigo)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Dados inválidos. Verifique a senha (letras+números, 4-8 dígitos).")));
      return;
    }

    setState(() => _salvando = true);
    try {
      final id = await provider.salvarFuncionarioCompleto(
        id: widget.funcionarioParaEditar?.id,
        mercadoId: widget.mercadoId,
        codigoId: codigo,
        nome: nome,
        // Enviamos o .name do enum para o banco (ex: 'gerente')
        funcao: _cargoSelecionado.name,
        ativo: widget.funcionarioParaEditar?.ativo ?? true,
      );

      if (widget.funcionarioParaEditar == null) {
        setState(() {
          _idGerado = id;
          _mostrarSucesso = true;
          _salvando = false;
        });
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmarExclusao() {
    final provider = context.read<LojistaProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remover funcionário?"),
        content: const Text("Esta ação não pode ser desfeita."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCELAR")),
          TextButton(
              onPressed: () async {
                try {
                  await provider
                      .excluirFuncionario(widget.funcionarioParaEditar!.id);
                  if (mounted) {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erro ao excluir: $e")),
                    );
                  }
                }
              },
              child:
                  const Text("EXCLUIR", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
