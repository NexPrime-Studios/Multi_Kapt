import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final bool autofocus;
  final FocusNode? focusNode;

  const SearchBarWidget({
    super.key,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.controller,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: "Buscar mercados...",
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          prefixIcon: Icon(Icons.search, color: cores.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
