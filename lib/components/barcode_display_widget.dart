import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/services.dart';
import '../core/app_color.dart';
import '../core/app_text_styles.dart';
import '../services/barcode_generator_service.dart';

class BarcodeDisplayWidget extends StatelessWidget {
  final String barcode;
  final double? width;
  final double? height;
  final bool showCopyButton;
  final bool showTypeInfo;
  
  const BarcodeDisplayWidget({
    super.key,
    required this.barcode,
    this.width,
    this.height,
    this.showCopyButton = true,
    this.showTypeInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    final barcodeType = BarcodeGeneratorService.detectBarcodeType(barcode);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barcode widget
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: BarcodeWidget(
              barcode: _getBarcodeType(barcodeType),
              data: barcode,
              width: width ?? 200,
              height: height ?? 80,
              drawText: true,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              errorBuilder: (context, error) => Container(
                width: width ?? 200,
                height: height ?? 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade400,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error al generar\ncódigo de barras',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Barcode text
          SelectableText(
            barcode,
            style: AppTextStyles.description.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (showTypeInfo) ...[
            const SizedBox(height: 8),
            Text(
              'Tipo: $barcodeType',
              style: AppTextStyles.small.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
          
          if (showCopyButton) ...[
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _copyToClipboard(context),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _shareBarcode(context),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Compartir'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Barcode _getBarcodeType(String type) {
    switch (type) {
      case 'EAN-13':
        return Barcode.ean13();
      case 'UPC-A':
        return Barcode.upcA();
      case 'EAN-8':
        return Barcode.ean8();
      case 'Code128':
      default:
        return Barcode.code128();
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: barcode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado al portapapeles'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareBarcode(BuildContext context) {
    // En una implementación real, aquí usarías el paquete share_plus
    // Para este ejemplo, solo mostramos el código para copiar
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartir Código de Barras'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Código de barras:'),
            const SizedBox(height: 8),
            SelectableText(
              barcode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              _copyToClipboard(context);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }
}

class BarcodeGeneratorDialog extends StatefulWidget {
  final Function(String) onBarcodeGenerated;
  
  const BarcodeGeneratorDialog({
    super.key,
    required this.onBarcodeGenerated,
  });

  @override
  State<BarcodeGeneratorDialog> createState() => _BarcodeGeneratorDialogState();
}

class _BarcodeGeneratorDialogState extends State<BarcodeGeneratorDialog> {
  String _selectedType = 'EAN-13';
  String? _generatedBarcode;
  
  final List<String> _barcodeTypes = [
    'EAN-13',
    'UPC-A',
    'Code128',
  ];

  void _generateBarcode() {
    String newBarcode;
    
    switch (_selectedType) {
      case 'EAN-13':
        newBarcode = BarcodeGeneratorService.generateEAN13();
        break;
      case 'UPC-A':
        newBarcode = BarcodeGeneratorService.generateUPCA();
        break;
      case 'Code128':
        newBarcode = BarcodeGeneratorService.generateCode128();
        break;
      default:
        newBarcode = BarcodeGeneratorService.generateEAN13();
    }
    
    setState(() {
      _generatedBarcode = newBarcode;
    });
  }

  @override
  void initState() {
    super.initState();
    _generateBarcode();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generar Código de Barras'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona el tipo de código:'),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _barcodeTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                  _generateBarcode();
                }
              },
            ),
            
            const SizedBox(height: 20),
            
            if (_generatedBarcode != null)
              Center(
                child: BarcodeDisplayWidget(
                  barcode: _generatedBarcode!,
                  width: 180,
                  height: 60,
                  showCopyButton: false,
                  showTypeInfo: false,
                ),
              ),
            
            const SizedBox(height: 16),
            
            Center(
              child: TextButton.icon(
                onPressed: _generateBarcode,
                icon: const Icon(Icons.refresh),
                label: const Text('Generar Nuevo'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _generatedBarcode != null
              ? () {
                  widget.onBarcodeGenerated(_generatedBarcode!);
                  Navigator.of(context).pop();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Usar Código'),
        ),
      ],
    );
  }
}
