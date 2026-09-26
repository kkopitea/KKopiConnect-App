import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/menu_catalog.dart';
import '../state/favorites_store.dart';
import '../widgets/cloudinary_image.dart';
import '../widgets/curved_content_page.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.onBrowseMenu});

  final VoidCallback onBrowseMenu;

  @override
  Widget build(BuildContext context) {
    return CurvedContentPage(
      title: 'Favorites',
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: FavoritesStore.productIds,
        builder: (context, favoriteIds, _) {
          final products = menuProducts
              .where((product) => favoriteIds.contains(product.id))
              .toList();
          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 42,
                      color: AppColors.orange,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No favorites yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap the heart on a drink to save it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: onBrowseMenu,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Browse menu'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = products[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: CloudinaryImage(
                      url: product.imageUrl,
                      fallbackAsset: product.imageAsset,
                      width: 54,
                      height: 54,
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'P${product.price}',
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove from favorites',
                    onPressed: () => FavoritesStore.remove(product.id),
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.orange,
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
