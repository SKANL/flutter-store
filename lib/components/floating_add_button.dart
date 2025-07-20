import 'package:flutter/material.dart';
import '../core/app_color.dart';

class FloatingAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;

  const FloatingAddButton({
    Key? key,
    required this.onPressed,
    this.tooltip = 'Agregar',
    this.icon = Icons.add,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      tooltip: tooltip,
      elevation: 6,
      child: Icon(icon),
    );
  }
}
