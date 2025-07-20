import 'package:flutter/foundation.dart';

/// Sistema de logging profesional para reemplazar print() en producción
class AppLogger {
  static const String _tag = '[STORE_APP]';
  
  // Control de nivel de log
  static LogLevel _currentLevel = kDebugMode ? LogLevel.debug : LogLevel.error;
  
  /// Configura el nivel de logging
  static void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }
  
  /// Log de debug (solo en modo debug)
  static void debug(String message, [String? tag]) {
    if (_currentLevel.level <= LogLevel.debug.level) {
      _log('DEBUG', message, tag);
    }
  }
  
  /// Log de información
  static void info(String message, [String? tag]) {
    if (_currentLevel.level <= LogLevel.info.level) {
      _log('INFO', message, tag);
    }
  }
  
  /// Log de advertencia
  static void warning(String message, [String? tag]) {
    if (_currentLevel.level <= LogLevel.warning.level) {
      _log('WARNING', message, tag);
    }
  }
  
  /// Log de error
  static void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    if (_currentLevel.level <= LogLevel.error.level) {
      _log('ERROR', message, tag);
      if (error != null) {
        _log('ERROR', 'Exception: $error', tag);
      }
      if (stackTrace != null && kDebugMode) {
        _log('ERROR', 'StackTrace: $stackTrace', tag);
      }
    }
  }
  
  /// Log crítico (siempre se muestra)
  static void critical(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    _log('CRITICAL', message, tag);
    if (error != null) {
      _log('CRITICAL', 'Exception: $error', tag);
    }
    if (stackTrace != null) {
      _log('CRITICAL', 'StackTrace: $stackTrace', tag);
    }
  }
  
  /// Método interno para formatear y mostrar logs
  static void _log(String level, String message, String? tag) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final fullTag = tag != null ? '$_tag[$tag]' : _tag;
    
    // Solo usar debugPrint en modo debug, no print
    if (kDebugMode) {
      debugPrint('$timestamp $level $fullTag: $message');
    }
    
    // En producción, podrías enviar logs críticos a un servicio de monitoreo
    if (level == 'CRITICAL' && kReleaseMode) {
      // TODO: Enviar a servicio de logging (Firebase Crashlytics, Sentry, etc.)
    }
  }
}

/// Niveles de logging disponibles
enum LogLevel {
  debug(0),
  info(1),  
  warning(2),
  error(3),
  critical(4);
  
  const LogLevel(this.level);
  final int level;
}
