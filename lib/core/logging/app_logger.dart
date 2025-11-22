import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class AppLogger {
  AppLogger._();

  static bool get _isDebugEnabled {
    return dotenv.env['ENABLE_DEBUG_LOGS']?.toLowerCase() == 'true' && kDebugMode;
  }

  static String get _logLevel {
    return dotenv.env['LOG_LEVEL']?.toLowerCase() ?? 'debug';
  }

  static bool _shouldLog(LogLevel level) {
    if (!_isDebugEnabled && level == LogLevel.debug) {
      return false;
    }

    switch (_logLevel) {
      case 'error':
        return level == LogLevel.error;
      case 'warning':
        return level == LogLevel.warning || level == LogLevel.error;
      case 'info':
        return level != LogLevel.debug;
      case 'debug':
      default:
        return true;
    }
  }

  static void debug(String message, {String? tag, Object? error}) {
    if (_shouldLog(LogLevel.debug)) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('🐛 DEBUG: $tagPrefix$message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
    }
  }

  static void info(String message, {String? tag}) {
    if (_shouldLog(LogLevel.info)) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ INFO: $tagPrefix$message');
    }
  }

  static void warning(String message, {String? tag, Object? error}) {
    if (_shouldLog(LogLevel.warning)) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('⚠️ WARNING: $tagPrefix$message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
    }
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_shouldLog(LogLevel.error)) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('❌ ERROR: $tagPrefix$message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null && kDebugMode) {
        debugPrint('   StackTrace: $stackTrace');
      }
    }
    
  }

  static void api(String message, {Map<String, dynamic>? data}) {
    if (_shouldLog(LogLevel.debug)) {
      debug(message, tag: 'API');
      if (data != null && kDebugMode) {
        debugPrint('   Data: $data');
      }
    }
  }

  static void bloc(String message, {String? blocName}) {
    if (_shouldLog(LogLevel.debug)) {
      final tag = blocName != null ? 'BLOC:$blocName' : 'BLOC';
      debug(message, tag: tag);
    }
  }

  static void navigation(String message) {
    if (_shouldLog(LogLevel.debug)) {
      debug(message, tag: 'NAVIGATION');
    }
  }
}