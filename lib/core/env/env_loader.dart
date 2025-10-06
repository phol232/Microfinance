import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvLoader {
  EnvLoader._();

  static bool _isInitialized = false;

  static Future<void> ensureInitialized({String fileName = 'assets/env/.env'}) async {
    if (_isInitialized) return;
    await dotenv.load(fileName: fileName);
    _isInitialized = true;
  }

  static String get(
    String key, {
    String? fallback,
    bool isRequired = false,
  }) {
    final value = dotenv.maybeGet(key);
    if ((value == null || value.isEmpty) && isRequired) {
      throw StateError('Missing required environment variable "$key".');
    }
    return value ?? fallback ?? '';
  }
}
