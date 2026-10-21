import 'package:flutter/material.dart';

import '../app_colors.dart';

class CategoryIconCircle extends StatelessWidget {
  const CategoryIconCircle({super.key, required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.orange,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.52),
    );
  }
}
