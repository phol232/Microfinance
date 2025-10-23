import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;

class ApiConfig {
  static String get _devUrlAndroid =>
      dotenv.env['API_BASE_URL_DEV_ANDROID'] ?? 'http://10.0.2.2:3000';
  static String get _devUrlIOS =>
      dotenv.env['API_BASE_URL_DEV_IOS'] ?? 'http://localhost:3000';
  static String get _prodUrl => dotenv.env['API_BASE_URL_PROD'] ?? '';

  static String get baseUrl {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return _prodUrl;
    }

    if (Platform.isAndroid) {
      return _devUrlAndroid;
    } else if (Platform.isIOS) {
      return _devUrlIOS;
    }

    return _devUrlAndroid;
  }

  static bool get isDevelopment {
    return !const bool.fromEnvironment('dart.vm.product');
  }

  static bool get isProduction {
    return const bool.fromEnvironment('dart.vm.product');
  }

  static String get environment {
    return dotenv.env['ENVIRONMENT'] ?? 'development';
  }
}
