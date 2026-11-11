import 'package:flutter/material.dart';

import '../data/advertisement.dart';
import '../data/menu_catalog.dart';
import '../screens/cart_screen.dart';
import '../screens/category_products_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/order_list_screen.dart';
import '../screens/product_detail_screen.dart';

class AdvertisementNavigation {
  const AdvertisementNavigation._();

  static void open(
    BuildContext context,
    Advertisement advertisement, {
    ValueChanged<int>? onNavigateTab,
    ValueChanged<String>? onSelectCategory,
  }) {
    final action = advertisement.effectiveButtonActionType;
    final target = advertisement.buttonTarget.trim();
    switch (action) {
      case 'product':
        final productId = target.isNotEmpty
            ? target
            : advertisement.productIdsForNavigation.firstOrNull;
        final product = productId == null
            ? null
            : menuProducts.where((item) => item.id == productId).firstOrNull;
        if (product == null) {
          _showUnavailable(
            context,
            'This advertised product is currently unavailable.',
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProductDetailScreen(
              product: product,
              onNavigateTab: onNavigateTab,
            ),
          ),
        );
        return;
      case 'category':
        final category = menuCategories
            .where((item) => item.id == target)
            .firstOrNull;
        if (category == null) {
          _showUnavailable(context, 'This advertised category is unavailable.');
          return;
        }
        if (onSelectCategory case final selectCategory?) {
          selectCategory(category.id);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CategoryProductsScreen(
                category: category,
                onNavigateTab: onNavigateTab,
              ),
            ),
          );
        }
        return;
      case 'menu':
        _navigateToTab(
          context,
          index: 0,
          onNavigateTab: onNavigateTab,
          fallback: const CategoriesScreen(),
        );
        return;
      case 'cart':
        _navigateToTab(
          context,
          index: 2,
          onNavigateTab: onNavigateTab,
          fallback: const CartScreen(),
        );
        return;
      case 'orders':
        _navigateToTab(
          context,
          index: 3,
          onNavigateTab: onNavigateTab,
          fallback: const OrderListScreen(),
        );
        return;
    }
  }

  static void _navigateToTab(
    BuildContext context, {
    required int index,
    required ValueChanged<int>? onNavigateTab,
    required Widget fallback,
  }) {
    if (onNavigateTab != null) {
      onNavigateTab(index);
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => fallback));
    }
  }

  static void _showUnavailable(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
