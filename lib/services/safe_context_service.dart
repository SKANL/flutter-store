import 'package:flutter/material.dart';
import '../core/app_logger.dart';

/// Servicio para el manejo seguro de BuildContext después de operaciones asíncronas
class SafeContextService {
  
  /// Ejecuta una función con context de manera segura
  /// Verifica que el widget aún esté montado antes de ejecutar
  static Future<T?> safeExecute<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    if (!context.mounted) {
      AppLogger.warning(
        'Context no válido para operación: ${operationName ?? 'desconocida'}',
        'SAFE_CONTEXT'
      );
      return null;
    }

    try {
      final result = await operation();
      
      // Verificar nuevamente que el context sigue siendo válido
      if (!context.mounted) {
        AppLogger.warning(
          'Context perdido durante operación: ${operationName ?? 'desconocida'}',
          'SAFE_CONTEXT'
        );
        return null;
      }
      
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error durante operación: ${operationName ?? 'desconocida'}',
        'SAFE_CONTEXT',
        e,
        stackTrace
      );
      return null;
    }
  }

  /// Muestra un SnackBar de manera segura
  static void safeShowSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    if (!context.mounted) {
      AppLogger.warning('Context no válido para mostrar SnackBar', 'SAFE_CONTEXT');
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration ?? const Duration(seconds: 3),
          action: action,
        ),
      );
    } catch (e) {
      AppLogger.error('Error mostrando SnackBar: $message', 'SAFE_CONTEXT', e);
    }
  }

  /// Navega de manera segura
  static Future<T?> safeNavigate<T extends Object?>(
    BuildContext context,
    Widget destination, {
    bool replace = false,
    String? routeName,
  }) async {
    if (!context.mounted) {
      AppLogger.warning(
        'Context no válido para navegación a: ${routeName ?? destination.toString()}',
        'SAFE_CONTEXT'
      );
      return null;
    }

    try {
      if (replace) {
        return Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => destination),
        );
      } else {
        return Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => destination),
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error durante navegación a: ${routeName ?? destination.toString()}',
        'SAFE_CONTEXT',
        e
      );
      return null;
    }
  }

  /// Navega usando rutas con nombre de manera segura
  static Future<T?> safeNavigateNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool clearStack = false,
  }) async {
    if (!context.mounted) {
      AppLogger.warning(
        'Context no válido para navegación a ruta: $routeName',
        'SAFE_CONTEXT'
      );
      return null;
    }

    try {
      if (clearStack) {
        return Navigator.of(context).pushNamedAndRemoveUntil(
          routeName,
          (route) => false,
          arguments: arguments,
        );
      } else if (replace) {
        return Navigator.of(context).pushReplacementNamed(
          routeName,
          arguments: arguments,
        );
      } else {
        return Navigator.of(context).pushNamed(
          routeName,
          arguments: arguments,
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error durante navegación a ruta: $routeName',
        'SAFE_CONTEXT',
        e
      );
      return null;
    }
  }

  /// Retrocede de manera segura en la navegación
  static bool safeNavigateBack(BuildContext context, [dynamic result]) {
    if (!context.mounted) {
      AppLogger.warning('Context no válido para retroceder', 'SAFE_CONTEXT');
      return false;
    }

    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(result);
        return true;
      } else {
        AppLogger.warning('No hay rutas disponibles para retroceder', 'SAFE_CONTEXT');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error retrocediendo en navegación', 'SAFE_CONTEXT', e);
      return false;
    }
  }

  /// Muestra un diálogo de manera segura
  static Future<T?> safeShowDialog<T>(
    BuildContext context,
    Widget dialog, {
    bool barrierDismissible = true,
  }) async {
    if (!context.mounted) {
      AppLogger.warning('Context no válido para mostrar diálogo', 'SAFE_CONTEXT');
      return null;
    }

    try {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (_) => dialog,
      );
    } catch (e) {
      AppLogger.error('Error mostrando diálogo', 'SAFE_CONTEXT', e);
      return null;
    }
  }

  /// Ejecuta una función después del siguiente frame de manera segura
  static void safePostFrame(
    BuildContext context,
    VoidCallback callback, {
    String? operationName,
  }) {
    if (!context.mounted) {
      AppLogger.warning(
        'Context no válido para PostFrame: ${operationName ?? 'desconocida'}',
        'SAFE_CONTEXT'
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        try {
          callback();
        } catch (e) {
          AppLogger.error(
            'Error en PostFrame: ${operationName ?? 'desconocida'}',
            'SAFE_CONTEXT',
            e
          );
        }
      } else {
        AppLogger.warning(
          'Context perdido durante PostFrame: ${operationName ?? 'desconocida'}',
          'SAFE_CONTEXT'
        );
      }
    });
  }
}
