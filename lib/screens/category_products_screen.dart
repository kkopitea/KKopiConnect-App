import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/menu_catalog.dart';
import '../data/order_draft.dart';
import '../state/cart_store.dart';
import 'product_detail_screen.dart';
import '../widgets/menu_product_card.dart';

class CategoryProductsScreen extends StatelessWidget {
  const CategoryProductsScreen({
    super.key,
    required this.category,
    this.onNavigateTab,
  });

  final MenuCategory category;
  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final products = menuProducts
        .where((product) => product.categoryIds.contains(category.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      body: products.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.displayIcon,
                      size: 44,
                      color: AppColors.orange,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No items in ${category.name} yet',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = products[index];
                return MenuProductCard(
                  product: product,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProductDetailScreen(
                        product: product,
                        onNavigateTab: onNavigateTab,
                      ),
                    ),
                  ),
                  onAdd: () {
                    CartStore.add(OrderDraft(product: product));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${product.name} added to cart')),
                    );
                  },
                );
              },
            ),
    );
  }
}
