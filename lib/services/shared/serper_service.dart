import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SerperService {
  final String _baseUrl = 'https://google.serper.dev/images';

  Future<List<dynamic>> buscarImagens(String query, {int limite = 16}) async {
    final String? apiKey = dotenv.env['SERPER_API_KEY'];

    if (apiKey == null) {
      throw Exception('Erro: Chave API não encontrada no arquivo chaves.env');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'X-API-KEY': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': query,
          'num': limite,
          'gl': 'br',
          'hl': 'pt-br',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['images'] ?? [];
      } else {
        throw Exception('Falha na busca: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com Serper: $e');
    }
  }
}
