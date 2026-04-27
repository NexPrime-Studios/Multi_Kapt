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
  final IconData? icon;
  final bool enabled;
  final TextCapitalization capitalization;

  const CampoTextoWidget({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.type = TextInputType.text,
    this.formatters,
    this.validator,
    this.maxLines = 1,
    this.icon,
    this.enabled = true,
    this.capitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        inputFormatters: formatters,
        textCapitalization: capitalization,
        maxLines: maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: theme.colorScheme.secondary)
              : null,
        ),
        validator: enabled
            ? (validator ??
                (v) => v != null && v.isEmpty ? "Campo obrigatório" : null)
            : null,
      ),
    );
  }
}

/// Formatador para forçar texto em MAIÚSCULO
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

/// Formatador para forçar texto em minúsculo
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}
