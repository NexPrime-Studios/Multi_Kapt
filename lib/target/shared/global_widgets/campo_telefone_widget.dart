import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brasil_fields/brasil_fields.dart';

class CampoTelefoneWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const CampoTelefoneWidget({
    super.key,
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          TelefoneInputFormatter(),
        ],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            Icons.phone_outlined,
            color: theme.colorScheme.secondary,
          ),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Campo obrigatório" : null,
      ),
    );
  }
}
