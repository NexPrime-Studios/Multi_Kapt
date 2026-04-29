import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ProdutoModel {
  final String nome;
  final String descricao;
  final String marca;
  final String categoria;
  final String ncm;

  ProdutoModel({
    required this.nome,
    required this.descricao,
    required this.marca,
    required this.categoria,
    required this.ncm,
  });

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoModel(
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      marca: json['marca']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      ncm: _validarNcm(json['ncm']?.toString() ?? ''),
    );
  }

  static String _validarNcm(String ncm) {
    final cleanNcm = ncm.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanNcm.length == 8 ? cleanNcm : "00000000";
  }

  Map<String, dynamic> toMap() => {
        "nome": nome,
        "descricao": descricao,
        "marca": marca,
        "categoria": categoria,
        "ncm": ncm,
      };
}

class OpenRouterService {
  final String _apiKey = dotenv.env['OPEN_ROUTER_API_KEY'] ?? "";
  static const String logTag = "OpenRouterService";

  static final Map<String, ProdutoModel> _cache = {};

  /// Método principal de busca
  Future<ProdutoModel?> buscarProdutoPorEan(String barcode) async {
    if (_apiKey.isEmpty) {
      dev.log("❌ Chave API ausente", name: logTag);
      return null;
    }

    if (_cache.containsKey(barcode)) {
      dev.log("📦 Retornando do cache: $barcode", name: logTag);
      return _cache[barcode];
    }

    try {
      dev.log("🌐 Buscando na API OpenRouter: $barcode", name: logTag);

      final response = await http
          .post(
            Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
            headers: {
              "Authorization": "Bearer $_apiKey",
              "Content-Type": "application/json",
              "HTTP-Referer": "https://seusite.com",
            },
            body: jsonEncode({
              "model": "perplexity/sonar",
              "messages": [
                {
                  "role": "system",
                  "content":
                      """Você é um sistema de extração e enriquecimento de dados de produtos baseado em EAN.

Sua tarefa é retornar um JSON VÁLIDO e PARSEÁVEL, sem nenhum texto extra.

REGRAS OBRIGATÓRIAS:
- Retorne SOMENTE JSON puro (sem ``` ou explicações)
- Todas as chaves devem existir
- Nunca retorne null
- Se não souber algum campo, use string vazia ""
- NCM deve conter exatamente 8 dígitos numéricos
- Se não encontrar NCM exato, estime com base na TIPI

DESCRIÇÃO (IMPORTANTE):
- Escreva para um consumidor comum (não técnico)
- Explique para que serve o produto
- Cite usos comuns no dia a dia
- Máximo de 2 frases
- Linguagem simples e natural
- NÃO usar linguagem de propaganda exagerada
- NÃO inventar 
- Sempre comece com o tipo do produto
- Sempre mencione a marca naturalmente
- Sempre inclua pelo menos 1 uso prático

FORMATO EXATO:
{
  "nome": string,
  "descricao": string,
  "marca": string,
  "categoria": string,
  "ncm": string
}"""
                },
                {"role": "user", "content": "EAN: $barcode"}
              ],
              // Menor temperatura = mais precisão/menos criatividade
              "temperature": 0.1,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final produto = _converterJsonParaProduto(response.body);

        if (produto != null) {
          _cache[barcode] = produto;
          dev.log("✅ Produto salvo no cache", name: logTag);
        }

        return produto;
      } else {
        dev.log("⚠️ Erro API: ${response.statusCode}", name: logTag);
        return null;
      }
    } catch (e) {
      dev.log("🚨 Exceção: $e", name: logTag);
      return null;
    }
  }

  static void limparCache() {
    _cache.clear();
    dev.log("🧹 Cache de produtos limpo", name: logTag);
  }

  ProdutoModel? _converterJsonParaProduto(String responseBody) {
    try {
      final Map<String, dynamic> fullData = jsonDecode(responseBody);

      // Segurança na estrutura
      final choices = fullData['choices'];
      if (choices == null || choices is! List || choices.isEmpty) {
        dev.log("⚠️ Resposta sem choices", name: logTag);
        return null;
      }

      final message = choices[0]['message'];
      if (message == null || message['content'] == null) {
        dev.log("⚠️ Resposta sem content", name: logTag);
        return null;
      }

      String content = message['content'].toString();
      content = content
          .replaceAll(RegExp(r'```[a-zA-Z]*'), '')
          .replaceAll('```', '')
          .trim();

      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        dev.log("⚠️ JSON não encontrado na resposta", name: logTag);
        return null;
      }

      final cleanJson = content.substring(jsonStart, jsonEnd + 1);
      final Map<String, dynamic> productMap = jsonDecode(cleanJson);
      final produto = ProdutoModel.fromJson(productMap);

      if (produto.nome.isEmpty || produto.marca.isEmpty) {
        dev.log("⚠️ Produto inválido (nome/marca vazios)", name: logTag);
        return null;
      }

      if (produto.ncm.length != 8) {
        dev.log("⚠️ NCM inválido após parsing", name: logTag);
        return null;
      }

      return produto;
    } catch (e) {
      dev.log("❌ Erro ao converter JSON: $e", name: logTag);
      return null;
    }
  }
}
