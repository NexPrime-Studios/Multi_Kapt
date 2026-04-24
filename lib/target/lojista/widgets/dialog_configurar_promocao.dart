import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/item_mercado.dart';
import '../../../services/lojista/lojista_provider.dart';

class DialogConfigurarPromocao extends StatefulWidget {
  final ItemMercado item;
  const DialogConfigurarPromocao({super.key, required this.item});

  @override
  State<DialogConfigurarPromocao> createState() =>
      _DialogConfigurarPromocaoState();
}

class _DialogConfigurarPromocaoState extends State<DialogConfigurarPromocao> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _precoController;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    _precoController = TextEditingController(
      text: widget.item.precoPromocional?.toStringAsFixed(2) ?? "",
    );
    _dataInicio = widget.item.inicioPromocao ?? DateTime.now();
    _dataFim = widget.item.fimPromocao;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        // Forçamos uma largura máxima fixa para o diálogo inteiro
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Stack(
          children: [
            // Container Branco Principal
            Container(
              margin: const EdgeInsets.only(
                  top: 12, right: 12), // Espaço para o "X"
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                // O ScrollView agora envolve tudo para garantir que nada transborde
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Configurar Promoção",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Resumo do Produto (Usando Layout flexível para evitar Right Overflow)
                      _buildProductSummary(),

                      const SizedBox(height: 20),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _precoController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: "Preço Promocional",
                                prefixText: "R\$ ",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.orange.withOpacity(0.05),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Obrigatório";
                                }
                                final preco =
                                    double.tryParse(value.replaceAll(',', '.'));
                                if (preco == null) return "Inválido";
                                if (preco >= widget.item.preco) {
                                  return "Menor que original";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Botão de Data (Design que não quebra)
                            _buildDateSelector(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("SALVAR",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botão Fechar (X) - Posicionado de forma independente
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSummary() {
    return Container(
      width: double.infinity, // Força o container a ocupar a largura do dialog
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Evita que a row tente ser infinita
        children: [
          // IMAGEM: Tamanho fixo para não empurrar o layout
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.item.produtoImagem.isNotEmpty
                ? Image.network(
                    widget.item.produtoImagem,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image)),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image)),
          ),
          const SizedBox(width: 12),

          // DADOS: O uso do Flexible/Expanded aqui é OBRIGATÓRIO para evitar overflow
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item.produtoNome,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // Corta o texto com "..."
                ),
                const SizedBox(height: 2),
                Text(
                  "Original: R\$ ${widget.item.preco.toStringAsFixed(2)}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selecionarPeriodo,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              // Impede que o texto da data empurre a borda para fora
              child: Text(
                _dataFim == null
                    ? "Definir Período"
                    : "${DateFormat('dd/MM').format(_dataInicio!)} - ${DateFormat('dd/MM').format(_dataFim!)}",
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Métodos _selecionarPeriodo e _salvar permanecem iguais...
  Future<void> _selecionarPeriodo() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dataInicio != null && _dataFim != null
          ? DateTimeRange(start: _dataInicio!, end: _dataFim!)
          : null,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      if (picked.end.difference(picked.start).inDays > 30) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Máximo 30 dias!")));
        }
        return;
      }
      setState(() {
        _dataInicio = picked.start;
        _dataFim = picked.end;
      });
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate() && _dataFim != null) {
      final novoItem = widget.item.copyWith(
        precoPromocional:
            double.parse(_precoController.text.replaceAll(',', '.')),
        inicioPromocao: _dataInicio,
        fimPromocao: _dataFim,
      );
      await context.read<LojistaProvider>().atualizarItem(novoItem);
      if (mounted) Navigator.pop(context);
    }
  }
}
