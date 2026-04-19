import 'package:flutter/material.dart';
import 'dialog_substituicao_widget.dart';

class ItemColetaWidget extends StatelessWidget {
  final int index;
  final dynamic item;
  final bool? status;
  final Function(int, bool?) onStatusChanged;
  final Function(int, double) onValueUpdated;
  final VoidCallback onSolicitarScanSubstituicao;

  const ItemColetaWidget({
    super.key,
    required this.index,
    required this.item,
    required this.status,
    required this.onStatusChanged,
    required this.onValueUpdated,
    required this.onSolicitarScanSubstituicao,
  });

  @override
  Widget build(BuildContext context) {
    final bool isChecked = status == true;
    final bool isError = status == false;
    final bool ehSubstituto =
        item['substituido'] == true; // Identifica o novo item azul

    // Definição das cores baseada no estado
    Color accentColor = Colors.grey[300]!;
    if (isChecked) accentColor = Colors.green;
    if (isError) accentColor = Colors.red;
    if (ehSubstituto) accentColor = Colors.blue; // Cor azul para substitutos

    final String unidade = item['unidade']?.toString().toLowerCase() ?? 'un';
    final bool ehPeso = unidade == 'kg';

    final dynamic qtdParaExibir =
        (item['quantidade_coletada'] != null && item['quantidade_coletada'] > 0)
            ? item['quantidade_coletada']
            : item['quantidade'];

    final String qtdFormatada = _formatarNumero(qtdParaExibir);

    final String precoFormatado =
        (double.tryParse(item['preco']?.toString() ?? '0.0') ?? 0.0)
            .toStringAsFixed(2)
            .replaceAll('.', ',');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        // Fundo azul clarinho se for substituto, senão branco
        color: ehSubstituto ? Colors.blue[50]?.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
        border: Border.all(
          color: status != null
              ? accentColor.withOpacity(0.5)
              : (ehSubstituto ? Colors.blue[200]! : Colors.transparent),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                  width: 6,
                  color: status == null && !ehSubstituto
                      ? Colors.grey[200]
                      : accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ehSubstituto)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text("PRODUTO SUBSTITUTO",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      Text(
                        item['produto_nome'] ?? item['nome'] ?? 'Produto',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          decoration:
                              isError ? TextDecoration.lineThrough : null,
                          color: isError
                              ? Colors.grey
                              : (ehSubstituto
                                  ? Colors.blue[900]
                                  : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildQuantidadeBadge(context, ehPeso, qtdFormatada,
                              unidade, ehSubstituto),
                          const SizedBox(width: 12),
                          Text("R\$ $precoFormatado",
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isError
                                      ? Colors.grey
                                      : (ehSubstituto
                                          ? Colors.blue
                                          : Colors.green[700]))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(item['codigo_barras'] ?? 'S/ Código',
                          style: TextStyle(
                              fontSize: 11,
                              color: ehSubstituto
                                  ? Colors.blue[300]
                                  : Colors.grey[500],
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
              Container(
                width: 70,
                decoration: BoxDecoration(
                    color: ehSubstituto
                        ? Colors.blue[50]?.withOpacity(0.3)
                        : Colors.grey[50]),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isChecked)
                      Icon(Icons.check_circle, color: accentColor, size: 30)
                    else ...[
                      IconButton(
                        icon: Icon(isError ? Icons.error : Icons.error_outline,
                            color: isError ? Colors.red : Colors.grey[400],
                            size: 32),
                        onPressed: ehSubstituto
                            ? null
                            : () => _handleFaltaClick(context),
                      ),
                      Text(
                          isError
                              ? "EM FALTA"
                              : (ehSubstituto ? "OK" : "FALTA"),
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isError
                                  ? Colors.red
                                  : (ehSubstituto
                                      ? Colors.blue
                                      : Colors.grey))),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ATUALIZADOS ---

  Widget _buildQuantidadeBadge(BuildContext context, bool ehPeso, String qtd,
      String unidade, bool ehSubstituto) {
    final bool jaPesei =
        item['quantidade_coletada'] != null && item['quantidade_coletada'] > 0;

    return InkWell(
      onTap: ehPeso ? () => _mostrarDialogAjustePesagem(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ehSubstituto
              ? Colors.blue[100]?.withOpacity(0.3)
              : (jaPesei
                  ? Colors.green[50]
                  : (ehPeso ? Colors.orange[50] : Colors.blueGrey[50])),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: ehSubstituto
                  ? Colors.blue[200]!
                  : (jaPesei
                      ? Colors.green[200]!
                      : (ehPeso
                          ? Colors.orange[200]!
                          : Colors.blueGrey[100]!))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("$qtd $unidade",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: ehSubstituto ? Colors.blue[900] : Colors.black87)),
            if (ehPeso) ...[
              const SizedBox(width: 4),
              Icon(Icons.scale_outlined,
                  size: 16,
                  color: ehSubstituto ? Colors.blue : Colors.orange[900]),
            ],
          ],
        ),
      ),
    );
  }

  // O restante dos métodos (_handleFaltaClick, _formatarNumero, _mostrarDialogAjustePesagem)
  // permanecem os mesmos da sua versão anterior.
  void _handleFaltaClick(BuildContext context) {
    if (status == false) {
      onStatusChanged(index, null);
      return;
    }
    final bool aceitaSubstituicao = item['pode_substituir'] == true;
    if (aceitaSubstituicao) {
      showDialog(
        context: context,
        builder: (context) => DialogSubstituicaoWidget(
          item: item,
          onApenasFalta: () => onStatusChanged(index, false),
          onBiparNovo: onSolicitarScanSubstituicao,
        ),
      );
    } else {
      onStatusChanged(index, false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Cliente não aceita substituição para este item.")),
      );
    }
  }

  String _formatarNumero(dynamic valorRaw) {
    if (valorRaw == null) return "0";
    double valor = double.tryParse(valorRaw.toString()) ?? 0.0;
    return (valor == valor.toInt())
        ? valor.toInt().toString()
        : valor
            .toStringAsFixed(3)
            .replaceAll(RegExp(r'0*$'), '')
            .replaceAll(RegExp(r'\.$'), '');
  }

  void _mostrarDialogAjustePesagem(BuildContext context) {
    final TextEditingController controller = TextEditingController(
        text: (item['quantidade_coletada'] ?? item['quantidade'] ?? '0.0')
            .toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Pesar Produto"),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: "Peso Final (Balança)",
            suffixText: "kg",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              final novaQtd =
                  double.tryParse(controller.text.replaceAll(',', '.'));
              if (novaQtd != null) {
                onValueUpdated(index, novaQtd);
                Navigator.pop(context);
              }
            },
            child: const Text("CONFIRMAR PESO",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
