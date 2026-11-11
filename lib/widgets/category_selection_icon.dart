import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CategorySelectionIcon extends StatelessWidget {
  const CategorySelectionIcon({
    super.key,
    required this.categoryId,
    required this.fallbackIcon,
    required this.size,
    required this.color,
  });

  final String? categoryId;
  final IconData fallbackIcon;
  final double size;
  final Color color;

  static const _assets = <String?, String>{
    null: 'assets/category_icons/all.svg',
    'iced_lattes': 'assets/category_icons/iced_lattes.svg',
    'bubble_teas': 'assets/category_icons/bubble_teas.svg',
    'fruit_teas': 'assets/category_icons/fruit_teas.svg',
    'non_caffeine': 'assets/category_icons/non_caffeine.svg',
    'amerikano': 'assets/category_icons/amerikano.svg',
  };

  @override
  Widget build(BuildContext context) {
    final asset = _assets[categoryId];
    if (asset == null) {
      return Icon(fallbackIcon, size: size, color: color);
    }

    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}
