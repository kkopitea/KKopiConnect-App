import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'category_selection_icon.dart';

class CategoryIconCircle extends StatelessWidget {
  const CategoryIconCircle({
    super.key,
    required this.categoryId,
    required this.fallbackIcon,
    required this.size,
  });

  final String categoryId;
  final IconData fallbackIcon;
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
      child: CategorySelectionIcon(
        categoryId: categoryId,
        fallbackIcon: fallbackIcon,
        size: 28,
        color: Colors.white,
      ),
    );
  }
}
