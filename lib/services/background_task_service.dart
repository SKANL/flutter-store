import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/app_logger.dart';

/// Servicio para manejar operaciones pesadas sin bloquear la UI
class BackgroundTaskService {
  
  /// Ejecuta una tarea en background usando un Isolate
  static Future<T?> runInBackground<T>(
    Future<T> Function() task, {
    String? taskName,
    Duration? timeout,
  }) async {
    final String operationName = taskName ?? 'BackgroundTask';
    
    try {
      AppLogger.debug('Iniciando tarea en background: $operationName', 'BACKGROUND');
      
      // Para operaciones simples, usar compute es más eficiente que crear un Isolate completo
      final result = await _runWithTimeout(
        () => compute(_backgroundTaskRunner, task),
        timeout ?? const Duration(seconds: 30),
        operationName,
      );
      
      AppLogger.debug('Tarea completada: $operationName', 'BACKGROUND');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error en tarea background: $operationName',
        'BACKGROUND',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Ejecuta múltiples tareas en paralelo sin bloquear la UI
  static Future<List<T?>> runMultipleInBackground<T>(
    List<Future<T> Function()> tasks, {
    String? groupName,
    Duration? timeout,
  }) async {
    final String operationName = groupName ?? 'BackgroundTaskGroup';
    
    try {
      AppLogger.debug('Iniciando grupo de tareas: $operationName (${tasks.length} tareas)', 'BACKGROUND');
      
      final futures = tasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        
        return runInBackground(
          task,
          taskName: '${operationName}_$index',
          timeout: timeout,
        );
      }).toList();
      
      final results = await Future.wait(futures);
      
      AppLogger.debug('Grupo completado: $operationName', 'BACKGROUND');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error en grupo de tareas: $operationName',
        'BACKGROUND',
        e,
        stackTrace,
      );
      return List.filled(tasks.length, null);
    }
  }

  /// Ejecuta una tarea con timeout personalizado
  static Future<T?> _runWithTimeout<T>(
    Future<T> Function() task,
    Duration timeout,
    String operationName,
  ) async {
    try {
      return await task().timeout(
        timeout,
        onTimeout: () {
          AppLogger.warning('Timeout en tarea: $operationName', 'BACKGROUND');
          throw TimeoutException('Operación expirada: $operationName', timeout);
        },
      );
    } catch (e) {
      if (e is TimeoutException) {
        rethrow;
      }
      throw Exception('Error en tarea con timeout: $e');
    }
  }

  /// Función que se ejecuta en el Isolate
  static Future<T> _backgroundTaskRunner<T>(Future<T> Function() task) async {
    return await task();
  }

  /// Ejecuta una tarea pesada usando microtasks para no bloquear la UI
  static Future<T?> runAsyncWithYield<T>(
    Future<T> Function() task, {
    String? taskName,
    int yieldInterval = 100, // Ceder control cada 100ms
  }) async {
    final String operationName = taskName ?? 'AsyncTask';
    
    try {
      AppLogger.debug('Iniciando tarea async con yield: $operationName', 'BACKGROUND');
      
      final stopwatch = Stopwatch()..start();
      T? result;
      
      await Future.microtask(() async {
        result = await task();
      });
      
      // Si la tarea toma mucho tiempo, ceder control periódicamente
      while (stopwatch.elapsedMilliseconds < yieldInterval && result == null) {
        await Future.delayed(const Duration(microseconds: 1));
      }
      
      AppLogger.debug('Tarea async completada: $operationName', 'BACKGROUND');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error en tarea async: $operationName',
        'BACKGROUND',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Procesa una lista de elementos de manera chunked para evitar bloqueos
  static Future<List<R>> processListInChunks<T, R>(
    List<T> items,
    Future<R> Function(T) processor, {
    int chunkSize = 10,
    Duration chunkDelay = const Duration(milliseconds: 50),
    String? taskName,
  }) async {
    final String operationName = taskName ?? 'ChunkedProcessing';
    final results = <R>[];
    
    try {
      AppLogger.debug(
        'Procesando lista en chunks: $operationName (${items.length} elementos, chunks de $chunkSize)',
        'BACKGROUND',
      );
      
      for (int i = 0; i < items.length; i += chunkSize) {
        final end = (i + chunkSize < items.length) ? i + chunkSize : items.length;
        final chunk = items.sublist(i, end);
        
        // Procesar chunk actual
        final chunkResults = await Future.wait(
          chunk.map((item) => processor(item)),
        );
        
        results.addAll(chunkResults);
        
        // Ceder control entre chunks si no es el último
        if (end < items.length) {
          await Future.delayed(chunkDelay);
        }
        
        AppLogger.debug(
          'Chunk procesado: $end/${items.length} elementos',
          'BACKGROUND',
        );
      }
      
      AppLogger.debug('Procesamiento chunked completado: $operationName', 'BACKGROUND');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error en procesamiento chunked: $operationName',
        'BACKGROUND',
        e,
        stackTrace,
      );
      return results; // Devolver resultados parciales
    }
  }

  /// Cache simple para operaciones repetitivas
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  /// Ejecuta una operación con cache temporal
  static Future<T?> runWithCache<T>(
    String cacheKey,
    Future<T> Function() task, {
    Duration cacheDuration = const Duration(minutes: 5),
    String? taskName,
  }) async {
    final now = DateTime.now();
    
    // Verificar si hay un valor en cache válido
    if (_cache.containsKey(cacheKey) && _cacheTimestamps.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey]!;
      if (now.difference(cacheTime) < cacheDuration) {
        AppLogger.debug('Usando valor del cache: $cacheKey', 'CACHE');
        return _cache[cacheKey] as T;
      }
    }
    
    // Ejecutar tarea y cachear resultado
    try {
      final result = await runAsyncWithYield(task, taskName: taskName);
      if (result != null) {
        _cache[cacheKey] = result;
        _cacheTimestamps[cacheKey] = now;
        AppLogger.debug('Resultado cacheado: $cacheKey', 'CACHE');
      }
      return result;
    } catch (e) {
      AppLogger.error('Error en operación con cache: $cacheKey', 'CACHE', e);
      return null;
    }
  }

  /// Limpia el cache
  static void clearCache([String? specificKey]) {
    if (specificKey != null) {
      _cache.remove(specificKey);
      _cacheTimestamps.remove(specificKey);
      AppLogger.debug('Cache limpiado para: $specificKey', 'CACHE');
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
      AppLogger.debug('Cache completamente limpiado', 'CACHE');
    }
  }
}
