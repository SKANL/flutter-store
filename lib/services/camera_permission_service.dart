import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class CameraPermissionService {
  /// Solicita permisos de cámara
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Verifica si los permisos de cámara están concedidos
  static Future<bool> hasCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking camera permission: $e');
      return false;
    }
  }

  /// Verifica si los permisos están denegados permanentemente
  static Future<bool> isCameraPermissionPermanentlyDenied() async {
    try {
      final status = await Permission.camera.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      debugPrint('Error checking permanent camera permission: $e');
      return false;
    }
  }

  /// Abre la configuración de la app para permisos
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  /// Muestra un diálogo de permisos personalizado
  static Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.blue),
            SizedBox(width: 8),
            Text('Permiso de Cámara'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta aplicación necesita acceso a la cámara para escanear códigos de barras.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Permisos necesarios:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Cámara - Para escanear códigos de barras'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Conceder Permiso'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Muestra un diálogo cuando los permisos están denegados permanentemente
  static Future<void> showPermanentlyDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Permisos Denegados'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Los permisos de cámara han sido denegados permanentemente. '
              'Para usar el escáner de códigos de barras, debes habilitar '
              'los permisos manualmente en la configuración de la app.',
            ),
            SizedBox(height: 12),
            Text(
              'Pasos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('1. Toca "Ir a Configuración"'),
            Text('2. Busca "Permisos" o "Permissions"'),
            Text('3. Habilita el acceso a la Cámara'),
            Text('4. Regresa a la aplicación'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ir a Configuración'),
          ),
        ],
      ),
    );
  }

  /// Flujo completo de solicitud de permisos con UI
  static Future<bool> requestPermissionWithUI(BuildContext context) async {
    // Verificar si ya tenemos el permiso
    if (await hasCameraPermission()) {
      return true;
    }

    // Verificar si está denegado permanentemente
    if (await isCameraPermissionPermanentlyDenied()) {
      await showPermanentlyDeniedDialog(context);
      return false;
    }

    // Mostrar diálogo explicativo antes de solicitar
    final shouldRequest = await showPermissionDialog(context);
    if (!shouldRequest) {
      return false;
    }

    // Solicitar el permiso
    final granted = await requestCameraPermission();
    
    if (!granted) {
      // Mostrar mensaje si fue denegado
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permiso de cámara denegado. El escáner no funcionará correctamente.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    return granted;
  }
}
