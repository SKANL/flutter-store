import 'package:flutter/material.dart';

class AppTextStyles {
  // Title style
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black, // Default color, can be overridden
  );

  // Description style
  static const TextStyle description = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  // Small text style
  static const TextStyle small = TextStyle(
    fontSize: 12,
    color: Colors.black54,
  );

  // Button text style
  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
