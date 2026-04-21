import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImagemService {
  final _supabase = Supabase.instance.client;

  // Método existente para Logos e Capas de Mercados
  Future<String?> uploadMercadoImageWeb({
    required Uint8List bytes,
    required String mercadoId,
    bool isLogo = true,
  }) async {
    if (bytes.isEmpty) return null;

    try {
      final int targetWidth = isLogo ? 300 : 900;
      final result =
          await _comprimirImagem(bytes, targetWidth, isLogo ? 80 : 70);

      final folder = isLogo ? 'logos' : 'capas';
      final path = '$mercadoId/$folder/foto.${result.extension}';

      // Remove versões antigas para evitar lixo no storage
      await _supabase.storage.from('mercados').remove([
        '$mercadoId/$folder/foto.jpg',
        '$mercadoId/$folder/foto.webp',
      ]);

      await _supabase.storage.from('mercados').uploadBinary(
            path,
            result.data,
            fileOptions: FileOptions(
              cacheControl: '31536000',
              upsert: true,
              contentType: result.contentType,
            ),
          );

      final url = _supabase.storage.from('mercados').getPublicUrl(path);
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('Erro ao fazer upload de imagem do mercado: $e');
      return null;
    }
  }

  // NOVO MÉTODO: Upload para o bucket 'produtos'
  Future<String?> uploadProdutoImage({
    required Uint8List bytes,
    required String produtoId,
  }) async {
    if (bytes.isEmpty) return null;

    try {
      // Para produtos, usamos uma largura padrão de 600px (equilíbrio entre qualidade e peso)
      final result = await _comprimirImagem(bytes, 600, 75);

      // O caminho será organizado pelo ID do produto
      final path = '$produtoId/foto.${result.extension}';

      // Remove arquivos anteriores do mesmo produto
      await _supabase.storage.from('produtos').remove([
        '$produtoId/foto.jpg',
        '$produtoId/foto.webp',
      ]);

      await _supabase.storage.from('produtos').uploadBinary(
            path,
            result.data,
            fileOptions: FileOptions(
              cacheControl: '31536000',
              upsert: true,
              contentType: result.contentType,
            ),
          );

      final url = _supabase.storage.from('produtos').getPublicUrl(path);

      // Retornamos a URL com timestamp para evitar que o cache do navegador mostre a imagem antiga
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('Erro ao fazer upload de imagem do produto: $e');
      return null;
    }
  }

  // Método auxiliar privado para evitar repetição de código de compressão
  Future<_CompressResult> _comprimirImagem(
      Uint8List bytes, int width, int quality) async {
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: width,
        format: CompressFormat.webp,
      );
      return _CompressResult(compressed, 'webp', 'image/webp');
    } catch (e) {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: width,
        format: CompressFormat.jpeg,
      );
      return _CompressResult(compressed, 'jpg', 'image/jpeg');
    }
  }
}

// Classe auxiliar para o retorno da compressão
class _CompressResult {
  final Uint8List data;
  final String extension;
  final String contentType;

  _CompressResult(this.data, this.extension, this.contentType);
}
