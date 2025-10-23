import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/api_config.dart';
import '../../core/logging/app_logger.dart';

class BackendApiDatasource {
  final String baseUrl;

  BackendApiDatasource({String? baseUrl})
    : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final token = await user.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ============ AUTH TEST ============

  /// Probar autenticación con el backend
  Future<Map<String, dynamic>> testAuth() async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/test'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Auth test failed: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ============ USER NOTIFICATIONS ============

  /// Notificar registro de nuevo usuario
  Future<Map<String, dynamic>> notifyUserRegistration({
    required String uid,
    required String email,
    String? displayName,
    required String provider,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/notify-registration'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'provider': provider,
        }),
      );

      AppLogger.info('Notification response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to send notification: ${response.body}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error sending user registration notification: $e');
      rethrow;
    }
  }

  // ============ SCORING ============

  Future<Map<String, dynamic>> calculateScoring({
    required String microfinancieraId,
    required String applicationId,
  }) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/scoring/calculate'),
      headers: headers,
      body: jsonEncode({
        'microfinancieraId': microfinancieraId,
        'applicationId': applicationId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error calculando scoring: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getScoringDetails({
    required String microfinancieraId,
    required String applicationId,
  }) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/api/scoring/$microfinancieraId/$applicationId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error obteniendo scoring: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> makeManualDecision({
    required String microfinancieraId,
    required String applicationId,
    required String result,
    required String comments,
  }) async {
    AppLogger.api(
      'Tomando decisión manual',
      data: {
        'microfinancieraId': microfinancieraId,
        'applicationId': applicationId,
        'result': result,
      },
    );

    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/decisions/manual'),
      headers: headers,
      body: jsonEncode({
        'microfinancieraId': microfinancieraId,
        'applicationId': applicationId,
        'result': result,
        'comments': comments,
      }),
    );

    AppLogger.api(
      'Respuesta decisión manual',
      data: {
        'statusCode': response.statusCode,
        'hasResponse': response.body.isNotEmpty,
      },
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        'Error tomando decisión: ${errorBody['error'] ?? response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDecisionStats({
    required String microfinancieraId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final headers = await _getHeaders();

    final uri = Uri.parse('$baseUrl/api/decisions/stats').replace(
      queryParameters: {
        'microfinancieraId': microfinancieraId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Error obteniendo estadísticas: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getAssignedApplications({
    required String microfinancieraId,
    required String agentId,
    String? status,
  }) async {
    final headers = await _getHeaders();

    final queryParams = {
      'microfinancieraId': microfinancieraId,
      'agentId': agentId,
      if (status != null) 'status': status,
    };

    final uri = Uri.parse(
      '$baseUrl/api/applications/assigned',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Error obteniendo aplicaciones: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['applications'] as List<dynamic>;
  }

  /// Obtener detalle de una aplicación
  Future<Map<String, dynamic>> getApplicationById({
    required String microfinancieraId,
    required String applicationId,
  }) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/api/applications/$microfinancieraId/$applicationId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error obteniendo aplicación: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> takeOwnership({
    required String microfinancieraId,
    required String applicationId,
    required String agentId,
  }) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/applications/take-ownership'),
      headers: headers,
      body: jsonEncode({
        'microfinancieraId': microfinancieraId,
        'applicationId': applicationId,
        'agentId': agentId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error tomando posesión: ${response.body}');
    }
  }

  Future<void> updateApplicationStatus({
    required String microfinancieraId,
    required String applicationId,
    required String status,
    String? reason,
  }) async {
    final headers = await _getHeaders();

    final response = await http.patch(
      Uri.parse(
        '$baseUrl/api/applications/$microfinancieraId/$applicationId/status',
      ),
      headers: headers,
      body: jsonEncode({
        'status': status,
        if (reason != null) 'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error actualizando estado: ${response.body}');
    }
  }

  Future<Map<String, int>> getApplicationStats({
    required String microfinancieraId,
    String? agentId,
  }) async {
    final headers = await _getHeaders();

    final queryParams = {
      'microfinancieraId': microfinancieraId,
      if (agentId != null) 'agentId': agentId,
    };

    final uri = Uri.parse(
      '$baseUrl/api/applications/stats',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Error obteniendo estadísticas: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, int>.from(data['stats'] as Map);
  }

  Future<List<dynamic>> generateReport({
    required String microfinancieraId,
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? agentId,
    String? status,
  }) async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/reports/generate'),
      headers: headers,
      body: jsonEncode({
        'microfinancieraId': microfinancieraId,
        'dateFrom': dateFrom.toIso8601String(),
        'dateTo': dateTo.toIso8601String(),
        if (branchId != null) 'branchId': branchId,
        if (agentId != null) 'agentId': agentId,
        if (status != null) 'status': status,
        'format': 'json',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error generando reporte: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getConversionMetrics({
    required String microfinancieraId,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final headers = await _getHeaders();

    final uri = Uri.parse('$baseUrl/api/reports/metrics').replace(
      queryParameters: {
        'microfinancieraId': microfinancieraId,
        'dateFrom': dateFrom.toIso8601String(),
        'dateTo': dateTo.toIso8601String(),
      },
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Error obteniendo métricas: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['metrics'] as Map<String, dynamic>;
  }

  Future<void> disburseLoan({
    required String microfinancieraId,
    required String applicationId,
    required String requestId,
  }) async {
    AppLogger.api(
      'Desembolsando crédito',
      data: {
        'microfinancieraId': microfinancieraId,
        'applicationId': applicationId,
        'requestId': requestId,
      },
    );

    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/disbursements/disburse'),
      headers: headers,
      body: jsonEncode({
        'microfinancieraId': microfinancieraId,
        'applicationId': applicationId,
        'requestId': requestId,
      }),
    );

    AppLogger.api(
      'Respuesta desembolso',
      data: {
        'statusCode': response.statusCode,
        'hasResponse': response.body.isNotEmpty,
      },
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        'Error desembolsando: ${errorBody['error'] ?? response.body}',
      );
    }
  }

  Future<List<dynamic>> getRepaymentSchedule({
    required String microfinancieraId,
    required String applicationId,
  }) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/disbursements/schedule/$microfinancieraId/$applicationId',
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error obteniendo cronograma: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['schedule'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> debugApplicationsCount({
    required String microfinancieraId,
  }) async {
    final headers = await _getHeaders();

    final uri = Uri.parse(
      '$baseUrl/api/reports/debug/count',
    ).replace(queryParameters: {'microfinancieraId': microfinancieraId});

    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Error en debug: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
