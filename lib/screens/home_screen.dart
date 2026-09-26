import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/menu_catalog.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
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
    (Icons.local_drink_outlined, 'Milk Tea'),
    (Icons.coffee_outlined, 'Coffee'),
    (Icons.local_cafe_outlined, 'Fruit Tea'),
    (Icons.sell_outlined, 'Add-ons'),
    (Icons.checkroom_outlined, 'Merch'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              decoration: const BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                children: [
                  _BranchSelector(branch: _branch, onTap: _chooseBranch),
                  const SizedBox(height: 14),
                  _HomePromoBanner(onOrderNow: _orderNow),
                  const SizedBox(height: 18),
                  _SectionHeading(
                    title: 'Categories',
                    onSeeAll: widget.onSeeAllCategories,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 98,
                    child: Row(
                      children: [
                        for (final category in _homeCategories)
                          Expanded(
                            child: _HomeCategoryButton(
                              icon: category.$1,
                              label: category.$2,
                              onTap: widget.onSeeAllCategories,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionHeading(
                    title: 'Best Sellers',
                    onSeeAll: widget.onSeeAllCategories,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 154,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final products = [
                          menuProducts[0],
                          menuProducts[3],
                          menuProducts[2],
                        ];
                        final labels = [
                          'Iced Americano',
                          'White Chocolate Milk Tea',
                          'Caramel Caffuccino',
                        ];
                        final backgrounds = [
                          const Color(0xFFFFE0AC),
                          const Color(0xFFFFBF72),
                          const Color(0xFFCC741C),
                        ];
                        return _BestSellerCard(
                          product: products[index],
                          label: labels[index],
                          background: backgrounds[index],
                          onTap: () => _openProduct(products[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'home-menu-fab',
        tooltip: 'Browse menu',
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        onPressed: widget.onSeeAllCategories,
        child: const Icon(Icons.local_cafe_rounded),
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

  void _orderNow() => _openProduct(menuProducts.first);

  void _openProduct(MenuProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(product: product),
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

class _HomePromoBanner extends StatelessWidget {
  const _HomePromoBanner({required this.onOrderNow});

  final VoidCallback onOrderNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 158,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Buy 1, Get 1 Free!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'SIP. SMILE. REPEAT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your everyday coffee and milk tea made with love.',
                  maxLines: 3,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 29,
                  child: FilledButton(
                    onPressed: onOrderNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Order Now!'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Image.asset(
            'assets/images/login_drinks.png',
            width: 126,
            height: 128,
            fit: BoxFit.contain,
          ),
        ],
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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
          child: const Text('See all', style: TextStyle(fontSize: 11)),
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
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE2BD),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black87, size: 23),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _BestSellerCard extends StatelessWidget {
  const _BestSellerCard({
    required this.product,
    required this.label,
    required this.background,
    required this.onTap,
  });

  final MenuProduct product;
  final String label;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CloudinaryImage(
                    url: product.imageUrl,
                    fallbackAsset: product.imageAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
