import 'package:flutter/material.dart';
import '../core/app_color.dart';

class CardWidget extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const CardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.0, // Tamaño reducido para el título
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20.0, // Mantener tamaño para el valor
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
