import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/menu_catalog.dart';
import 'cloudinary_image.dart';

class MenuProductCard extends StatelessWidget {
  const MenuProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAdd,
  });

  final MenuProduct product;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CloudinaryImage(
                  url: product.imageUrl,
                  fallbackAsset: product.imageAsset,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  semanticLabel: product.name,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'P${product.price}',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (onAdd != null) ...[
                const SizedBox(width: 6),
                IconButton.filled(
                  tooltip: 'Add ${product.name}',
                  onPressed: onAdd,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
