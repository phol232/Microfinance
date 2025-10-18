import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/datasources/backend_api_datasource.dart';

/// Widget de prueba para verificar la autenticación con el backend
///
/// Uso:
/// ```dart
/// // Agregar en cualquier pantalla
/// AuthTestButton()
/// ```
class AuthTestButton extends StatefulWidget {
  const AuthTestButton({super.key});

  @override
  State<AuthTestButton> createState() => _AuthTestButtonState();
}

class _AuthTestButtonState extends State<AuthTestButton> {
  bool _isLoading = false;
  String? _result;
  String? _token;

  Future<void> _testAuth() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _token = null;
    });

    try {
      // 1. Obtener token de Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      final token = await user.getIdToken();
      if (token == null) {
        throw Exception('No se pudo obtener el token');
      }

      setState(() {
        _token = token;
      });

      // 2. Probar autenticación con el backend
      final backendApi = BackendApiDatasource();
      final response = await backendApi.testAuth();

      setState(() {
        _result =
            '✅ Autenticación exitosa!\n\n'
            'Usuario: ${response['user']['uid']}\n'
            'Email: ${response['user']['email']}\n'
            'Role: ${response['user']['role'] ?? 'N/A'}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToken() {
    if (_token != null) {
      Clipboard.setData(ClipboardData(text: _token!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token copiado al portapapeles'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🧪 Prueba de Autenticación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifica que el backend puede autenticar tu token de Firebase',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Botón de prueba
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testAuth,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Probar Autenticación'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            // Resultado
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result!.startsWith('✅')
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _result!.startsWith('✅') ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _result!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: _result!.startsWith('✅')
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ),
            ],

            // Token (para copiar)
            if (_token != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Token: ${_token!.substring(0, 30)}...',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: _copyToken,
                    tooltip: 'Copiar token completo',
                  ),
                ],
              ),
              const Text(
                'Usa este token para probar con curl o Postman',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
