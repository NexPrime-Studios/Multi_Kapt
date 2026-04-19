import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/campo_formulario.dart';

class EtapaGeral extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final Uint8List? logoBytes;
  final Uint8List? capaBytes;
  final Function(Uint8List) onLogoSelecionado;
  final Function(Uint8List) onCapaSelecionada;

  const EtapaGeral({
    super.key,
    required this.controllers,
    this.logoBytes,
    this.capaBytes,
    required this.onLogoSelecionado,
    required this.onCapaSelecionada,
  });

  Future<void> _pickImage(bool isLogo) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        if (isLogo) {
          onLogoSelecionado(bytes);
        } else {
          onCapaSelecionada(bytes);
        }
      }
    } catch (e) {
      debugPrint("Erro ao selecionar imagem: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampoFormulario(
          controller: controllers['nomeDono']!,
          titulo: "Seu Nome",
          label: "Digite seu nome completo",
          icone: Icons.person_outline,
          validator: (value) =>
              value == null || value.isEmpty ? "Campo obrigatório" : null,
        ),
        CampoFormulario(
          controller: controllers['nome']!,
          titulo: "Nome Fantasia",
          label: "Ex: MERCADO TOP",
          icone: Icons.store,
          onChanged: (value) {
            controllers['nome']!.value = controllers['nome']!.value.copyWith(
                  text: value.toUpperCase(),
                  selection: TextSelection.collapsed(offset: value.length),
                );
          },
          validator: (value) =>
              value == null || value.isEmpty ? "Campo obrigatório" : null,
        ),
        CampoFormulario(
          controller: controllers['tel']!,
          titulo: "WhatsApp",
          label: "(00) 00000-0000",
          icone: Icons.phone,
          isNumero: true,
          validator: (value) =>
              value == null || value.isEmpty ? "Campo obrigatório" : null,
        ),
        const SizedBox(height: 24),
        const Text(
          "Identidade Visual",
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePicker(
              label: "Logo",
              bytes: logoBytes,
              onTap: () => _pickImage(true),
              width: 100,
              height: 100,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildImagePicker(
                label: "Imagem de Capa",
                bytes: capaBytes,
                onTap: () => _pickImage(false),
                width: double.infinity,
                height: 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Toque nos quadros acima para escolher as fotos.",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildImagePicker({
    required String label,
    required Uint8List? bytes,
    required VoidCallback onTap,
    required double width,
    required double height,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: (bytes != null && bytes.isNotEmpty)
                ? Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    width: width,
                    height: height,
                    gaplessPlayback: true,
                    key: ValueKey(bytes.hashCode),
                  )
                : const Icon(Icons.add_a_photo_outlined, color: Colors.white54),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}
