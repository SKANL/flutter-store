import 'package:flutter/material.dart';
import '../screens/store_dashboard_screen.dart';

class NavigationService {
  static Future<bool> safeNavigateBack(BuildContext context) async {
    if (!context.mounted) {
      print('⚠️ [NAV] Contexto no válido para navegación');
      return false;
    }

    // Esperar un frame para asegurar estabilidad
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!context.mounted) {
      print('⚠️ [NAV] Contexto perdido durante espera');
      return false;
    }

    // Usar WidgetsBinding para navegación más segura
    bool navigationSuccess = false;
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      
      try {
        print('🔄 [NAV] Intentando navigación segura...');
        
        // Método principal: pushNamedAndRemoveUntil
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard',
          (route) => false,
        );
        
        navigationSuccess = true;
        print('✅ [NAV] Navegación exitosa');
      } catch (e) {
        print('❌ [NAV] Error en navegación principal: $e');
        
        // Método de respaldo
        try {
          if (context.mounted) {
            await Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const StoreDashboardScreen(),
                settings: const RouteSettings(name: '/dashboard'),
              ),
              (route) => false,
            );
            navigationSuccess = true;
            print('✅ [NAV] Navegación de respaldo exitosa');
          }
        } catch (e2) {
          print('❌ [NAV] Error en navegación de respaldo: $e2');
          
          // Último recurso: pop simple
          if (context.mounted) {
            try {
              Navigator.of(context).pop(true);
              navigationSuccess = true;
              print('✅ [NAV] Pop simple como último recurso');
            } catch (e3) {
              print('❌ [NAV] Todos los métodos de navegación fallaron: $e3');
            }
          }
        }
      }
    });
    
    // Esperar a que se complete el callback
    await Future.delayed(const Duration(milliseconds: 200));
    return navigationSuccess;
  }

  static Future<void> showSuccessMessage(BuildContext context, String message) async {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Dar tiempo para que se muestre el mensaje
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
