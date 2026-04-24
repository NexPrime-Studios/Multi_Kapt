import 'package:flutter/material.dart';

class CampoSenhaWidget extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final IconData? icon;
  final bool enabled;

  const CampoSenhaWidget({
    super.key,
    this.label = "Senha",
    required this.controller,
    this.validator,
    this.icon = Icons.lock_outline,
    this.enabled = true,
  });

  @override
  State<CampoSenhaWidget> createState() => _CampoSenhaWidgetState();
}

class _CampoSenhaWidgetState extends State<CampoSenhaWidget> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscureText,
        maxLines: 1,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: widget.icon != null
              ? Icon(widget.icon, color: theme.colorScheme.secondary)
              : null,
          // Ícone de sufixo (o olhinho)
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
        validator: widget.enabled
            ? (widget.validator ??
                (v) => (v == null || v.isEmpty) ? "Campo obrigatório" : null)
            : null,
      ),
    );
  }
}
