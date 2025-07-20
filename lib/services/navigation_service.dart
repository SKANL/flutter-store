import 'package:flutter/material.dart';
import '../core/app_logger.dart';
import '../services/safe_context_service.dart';

class NavigationService {
  static Future<bool> safeNavigateBack(BuildContext context) async {
    if (!context.mounted) {
      AppLogger.warning('Contexto no válido para navegación', 'NAV');
      return false;
    }

    // Esperar un frame para asegurar estabilidad
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!context.mounted) {
      AppLogger.warning('Contexto perdido durante espera', 'NAV');
      return false;
    }

    // Usar el nuevo servicio seguro de contexto
    final result = await SafeContextService.safeNavigateNamed(
      context, 
      '/dashboard',
      clearStack: true,
    );
    
    final success = result != null;
    AppLogger.debug('Navegación ${success ? 'exitosa' : 'falló'}', 'NAV');
    return success;
  }

  static Future<void> showSuccessMessage(BuildContext context, String message) async {
    SafeContextService.safeShowSnackBar(
      context,
      message,
      backgroundColor: Colors.green,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Dar tiempo para que se muestre el mensaje
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
