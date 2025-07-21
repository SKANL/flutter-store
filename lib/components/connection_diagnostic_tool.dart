import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../core/app_logger.dart';

class ConnectionDiagnosticTool extends StatefulWidget {
  const ConnectionDiagnosticTool({super.key});

  @override
  State<ConnectionDiagnosticTool> createState() => _ConnectionDiagnosticToolState();
}

class _ConnectionDiagnosticToolState extends State<ConnectionDiagnosticTool> {
  final List<DiagnosticResult> _results = [];
  bool _isRunning = false;
  final List<String> _testUrls = [
    'http://192.168.1.7:5041',
    'http://localhost:5041',
    'http://127.0.0.1:5041',
    'http://192.168.1.1:5041', // Router común
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌐 Diagnóstico de Conexión'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),
            _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔍 Diagnóstico de Conectividad API',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Esta herramienta verifica:'),
            const Text('• Conectividad de red'),
            const Text('• Estado del servidor API'),
            const Text('• Disponibilidad de endpoints'),
            const Text('• Configuración de IP/Puerto'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isRunning ? null : _runFullDiagnostic,
            icon: _isRunning 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.play_arrow),
            label: Text(_isRunning ? 'Ejecutando...' : 'Iniciar Diagnóstico'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _clearResults,
          icon: const Icon(Icons.clear),
          label: const Text('Limpiar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 Resultados del Diagnóstico',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _results.isEmpty
                  ? const Center(
                      child: Text('Presiona "Iniciar Diagnóstico" para comenzar'),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return _buildResultTile(result);
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultTile(DiagnosticResult result) {
    Color statusColor = result.success ? Colors.green : Colors.red;
    IconData statusIcon = result.success ? Icons.check_circle : Icons.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          result.testName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message),
            if (result.details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                result.details,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        trailing: result.duration != null
          ? Chip(
              label: Text('${result.duration!.inMilliseconds}ms'),
              backgroundColor: statusColor.withOpacity(0.1),
            )
          : null,
      ),
    );
  }

  Future<void> _runFullDiagnostic() async {
    setState(() {
      _isRunning = true;
      _results.clear();
    });

    AppLogger.info('CONNECTION_DIAGNOSTIC', 'Iniciando diagnóstico completo de conexión');

    // Test 1: Conectividad básica
    await _testNetworkConnectivity();

    // Test 2: Ping a diferentes IPs
    for (String baseUrl in _testUrls) {
      await _testServerConnectivity(baseUrl);
    }

    // Test 3: Endpoints específicos
    await _testApiEndpoints();

    // Test 4: Configuración recomendada
    await _generateRecommendations();

    setState(() {
      _isRunning = false;
    });

    AppLogger.info('CONNECTION_DIAGNOSTIC', 'Diagnóstico completo finalizado');
  }

  Future<void> _testNetworkConnectivity() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Test conectividad general
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );
      
      stopwatch.stop();
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _addResult(DiagnosticResult(
          testName: '🌐 Conectividad a Internet',
          success: true,
          message: 'Conexión a internet disponible',
          details: 'IP: ${result[0].address}',
          duration: stopwatch.elapsed,
        ));
      }
    } catch (e) {
      stopwatch.stop();
      _addResult(DiagnosticResult(
        testName: '🌐 Conectividad a Internet',
        success: false,
        message: 'Sin conexión a internet',
        details: 'Error: $e',
        duration: stopwatch.elapsed,
      ));
    }
  }

  Future<void> _testServerConnectivity(String baseUrl) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/productos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      stopwatch.stop();

      if (response.statusCode == 200) {
        _addResult(DiagnosticResult(
          testName: '✅ Servidor API ($baseUrl)',
          success: true,
          message: 'Servidor accesible',
          details: 'Status: ${response.statusCode}, Respuesta: ${response.body.length} chars',
          duration: stopwatch.elapsed,
        ));
      } else {
        _addResult(DiagnosticResult(
          testName: '⚠️ Servidor API ($baseUrl)',
          success: false,
          message: 'Servidor responde con error',
          details: 'Status: ${response.statusCode}',
          duration: stopwatch.elapsed,
        ));
      }
    } catch (e) {
      stopwatch.stop();
      _addResult(DiagnosticResult(
        testName: '❌ Servidor API ($baseUrl)',
        success: false,
        message: 'No se pudo conectar',
        details: 'Error: $e',
        duration: stopwatch.elapsed,
      ));
    }
  }

  Future<void> _testApiEndpoints() async {
    final endpoints = [
      '/api/categorias',
      '/api/proveedores', 
      '/api/productos',
      '/api/ventas',
    ];

    for (String endpoint in endpoints) {
      final stopwatch = Stopwatch()..start();
      
      try {
        final response = await http.get(
          Uri.parse('http://192.168.1.7:5041$endpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 8));

        stopwatch.stop();

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _addResult(DiagnosticResult(
            testName: '🎯 Endpoint $endpoint',
            success: true,
            message: 'Endpoint funcional',
            details: 'Datos: ${data is List ? data.length : 'Objeto'} items',
            duration: stopwatch.elapsed,
          ));
        } else {
          _addResult(DiagnosticResult(
            testName: '🎯 Endpoint $endpoint',
            success: false,
            message: 'Error en endpoint',
            details: 'Status: ${response.statusCode}',
            duration: stopwatch.elapsed,
          ));
        }
      } catch (e) {
        stopwatch.stop();
        _addResult(DiagnosticResult(
          testName: '🎯 Endpoint $endpoint',
          success: false,
          message: 'Endpoint no accesible',
          details: 'Error: $e',
          duration: stopwatch.elapsed,
        ));
      }
    }
  }

  Future<void> _generateRecommendations() async {
    // Analizar resultados y generar recomendaciones
    bool hasInternetConnection = _results.any((r) => r.testName.contains('Internet') && r.success);
    bool hasWorkingServer = _results.any((r) => r.testName.contains('Servidor API') && r.success);
    bool hasWorkingEndpoints = _results.any((r) => r.testName.contains('Endpoint') && r.success);

    String recommendations = '';
    
    if (!hasInternetConnection) {
      recommendations += '• Verificar conexión WiFi/datos móviles\n';
    }
    
    if (!hasWorkingServer) {
      recommendations += '• Iniciar el servidor backend API\n';
      recommendations += '• Verificar que esté ejecutándose en puerto 5041\n';
      recommendations += '• Verificar la IP correcta del servidor\n';
    }
    
    if (!hasWorkingEndpoints) {
      recommendations += '• Verificar configuración de endpoints\n';
      recommendations += '• Revisar cors en el backend\n';
    }

    if (hasInternetConnection && hasWorkingServer && hasWorkingEndpoints) {
      recommendations = '✅ Todo funciona correctamente!\n• La app debería conectarse sin problemas';
    }

    _addResult(DiagnosticResult(
      testName: '💡 Recomendaciones',
      success: hasWorkingServer && hasWorkingEndpoints,
      message: hasWorkingServer && hasWorkingEndpoints ? 'Sistema funcionando' : 'Acciones requeridas',
      details: recommendations,
    ));
  }

  void _addResult(DiagnosticResult result) {
    setState(() {
      _results.add(result);
    });
  }

  void _clearResults() {
    setState(() {
      _results.clear();
    });
  }
}

class DiagnosticResult {
  final String testName;
  final bool success;
  final String message;
  final String details;
  final Duration? duration;

  DiagnosticResult({
    required this.testName,
    required this.success,
    required this.message,
    required this.details,
    this.duration,
  });
}
