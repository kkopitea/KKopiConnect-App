import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/advertisement.dart';
import '../data/menu_catalog.dart';
import 'category_products_screen.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
import '../widgets/advertisement_carousel.dart';
import '../widgets/cloudinary_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSeeAllCategories});

  final VoidCallback onSeeAllCategories;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _branch = 'Urdaneta City';

  static const _homeCategories = [
    (Icons.local_drink_outlined, 'milk-tea', 'Milktea'),
    (Icons.coffee_outlined, 'coffee', 'Coffee'),
    (Icons.fastfood_outlined, 'snacks', 'Snacks'),
    (Icons.soup_kitchen_outlined, 'frappe', 'Frappe'),
    (Icons.emoji_food_beverage_outlined, 'fruit-tea', 'Fruit Tea'),
  ];

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
                            builder: (_) => const NotificationsScreen(),
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
                    _BranchSelector(branch: _branch, onTap: _chooseBranch),
                    const SizedBox(height: 14),
                    AdvertisementCarousel(onSelect: _selectAdvertisement),
                    const SizedBox(height: 18),
                    _SectionHeading(
                      title: 'Categories',
                      onSeeAll: widget.onSeeAllCategories,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 116,
                      child: Row(
                        children: [
                          for (final category in _homeCategories)
                            Expanded(
                              child: _HomeCategoryButton(
                                icon: category.$1,
                                label: category.$3,
                                onTap: () => _openCategory(category.$2),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeading(
                      title: 'All Products',
                      onSeeAll: widget.onSeeAllCategories,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 174,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: menuProducts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final product = menuProducts[index];
                          return _BestSellerCard(
                            product: product,
                            onTap: () => _openProduct(product),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseBranch() async {
    const branches = ['Urdaneta City', 'Dagupan City', 'San Carlos City'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Available branches',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            for (final branch in branches)
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(branch),
                trailing: branch == _branch
                    ? const Icon(Icons.check_circle, color: AppColors.orange)
                    : null,
                onTap: () => Navigator.pop(sheetContext, branch),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _branch = selected);
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
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _openCategory(String categoryId) {
    final category = menuCategories.firstWhere((item) => item.id == categoryId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryProductsScreen(category: category),
      ),
    );
  }
}

class _BranchSelector extends StatelessWidget {
  const _BranchSelector({required this.branch, required this.onTap});

  final String branch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E7E7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available branches',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      branch,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.orange,
              ),
            ],
          ),
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

class _BestSellerCard extends StatelessWidget {
  const _BestSellerCard({required this.product, required this.onTap});

  final MenuProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = menuCategories.firstWhere(
      (item) => item.id == product.categoryId,
    );

    return SizedBox(
      width: 210,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8E8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CloudinaryImage(
                      url: product.imageUrl,
                      fallbackAsset: product.imageAsset,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      semanticLabel: product.name,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              category.icon,
                              color: AppColors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'P${product.price}',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
