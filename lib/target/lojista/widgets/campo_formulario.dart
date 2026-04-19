import 'package:flutter/material.dart';

class CampoFormulario extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String titulo;
  final IconData icone;
  final bool isNumero;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;

  const CampoFormulario({
    super.key,
    required this.controller,
    required this.label,
    required this.titulo,
    required this.icone,
    this.isNumero = false,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            onChanged: onChanged,
            keyboardType: isNumero
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: label,
              prefixIcon: Icon(icone),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }
}
