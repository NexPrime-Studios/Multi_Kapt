import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImagemService {
  final _supabase = Supabase.instance.client;

  Future<String?> uploadMercadoImageWeb({
    required Uint8List bytes,
    required String mercadoId,
    bool isLogo = true,
  }) async {
    if (bytes.isEmpty) return null;

    try {
      final int targetWidth = isLogo ? 300 : 900;

      Uint8List compressedBytes;
      String extension;
      String contentType;

      try {
        compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          quality: isLogo ? 80 : 70,
          minWidth: targetWidth,
          format: CompressFormat.webp,
        );

        extension = 'webp';
        contentType = 'image/webp';
      } catch (e) {
        compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          quality: isLogo ? 80 : 70,
          minWidth: targetWidth,
          format: CompressFormat.jpeg,
        );

        extension = 'jpg';
        contentType = 'image/jpeg';
      }

      final folder = isLogo ? 'logos' : 'capas';

      await _supabase.storage.from('mercados').remove([
        '$mercadoId/$folder/foto.jpg',
        '$mercadoId/$folder/foto.webp',
      ]);

      final path = '$mercadoId/$folder/foto.$extension';

      await _supabase.storage.from('mercados').uploadBinary(
            path,
            compressedBytes,
            fileOptions: FileOptions(
              cacheControl: '31536000',
              upsert: true,
              contentType: contentType,
            ),
          );

      final url = _supabase.storage.from('mercados').getPublicUrl(path);

      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('Erro: $e');
      return null;
    }
  }
}
