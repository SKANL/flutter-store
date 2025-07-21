import 'dart:ui';

class AppColors {
  static const Color primary = Color.fromARGB(255, 140, 146, 100);
  static const Color secondary = Color(0xffFFFFFF);
  static const Color accent = Color(0xffFF4081);

  //Background colors
  static const Color background = Color.fromARGB(255, 255, 246, 203);
  static const Color backgroundComponent = Color(0xffE0E0E0);
  static const Color backgroundComponentSelected = Color(0xffBDBDBD);

  //Text colors
  static const Color text = Color(0xff212121);
  
  // Status colors
  static const Color success = Color(0xff4CAF50);
  static const Color warning = Color(0xffFF9800);
  static const Color error = Color(0xffF44336);
  static const Color info = Color(0xff2196F3);
  
  // Product status colors
  static const Color statusGood = Color(0xff4CAF50);
  static const Color statusWarning = Color(0xffFF9800);
  static const Color statusExpired = Color(0xffF44336);
  
  // Inventory colors
  static const Color lowStock = Color(0xffF44336);
  static const Color normalStock = Color(0xff4CAF50);
  static const Color highStock = Color(0xff2196F3);
}

// Clase alternativa para compatibilidad
class AppColor {
  static const Color colorPrimario = Color.fromARGB(255, 140, 146, 100);
  static const Color colorSecundario = Color(0xffFFFFFF);
  static const Color colorTexto = Color(0xff212121);
  static const Color colorFondo = Color.fromARGB(255, 255, 246, 203);
}