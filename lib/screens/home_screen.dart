import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/advertisement.dart';
import '../data/menu_catalog.dart';
import '../data/order_draft.dart';
import '../state/cart_store.dart';
import 'category_products_screen.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
import '../widgets/advertisement_carousel.dart';
import '../widgets/menu_product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onSeeAllCategories,
    this.onNavigateTab,
  });

  final VoidCallback onSeeAllCategories;
  final ValueChanged<int>? onNavigateTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    menuCategoriesNotifier.addListener(_categoriesChanged);
  }

  @override
  void dispose() {
    menuCategoriesNotifier.removeListener(_categoriesChanged);
    super.dispose();
  }

  void _categoriesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.orange,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 96,
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'KKOPI.TEA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Notifications',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => NotificationsScreen(
                              onNavigateTab: widget.onNavigateTab,
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: 96,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 24, 14, 24),
                  children: [
                    AdvertisementCarousel(onSelect: _selectAdvertisement),
                    const SizedBox(height: 18),
                    _SectionHeading(
                      title: 'Categories',
                      onSeeAll: widget.onSeeAllCategories,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 116,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: menuCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final category = menuCategories[index];
                          return SizedBox(
                            width: 68,
                            child: _HomeCategoryButton(
                              icon: category.displayIcon,
                              label: category.name,
                              onTap: () => _openCategory(category.id),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeading(
                      title: 'All Products',
                      onSeeAll: widget.onSeeAllCategories,
                    ),
                    const SizedBox(height: 10),
                    for (final product in menuProducts) ...[
                      MenuProductCard(
                        product: product,
                        onTap: () => _openProduct(product),
                        onAdd: () {
                          CartStore.add(OrderDraft(product: product));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectAdvertisement(Advertisement advertisement) {
    for (final product in menuProducts) {
      if (product.id == advertisement.productId) {
        _openProduct(product);
        return;
      }
    }
    widget.onSeeAllCategories();
  }

  void _openProduct(MenuProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          product: product,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );
  }

  void _openCategory(String categoryId) {
    final matching = menuCategories.where((item) => item.id == categoryId);
    if (matching.isEmpty) return;
    final category = matching.first;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryProductsScreen(
          category: category,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.orange,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('See all', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

class _HomeCategoryButton extends StatelessWidget {
  const _HomeCategoryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE2BD),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black87, size: 27),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
