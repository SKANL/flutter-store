import 'dart:math';

class BarcodeGeneratorService {
  static final Random _random = Random();
  
  /// Genera un código de barras EAN-13 válido
  static String generateEAN13() {
    // Los primeros 12 dígitos son aleatorios (excluyendo el dígito de verificación)
    String barcode = '';
    for (int i = 0; i < 12; i++) {
      barcode += _random.nextInt(10).toString();
    }
    
    // Calcular el dígito de verificación
    int checkDigit = _calculateEAN13CheckDigit(barcode);
    return barcode + checkDigit.toString();
  }
  
  /// Genera un código de barras Code128 con prefijo personalizado
  static String generateCode128({String prefix = 'STR'}) {
    // Generar número secuencial de 6 dígitos
    String sequence = '';
    for (int i = 0; i < 6; i++) {
      sequence += _random.nextInt(10).toString();
    }
    
    return prefix + sequence;
  }
  
  /// Genera un código de barras UPC-A válido
  static String generateUPCA() {
    // Los primeros 11 dígitos son aleatorios
    String barcode = '';
    for (int i = 0; i < 11; i++) {
      barcode += _random.nextInt(10).toString();
    }
    
    // Calcular el dígito de verificación
    int checkDigit = _calculateUPCACheckDigit(barcode);
    return barcode + checkDigit.toString();
  }
  
  /// Valida si un código de barras EAN-13 es válido
  static bool isValidEAN13(String barcode) {
    if (barcode.length != 13) return false;
    if (!RegExp(r'^\d+$').hasMatch(barcode)) return false;
    
    String mainPart = barcode.substring(0, 12);
    int providedCheckDigit = int.parse(barcode.substring(12));
    int calculatedCheckDigit = _calculateEAN13CheckDigit(mainPart);
    
    return providedCheckDigit == calculatedCheckDigit;
  }
  
  /// Valida si un código de barras UPC-A es válido
  static bool isValidUPCA(String barcode) {
    if (barcode.length != 12) return false;
    if (!RegExp(r'^\d+$').hasMatch(barcode)) return false;
    
    String mainPart = barcode.substring(0, 11);
    int providedCheckDigit = int.parse(barcode.substring(11));
    int calculatedCheckDigit = _calculateUPCACheckDigit(mainPart);
    
    return providedCheckDigit == calculatedCheckDigit;
  }
  
  /// Detecta el tipo de código de barras basado en su formato
  static String detectBarcodeType(String barcode) {
    if (barcode.length == 13 && RegExp(r'^\d+$').hasMatch(barcode)) {
      return 'EAN-13';
    }
    if (barcode.length == 12 && RegExp(r'^\d+$').hasMatch(barcode)) {
      return 'UPC-A';
    }
    if (barcode.length == 8 && RegExp(r'^\d+$').hasMatch(barcode)) {
      return 'EAN-8';
    }
    if (RegExp(r'^[A-Z0-9\-\.\s\$\/\+%]+$').hasMatch(barcode)) {
      return 'Code128';
    }
    return 'Desconocido';
  }
  
  /// Calcula el dígito de verificación para EAN-13
  static int _calculateEAN13CheckDigit(String barcode) {
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i.isEven) ? digit : digit * 3;
    }
    int remainder = sum % 10;
    return (remainder == 0) ? 0 : 10 - remainder;
  }
  
  /// Calcula el dígito de verificación para UPC-A
  static int _calculateUPCACheckDigit(String barcode) {
    int sum = 0;
    for (int i = 0; i < 11; i++) {
      int digit = int.parse(barcode[i]);
      sum += (i.isEven) ? digit * 3 : digit;
    }
    int remainder = sum % 10;
    return (remainder == 0) ? 0 : 10 - remainder;
  }
}
