import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/app_logger.dart';
import '../services/api_service.dart';

class ApiConfigTool extends StatefulWidget {
  const ApiConfigTool({super.key});

  @override
  State<ApiConfigTool> createState() => _ApiConfigToolState();
}

class _ApiConfigToolState extends State<ApiConfigTool> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  bool _isLoading = false;
  String? _testResult;
  Color _testResultColor = Colors.grey;

  final List<String> _commonIps = [
    '192.168.1.7',
    '192.168.1.1',
    '192.168.0.1',
    '10.0.0.1',
    '127.0.0.1',
    'localhost',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    // Cargar configuración actual desde ApiService
    final currentBaseUrl = ApiService.baseUrl;
    final uri = Uri.parse(currentBaseUrl);
    _ipController.text = uri.host;
    _portController.text = uri.port.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Configuración API'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentConfigCard(),
            const SizedBox(height: 20),
            _buildConfigForm(),
            const SizedBox(height: 20),
            _buildQuickIpButtons(),
            const SizedBox(height: 20),
            _buildTestSection(),
            const SizedBox(height: 20),
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentConfigCard() {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔧 Configuración Actual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('URL Base: ${ApiService.baseUrl}'),
            const SizedBox(height: 4),
            Text('Estado: ${_testResult ?? 'No probado'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 Nueva Configuración',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Dirección IP del Servidor',
                hintText: 'Ej: 192.168.1.7',
                prefixIcon: Icon(Icons.computer),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Puerto',
                hintText: 'Ej: 5041',
                prefixIcon: Icon(Icons.settings_ethernet),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickIpButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚀 IPs Comunes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonIps.map((ip) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _ipController.text = ip;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade800,
                  ),
                  child: Text(ip),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧪 Probar Conexión',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testConnection,
                    icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_find),
                    label: Text(_isLoading ? 'Probando...' : 'Probar Conexión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveAndApplyConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar y Aplicar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResultColor.withOpacity(0.1),
                  border: Border.all(color: _testResultColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResultColor == Colors.green ? Icons.check_circle : Icons.error,
                      color: _testResultColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(color: _testResultColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      color: Colors.amber.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💡 Instrucciones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Asegúrate de que tu servidor API esté ejecutándose'),
            Text('2. Verifica que el firewall permita conexiones en el puerto especificado'),
            Text('3. Si usas un emulador Android, usa 10.0.2.2 para localhost'),
            Text('4. Si usas un dispositivo físico, usa la IP real de tu computadora'),
            Text('5. Prueba la conexión antes de guardar la configuración'),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_ipController.text.isEmpty || _portController.text.isEmpty) {
      setState(() {
        _testResult = 'Por favor, completa IP y Puerto';
        _testResultColor = Colors.orange;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    final testUrl = 'http://${_ipController.text}:${_portController.text}';
    AppLogger.info('API_CONFIG', 'Probando conexión a: $testUrl');

    try {
      final response = await http.get(
        Uri.parse('$testUrl/api/productos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _testResult = '✅ Conexión exitosa! Encontrados ${data is List ? data.length : 'varios'} productos';
          _testResultColor = Colors.green;
        });
        AppLogger.info('API_CONFIG', 'Conexión exitosa a $testUrl');
      } else {
        setState(() {
          _testResult = '⚠️ Servidor responde con error: ${response.statusCode}';
          _testResultColor = Colors.orange;
        });
        AppLogger.warning('API_CONFIG', 'Servidor responde con error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ Error de conexión: $e';
        _testResultColor = Colors.red;
      });
      AppLogger.error('API_CONFIG', 'Error de conexión: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndApplyConfig() async {
    if (_ipController.text.isEmpty || _portController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa IP y Puerto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newBaseUrl = 'http://${_ipController.text}:${_portController.text}';
    
    // Aplicar nueva configuración
    ApiService.updateBaseUrl(newBaseUrl);
    
    AppLogger.info('API_CONFIG', 'Nueva configuración aplicada: $newBaseUrl');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Configuración guardada: $newBaseUrl'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Probar',
          onPressed: _testConnection,
        ),
      ),
    );

    // Actualizar la configuración mostrada
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
