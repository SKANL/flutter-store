import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/app_color.dart';

class CustomBarcodeScanner extends StatefulWidget {
  final Function(String) onBarcodeScanned;
  final String? title;
  final String? subtitle;
  final bool showManualInput;
  final bool vibrate;
  
  const CustomBarcodeScanner({
    super.key,
    required this.onBarcodeScanned,
    this.title = 'Escanear Código de Barras',
    this.subtitle = 'Alinea el código de barras dentro del marco',
    this.showManualInput = true,
    this.vibrate = true,
  });

  @override
  State<CustomBarcodeScanner> createState() => _CustomBarcodeScannerState();
}

enum ScannerState {
  initializing,
  ready,
  scanning,
  processing,
  error,
}

class _CustomBarcodeScannerState extends State<CustomBarcodeScanner> 
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  ScannerState _scannerState = ScannerState.initializing;
  String? _errorMessage;
  
  final TextEditingController _manualInputController = TextEditingController();
  bool _isFlashOn = false;
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _animation;  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeScanner();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ),);
  }

  Future<void> _initializeScanner() async {
    try {
      debugPrint('🔄 Inicializando scanner...');
      setState(() {
        _scannerState = ScannerState.initializing;
        _errorMessage = null;
      });

      // Verificar permisos primero
      final hasPermission = await Permission.camera.isGranted;
      if (!hasPermission) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          throw Exception('Permisos de cámara denegados');
        }
      }

      // Inicializar controller
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
        autoStart: true, // Cambiar a true para que inicie automáticamente
      );

      // Esperar un momento para que el controller esté listo
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && _controller != null) {
        setState(() {
          _scannerState = ScannerState.ready;
        });
        debugPrint('✅ Scanner inicializado correctamente');
      }
    } catch (e) {
      debugPrint('❌ Error inicializando scanner: $e');
      if (mounted) {
        setState(() {
          _scannerState = ScannerState.error;
          _errorMessage = 'Error al inicializar la cámara: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    debugPrint('🔄 Disposing scanner...');
    _animationController.dispose();
    _controller?.dispose();
    _manualInputController.dispose();
    super.dispose();
    debugPrint('✅ Scanner disposed');
  }

  void _onBarcodeDetected(BarcodeCapture barcodeCapture) async {
    if (_isProcessing || _scannerState != ScannerState.ready) return;
    
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) return;
    
    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;
    
    debugPrint('📱 Código detectado: ${barcode.rawValue}');
    
    setState(() {
      _isProcessing = true;
      _scannerState = ScannerState.processing;
    });
    
    // Vibrar si está habilitado
    if (widget.vibrate) {
      HapticFeedback.mediumImpact();
    }
    
    // Pausar el escáner temporalmente
    try {
      await _controller?.stop();
    } catch (e) {
      debugPrint('⚠️ Error stopping controller: $e');
    }
    
    // Llamar al callback con el código escaneado
    widget.onBarcodeScanned(barcode.rawValue!);
  }

  void _toggleFlash() async {
    try {
      if (_controller != null) {
        await _controller!.toggleTorch();
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      }
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingresar Código Manualmente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa el código de barras manualmente:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualInputController,
              decoration: const InputDecoration(
                labelText: 'Código de barras',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _manualInputController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _manualInputController.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(context).pop();
                _manualInputController.clear();
                widget.onBarcodeScanned(code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title ?? ''),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.showManualInput)
            IconButton(
              icon: const Icon(Icons.keyboard),
              onPressed: _showManualInputDialog,
              tooltip: 'Ingresar manualmente',
            ),
          if (_scannerState == ScannerState.ready)
            IconButton(
              icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: _toggleFlash,
              tooltip: 'Flash',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_scannerState) {
      case ScannerState.initializing:
        return _buildInitializingState();
      case ScannerState.ready:
        return _buildScannerView();
      case ScannerState.scanning:
      case ScannerState.processing:
        return _buildProcessingState();
      case ScannerState.error:
        return _buildErrorState();
    }
  }

  Widget _buildInitializingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Inicializando cámara...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        // Scanner view
        if (_controller != null)
          MobileScanner(
            controller: _controller!,
            onDetect: _onBarcodeDetected,
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                'Error: Cámara no disponible',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        
        // Overlay with scanning frame
        _buildScanningOverlay(),
        
        // Bottom instruction panel
        _buildInstructionPanel(),
      ],
    );
  }

  Widget _buildProcessingState() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Procesando...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error con la cámara',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'No se pudo inicializar la cámara',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeScanner,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            if (widget.showManualInput) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _showManualInputDialog,
                icon: const Icon(Icons.keyboard),
                label: const Text('Ingresar manualmente'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return CustomPaint(
      painter: _ScannerOverlayPainter(
        animation: _animation,
        borderColor: AppColors.primary,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildInstructionPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Instructions
              Text(
                widget.subtitle ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              const Text(
                '• Mantén el teléfono estable\n'
                '• Asegúrate de que haya buena iluminación\n'
                '• El código debe estar completamente visible',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (widget.showManualInput) ...[
                const SizedBox(height: 16),
                
                TextButton.icon(
                  onPressed: _showManualInputDialog,
                  icon: const Icon(Icons.keyboard, color: AppColors.primary),
                  label: const Text(
                    'Ingresar código manualmente',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Animation<double> animation;
  final Color borderColor;

  _ScannerOverlayPainter({
    required this.animation,
    required this.borderColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final frameSize = size.width * 0.7;
    final frameRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: frameSize,
      height: frameSize * 0.6,
    );

    // Draw dark overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.7),
    );

    // Draw frame border
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(12)),
      borderPaint,
    );

    // Draw corner indicators
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      Offset(frameRect.left, frameRect.top + cornerLength),
      Offset(frameRect.left, frameRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.left, frameRect.top),
      Offset(frameRect.left + cornerLength, frameRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(frameRect.right - cornerLength, frameRect.top),
      Offset(frameRect.right, frameRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.right, frameRect.top),
      Offset(frameRect.right, frameRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(frameRect.left, frameRect.bottom - cornerLength),
      Offset(frameRect.left, frameRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.left, frameRect.bottom),
      Offset(frameRect.left + cornerLength, frameRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(frameRect.right - cornerLength, frameRect.bottom),
      Offset(frameRect.right, frameRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameRect.right, frameRect.bottom - cornerLength),
      Offset(frameRect.right, frameRect.bottom),
      cornerPaint,
    );

    // Draw scanning line
    final scanLineY = frameRect.top + 
        (frameRect.height * animation.value);
    final scanLinePaint = Paint()
      ..color = borderColor.withValues(alpha: 0.8)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(frameRect.left + 10, scanLineY),
      Offset(frameRect.right - 10, scanLineY),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
