import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

class ChatBotService {
  ChatBotService({http.Client? client})
      : _client = client ?? http.Client(),
        _baseUrl = ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<String> sendMessage({
    required String message,
    required String userId,
    required String microfinancieraId,
    String? userName,
    List<Map<String, String>> history = const [],
  }) async {
    final uri = Uri.parse('$_baseUrl/api/ai/chat');
    final normalizedHistory = history.isNotEmpty
        ? history
        : [
            {
              'role': 'user',
              'content': message,
            },
          ];

    final payload = <String, dynamic>{
      'userId': userId,
      'microfinancieraId': microfinancieraId,
      'userName': userName,
      'message': message,
      'history': normalizedHistory,
    };

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 400) {
      final responseBody = response.body;
      throw Exception(
        'Error ${response.statusCode} al contactar al backend: $responseBody',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['success'] == true && decoded['answer'] is String) {
      return (decoded['answer'] as String).trim();
    }

    throw Exception(decoded['message'] ?? 'Respuesta inválida del backend.');
  }
}
