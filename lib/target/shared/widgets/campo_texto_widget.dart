import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CampoTextoWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType type;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const CampoTextoWidget({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.type = TextInputType.text,
    this.formatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        inputFormatters: formatters,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator ?? (v) => v!.isEmpty ? "Campo obrigatório" : null,
      ),
    );
  }
}
