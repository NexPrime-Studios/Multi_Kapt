import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static final Map<String, Map<String, dynamic>> _cache = {};

  late final GenerativeModel _model;
  bool _isInitialized = false;

  GeminiService() {
    _inicializar();
  }

  void _inicializar() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
    if (apiKey.isEmpty) return;

    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
      systemInstruction: Content.system(
          "Você é um classificador de produtos especializado em EAN/Código de barras. "
          "Sua saída deve ser EXCLUSIVAMENTE um JSON válido. "
          "Campos: "
          "nome: [lista com 3 variações de nomes comerciais], "
          "marca: 'string', "
          "categoria: 'string', "
          "descricao: [lista com 3 descrições detalhadas, técnicas e informativas sobre o produto], "
          "confianca: número de 0 a 1. "
          "Não explique nada e não inclua texto fora do JSON."),
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
      ),
    );
    _isInitialized = true;
  }

  Future<Map<String, dynamic>?> buscarDadosProduto(String barcode) async {
    // 1. Verifica se já está no cache
    if (_cache.containsKey(barcode)) {
      return _cache[barcode];
    }

    if (!_isInitialized) return null;

    try {
      final query = Uri.encodeComponent("$barcode produto Brasil");
      final url = Uri.parse("https://duckduckgo.com/html/?q=$query");
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      String resultadosWeb = "";
      if (response.statusCode == 200) {
        final matches = RegExp(r'<a[^>]*>(.*?)</a>').allMatches(response.body);
        resultadosWeb = matches.map((m) => m.group(1) ?? "").take(8).join('\n');
      }

      final prompt = "Código: $barcode\nResultados Web:\n$resultadosWeb";
      final aiResponse = await _model.generateContent([Content.text(prompt)]);

      final rawJson = aiResponse.text
          ?.replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      if (rawJson == null) return null;

      final parsed = jsonDecode(rawJson) as Map<String, dynamic>;

      _cache[barcode] = parsed;
      return parsed;
    } catch (e) {
      debugPrint("Erro Gemini: $e");
      return null;
    }
  }

  static void limparCache() {
    _cache.clear();
    debugPrint("💡 Cache da IA limpo com sucesso.");
  }
}
