import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple wrapper around [flutter_dotenv] to ensure the environment file
/// is loaded once and to provide typed access helpers.
class EnvLoader {
  EnvLoader._();

  static bool _isInitialized = false;

  /// Loads the environment variables from the bundled `.env` file.
  /// Subsequent calls are ignored.
  static Future<void> ensureInitialized({String fileName = 'assets/env/.env'}) async {
    if (_isInitialized) return;
    await dotenv.load(fileName: fileName);
    _isInitialized = true;
  }

  /// Reads an environment value, optionally throwing if it is missing.
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
