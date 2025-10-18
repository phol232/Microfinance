import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/api_config.dart';

class BackendApiDatasource {
  // URL del backend (desde configuración)
  final String baseUrl;

  BackendApiDatasource({String? baseUrl})
    : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtener token de Firebase para autenticación
  Future<String> _getToken() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final token = await user.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');
    return token;
  }

  /// Headers comunes para todas las peticiones
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

  // ============ SCORING ============

  /// Calcular scoring y tomar decisión automática
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

  /// Obtener detalles del scoring de una aplicación
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
    print('🔍 Tomando decisión manual:');
    print('   microfinancieraId: $microfinancieraId');
    print('   applicationId: $applicationId');
    print('   result: $result');

    final headers = await _getHeaders();
    print('   headers: ${headers.keys}');

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

    print('   statusCode: ${response.statusCode}');
    print('   response: ${response.body}');

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        'Error tomando decisión: ${errorBody['error'] ?? response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Obtener estadísticas de decisiones
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

  // ============ APLICACIONES ============

  /// Obtener aplicaciones asignadas a un agente
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

  /// Tomar posesión de una aplicación
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

  /// Actualizar estado de una aplicación
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

  /// Obtener estadísticas de aplicaciones
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

  // ============ REPORTES ============

  /// Generar reporte de aplicaciones
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

  /// Obtener métricas de conversión
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

  // ============ DESEMBOLSOS ============

  /// Desembolsar un crédito aprobado
  Future<void> disburseLoan({
    required String microfinancieraId,
    required String applicationId,
    required String requestId,
  }) async {
    print('💰 Desembolsando crédito:');
    print('   microfinancieraId: $microfinancieraId');
    print('   applicationId: $applicationId');
    print('   requestId: $requestId');

    final headers = await _getHeaders();
    print('   headers: ${headers.keys}');

    final response = await http.post(
      Uri.parse('$baseUrl/api/disbursements/disburse'),
      headers: headers,
      body: jsonEncode({
        'microfinancieraId': microfinancieraId,
        'applicationId': applicationId,
        'requestId': requestId,
      }),
    );

    print('   statusCode: ${response.statusCode}');
    print('   response: ${response.body}');

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        'Error desembolsando: ${errorBody['error'] ?? response.body}',
      );
    }
  }

  /// Obtener cronograma de pagos
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

  // ============ DEBUG ============

  /// Debug: Obtener conteo total de solicitudes
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
