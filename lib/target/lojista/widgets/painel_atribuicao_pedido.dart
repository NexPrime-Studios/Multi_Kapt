import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/pedido.dart';
import '../../../services/lojista_provider.dart';

class PainelAtribuicaoPedido extends StatefulWidget {
  final Pedido pedido;

  const PainelAtribuicaoPedido({super.key, required this.pedido});

  @override
  State<PainelAtribuicaoPedido> createState() => _PainelAtribuicaoPedidoState();
}

class _PainelAtribuicaoPedidoState extends State<PainelAtribuicaoPedido> {
  String _filtro = "";

  @override
  Widget build(BuildContext context) {
    final lojistaProvider = Provider.of<LojistaProvider>(context);

    // Filtra funcionários ativos com base na pesquisa
    final funcionarios = lojistaProvider.equipe
        .where((f) =>
            f.ativo && f.nome.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Atribuir Responsável",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: "Buscar por nome...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _filtro = val),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: funcionarios.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: funcionarios.length,
                      itemBuilder: (context, index) {
                        final f = funcionarios[index];
                        // Correção: Comparação usando codigoSenha conforme seu modelo
                        final isSelected =
                            widget.pedido.coletorId == f.codigoSenha;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () => _confirmarAtribuicao(context,
                                lojistaProvider, f.nome, f.codigoSenha),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.orange
                                      : Colors.grey.shade200,
                                  width: 1.5,
                                ),
                                color: isSelected
                                    ? Colors.orange.shade50
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isSelected
                                        ? Colors.orange
                                        : Colors.grey.shade200,
                                    child: Icon(Icons.person,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f.nome,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? Colors.orange.shade900
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                            "Cód: ${f.codigoSenha} • ${f.cargo}",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle,
                                        color: Colors.orange),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Text("Nenhum funcionário encontrado.",
          style: TextStyle(color: Colors.grey)),
    );
  }

  void _confirmarAtribuicao(BuildContext context, LojistaProvider provider,
      String nome, String codigoSenha) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Atribui o funcionário
      await provider.service.atribuirFuncionarioAoPedido(
        widget.pedido.idPedido,
        nome,
        codigoSenha,
      );

      // 2. Atualiza o status para 'preparando' (registra horário automaticamente)
      await provider.service.atualizarStatusPedido(
        widget.pedido.mercadoId,
        widget.pedido.idPedido,
        'preparando',
      );

      if (context.mounted) {
        Navigator.pop(context); // Fecha o loading
        Navigator.pop(context); // Fecha o Popup Principal
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fecha o loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao atualizar: $e")),
        );
      }
    }
  }
}
