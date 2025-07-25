import 'package:flutter/material.dart';
import 'package:store_manager/core/app_theme.dart';
import 'package:store_manager/core/inventory_state.dart';
import 'package:store_manager/core/app_logger.dart';
import 'package:store_manager/core/api_config.dart';
import 'package:store_manager/screens/store_dashboard_screen.dart';
import 'package:store_manager/services/api_service.dart';

// Clave global para acceder al estado del AppInitializer desde cualquier lugar
final GlobalKey<_AppInitializerState> appInitializerKey = GlobalKey<_AppInitializerState>();

Future<void> main() async {
  // Asegurarse de que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar el sistema de logging
  AppLogger.setLogLevel(LogLevel.debug);
  AppLogger.info('Iniciando Store Manager App', 'MAIN');

  // Inicializar la configuración de la API antes de lanzar la aplicación
  // Intentará auto-detectar el entorno (emulador, dispositivo físico, localhost)
  await ApiConfig.configureForEnvironment();
  AppLogger.info('URL de API configurada: ${ApiConfig.baseUrl}', 'MAIN');

  // Guardar la IP del dispositivo para diagnóstico
  final deviceIps = await ApiConfig.getDeviceIpAddresses();
  if (deviceIps.isNotEmpty) {
    AppLogger.info('IPs de este dispositivo: ${deviceIps.join(", ")}', 'MAIN');
  }
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Crear instancia de InventoryState y cargar datos iniciales
    final inventoryState = InventoryState();
    
    return InventoryProvider(
      notifier: inventoryState,
      child: MaterialApp(
        title: 'Store Manager',
        theme: AppTheme.lightTheme,
        home: AppInitializer(
          key: appInitializerKey,
          inventoryState: inventoryState,
        ),
        debugShowCheckedModeBanner: false,
        // Añadir rutas con nombre para navegación de respaldo
        routes: {
          '/dashboard': (context) => const StoreDashboardScreen(),
        },
      ),
    );
  }
}

// Widget para inicializar datos de la app
class AppInitializer extends StatefulWidget {
  final InventoryState inventoryState;
  
  const AppInitializer({
    super.key,
    required this.inventoryState,
  });

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _showConfigApiButton = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Mostrar UI inmediatamente sin bloquear
    AppLogger.debug('Iniciando carga de datos en background', 'INIT');

    // Cargar datos en background sin bloquear el UI
    try {
      // Usar microtask para no bloquear el hilo principal
      await Future.microtask(() async {
        await widget.inventoryState.initializeData();
      });
      
      AppLogger.info('Datos cargados exitosamente', 'INIT');
    } catch (e, stackTrace) {
      AppLogger.error('Error durante la carga en background', 'INIT', e, stackTrace);
      
      if (mounted) {
        // Mostrar mensaje más específico basado en el tipo de error
        final errorMsg = e.toString().contains('Connection failed') || 
                        e.toString().contains('SocketException') || 
                        e.toString().contains('Connection refused') ||
                        e.toString().contains('No se puede conectar') ||
                        e.toString().contains('Network is unreachable')
            ? 'Error de conexión a ${ApiConfig.baseUrl}. La API parece no estar disponible.'
            : 'Error de conexión: ${e.toString()}';
            
        // Mostrar snackbar con error pero mantener la UI funcional
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Configurar API',
              onPressed: () => _showApiConfigDialog(),
            ),
          ),
        );
        
        // Mostrar SIEMPRE el diálogo de configuración API si hay cualquier error
        // El delay es para que el usuario vea primero el snackbar
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showApiConfigDialog();
          }
        });
      }
    }
  }
  
  // Widget auxiliar para crear botones de configuración de API
  Widget _buildApiButton(TextEditingController controller, String label, String url) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label),
      onPressed: () {
        controller.text = url;
      },
    );
  }

  // Dialog para configurar manualmente la API
  void _showApiConfigDialog() {
    final TextEditingController urlController = TextEditingController(text: ApiConfig.baseUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar URL de la API'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'La conexión a la API falló. Prueba con una URL diferente:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL de la API',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              // Botones de opciones de conexión comunes
              const Text(
                'Seleccione una configuración:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildApiButton(urlController, 'Emulador', ApiConfig.emulatorUrl),
                  _buildApiButton(urlController, 'localhost', ApiConfig.localHostUrl),
                  _buildApiButton(urlController, '0.0.0.0', ApiConfig.allInterfacesUrl),
                  _buildApiButton(urlController, '192.168.1.7', ApiConfig.localDeviceUrl),
                  _buildApiButton(urlController, '127.0.0.1', 'http://127.0.0.1:5041'),
                ],
              ),
              const SizedBox(height: 8),
              // Campo para ingresar IP personalizada
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'IP personalizada',
                        hintText: 'ej: 192.168.1.X',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          urlController.text = 'http://${value.trim()}:5041';
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Generar una lista de IPs comunes en la subred 192.168.1.X
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sugerencias de IPs'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(10, (i) {
                                final ip = 'http://192.168.1.${i+1}:5041';
                                return ListTile(
                                  title: Text(ip),
                                  onTap: () {
                                    urlController.text = ip;
                                    Navigator.pop(context);
                                  },
                                  trailing: const Icon(Icons.arrow_forward),
                                  dense: true,
                                );
                              }),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Ver IPs'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.network_check),
                label: const Text('Detectar automáticamente'),
                onPressed: () async {
                  // Mostrar indicador de progreso
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      title: Text('Buscando API'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Escaneando la red...'),
                        ],
                      ),
                    ),
                  );
                  
                  // Ejecutar la detección automática
                  await ApiConfig.configureForEnvironment();
                  
                  // Actualizar el campo de texto con la URL detectada
                  urlController.text = ApiConfig.baseUrl;
                  
                  // Cerrar el diálogo de progreso
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              // Mostrar información de la red para diagnóstico
              FutureBuilder<List<String>>(
                future: ApiConfig.getDeviceIpAddresses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INFORMACIÓN DE DIAGNÓSTICO:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'IP actual de este dispositivo:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      ...snapshot.data!.map((ip) => InkWell(
                        onTap: () {
                          // Al hacer tap en una IP, crear una URL y usarla
                          final ipBase = ip.split('.').take(3).join('.');
                          final suggestedUrl = 'http://$ipBase.7:5041'; // Usar x.x.x.7 como convención común
                          urlController.text = suggestedUrl;
                        },
                        child: Row(
                          children: [
                            Text(
                              ip,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.copy, size: 14),
                          ],
                        ),
                      )),
                      const SizedBox(height: 12),
                      const Text(
                        'IMPORTANTE:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '1. La API y el dispositivo deben estar en la misma red WiFi',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '2. Ingresa la IP de tu PC donde se ejecuta la API',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '3. Para conocer la IP de tu PC, ejecuta "ipconfig" en CMD',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      // Botón para abrir las instrucciones
                      OutlinedButton.icon(
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: const Text('Ver guía completa'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Guía de conexión'),
                              content: const SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('1. Asegúrate que tu API esté ejecutándose'),
                                    Text('2. Verifica que la API y el móvil estén en la misma red'),
                                    Text('3. Obtén la IP de tu PC:'),
                                    Padding(
                                      padding: EdgeInsets.only(left: 16),
                                      child: Text('- Windows: abre CMD y ejecuta "ipconfig"'),
                                    ),
                                    Text('4. Ingresa la URL: http://TU_IP:5041'),
                                    SizedBox(height: 8),
                                    Text('Posibles problemas:'),
                                    Padding(
                                      padding: EdgeInsets.only(left: 16),
                                      child: Text('- Firewall de Windows bloqueando conexiones'),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 16),
                                      child: Text('- La API no está configurada para aceptar conexiones externas'),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Entendido'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                // Mostrar indicador de progreso
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    title: Text('Probando conexión'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Intentando conectar con la API...'),
                      ],
                    ),
                  ),
                );
                
                // Actualizar la URL
                ApiConfig.updateBaseUrl(newUrl);
                
                // Limpiar caché de la API
                ApiService.clearCache();
                
                // Probar la conexión
                final isConnected = await ApiConfig.testApiConnection(newUrl);
                
                // Cerrar el diálogo de progreso
                Navigator.pop(context);
                
                if (isConnected) {
                  // Si la conexión funciona, cerrar el diálogo de configuración
                  Navigator.pop(context);
                  
                  // Mostrar mensaje de éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Conexión exitosa! Cargando datos...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Reintentar cargar datos
                  _initializeApp();
                } else {
                  // Si la conexión falla, mostrar mensaje de error
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: No se pudo conectar a la API. Verifica la URL y que el servidor esté en ejecución.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            label: const Text('Probar y Guardar'),
          ),
          // Agregar botón para probar la URL sin guardar
          ElevatedButton.icon(
            icon: const Icon(Icons.network_check),
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                // Mostrar indicador de progreso
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    title: Text('Probando conexión'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Probando solo la conexión...'),
                      ],
                    ),
                  ),
                );
                
                // Probar la conexión sin guardar la URL
                final isConnected = await ApiConfig.testApiConnection(newUrl);
                
                // Cerrar el diálogo de progreso
                Navigator.pop(context);
                
                // Mostrar resultado
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isConnected 
                      ? 'La conexión a $newUrl funciona correctamente!' 
                      : 'Error: No se pudo conectar a $newUrl'),
                    backgroundColor: isConnected ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            label: const Text('Solo Probar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Siempre mostrar StoreDashboardScreen directamente
    // Los datos se cargan en background sin bloquear UI
    return Stack(
      children: [
        StoreDashboardScreen(
          showConfigApiSwitch: _showConfigApiButton,
          onConfigApiSwitchChanged: (value) {
            setState(() {
              _showConfigApiButton = value;
            });
          },
        ),
        if (_showConfigApiButton)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showApiConfigDialog,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.settings_ethernet, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Config. API',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
