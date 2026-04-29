import 'package:flutter/material.dart';
import '../../../../models/mercado.dart'; // Importe para acessar PagamentosAceitos
import '../../../../enums/produto_enums.dart';
import '../../widgets/campo_formulario.dart';

class EtapaRegras extends StatefulWidget {
  final Map<String, TextEditingController> controllers;
  final List<CategoriaProduto> categorias;
  final List<PagamentosAceitos> pagamentos;

  const EtapaRegras({
    super.key,
    required this.controllers,
    required this.categorias,
    required this.pagamentos,
  });

  @override
  State<EtapaRegras> createState() => _EtapaRegrasState();
}

class _EtapaRegrasState extends State<EtapaRegras> {
  final List<PagamentosAceitos> _opcoesPagamento = PagamentosAceitos.values;

  String _formatarNomePagamento(PagamentosAceitos pag) {
    switch (pag) {
      case PagamentosAceitos.dinheiro:
        return 'Dinheiro';
      case PagamentosAceitos.cartao:
        return 'Cartão';
      case PagamentosAceitos.pix:
        return 'Pix';
      case PagamentosAceitos.vale:
        return 'Vale Refeição';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha 1: Taxa e Mínimo
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoFormulario(
                controller: widget.controllers['taxa']!,
                titulo: "Taxa de Entrega",
                label: "0.00",
                icone: Icons.delivery_dining,
                isNumero: true,
                validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CampoFormulario(
                controller: widget.controllers['minimo']!,
                titulo: "Pedido Mínimo",
                label: "0.00",
                icone: Icons.shopping_bag_outlined,
                isNumero: true,
                validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            "* Só será aplicada taxa de entrega se o valor do pedido for menor que o valor mínimo.",
            style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontStyle: FontStyle.italic),
          ),
        ),

        // Linha 2: Tempo Médio (Largura total agora)
        CampoFormulario(
          controller: widget.controllers['tempo']!,
          titulo: "Tempo Médio",
          label: "30-50 min",
          icone: Icons.timer,
          validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
        ),

        const SizedBox(height: 10),

        // Seção: Pagamentos (Abaixo do Tempo Médio)
        const Text(
          "Pagamentos aceitos",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 14),
        ),
        const SizedBox(height: 10),
        FormField<List<PagamentosAceitos>>(
          initialValue: widget.pagamentos,
          validator: (value) {
            if (widget.pagamentos.isEmpty) {
              return "Selecione ao menos uma forma de pagamento";
            }
            return null;
          },
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _opcoesPagamento.map((pag) {
                    final bool selecionada = widget.pagamentos.contains(pag);
                    return FilterChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        _formatarNomePagamento(pag),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                      selected: selecionada,
                      selectedColor: Colors.greenAccent.withOpacity(0.5),
                      checkmarkColor: Colors.black,
                      onSelected: (val) {
                        setState(() {
                          val
                              ? widget.pagamentos.add(pag)
                              : widget.pagamentos.remove(pag);
                        });
                        state.didChange(widget.pagamentos);
                      },
                    );
                  }).toList(),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Seção: Categorias
        const Text(
          "Selecione as categorias que o seu mercado oferece",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              fontSize: 14),
        ),
        const SizedBox(height: 12),
        FormField<List<CategoriaProduto>>(
          initialValue: widget.categorias,
          validator: (_) {
            if (widget.categorias.isEmpty) {
              return "Selecione ao menos uma categoria";
            }
            return null;
          },
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: CategoriaProduto.values.map((cat) {
                    final bool selecionada = widget.categorias.contains(cat);
                    return FilterChip(
                      label: Text(cat.name,
                          style: const TextStyle(color: Colors.black)),
                      selected: selecionada,
                      onSelected: (val) {
                        setState(() {
                          val
                              ? widget.categorias.add(cat)
                              : widget.categorias.remove(cat);
                        });
                        state.didChange(widget.categorias);
                      },
                    );
                  }).toList(),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
