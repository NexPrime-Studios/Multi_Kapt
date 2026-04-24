import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brasil_fields/brasil_fields.dart';

class CampoCepWidget extends StatelessWidget {
  final TextEditingController controller;

  const CampoCepWidget({super.key, required this.controller});

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
          CepInputFormatter(),
        ],
        decoration: InputDecoration(
          labelText: "CEP",
          prefixIcon: Icon(
            Icons.location_on_outlined,
            color: theme.colorScheme.secondary,
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return "CEP obrigatório";
          if (v.length < 9) return "CEP incompleto";
          return null;
        },
      ),
    );
  }
}
