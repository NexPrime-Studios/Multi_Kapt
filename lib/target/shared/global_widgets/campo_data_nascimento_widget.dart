import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brasil_fields/brasil_fields.dart';

class CampoDataNascimentoWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const CampoDataNascimentoWidget({
    super.key,
    required this.controller,
    this.label = "Data de Nascimento",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          DataInputFormatter(),
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: "Ex: 10/05/1995",
          prefixIcon: Icon(
            Icons.calendar_today_outlined,
            color: theme.colorScheme.secondary,
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) {
            return "Campo obrigatório";
          }
          if (v.length < 10) {
            return "Informe a data completa";
          }
          return null;
        },
      ),
    );
  }
}
