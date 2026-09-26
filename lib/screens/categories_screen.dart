import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/advertisement.dart';
import '../data/menu_catalog.dart';
import '../data/order_draft.dart';
import '../state/cart_store.dart';
import 'cart_screen.dart';
import 'category_products_screen.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import '../widgets/advertisement_carousel.dart';
import '../widgets/cloudinary_image.dart';
import '../widgets/curved_content_page.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, this.onNavigateTab});

  final ValueChanged<int>? onNavigateTab;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const _filters = ['All', 'Best Sellers', 'New', 'Classic'];
  String _activeFilter = 'All';
  String? _activeCategoryId;
  String _searchQuery = '';

  List<MenuProduct> get _visibleProducts => menuProducts.where((product) {
    final matchesFilter = switch (_activeFilter) {
      'Best Sellers' => product.isBestSeller,
      'New' => product.isNew,
      'Classic' => product.isClassic,
      _ => true,
    };
    final matchesCategory =
        _activeCategoryId == null ||
        product.categoryIds.contains(_activeCategoryId);
    return matchesFilter &&
        matchesCategory &&
        product.name.toLowerCase().contains(_searchQuery.toLowerCase());
  }).toList();

  @override
  Widget build(BuildContext context) {
    final products = _visibleProducts;
    return CurvedContentPage(
      title: 'Menu',
      actions: [
        IconButton(
          tooltip: 'Search products',
          onPressed: _openSearch,
          color: Colors.white,
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: 'Open cart',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const CartScreen())),
          color: Colors.white,
          icon: const Icon(Icons.shopping_cart_checkout_rounded),
        ),
      ],
      body: Column(
        children: [
          _CategoryCarousel(
            selectedCategoryId: _activeCategoryId,
            onSelected: (categoryId) =>
                setState(() => _activeCategoryId = categoryId),
          ),
          Container(
            color: Colors.white,
            height: 60,
            child: Row(
              children: [
                for (final filter in _filters)
                  Expanded(
                    child: _FilterTab(
                      label: filter,
                      selected: filter == _activeFilter,
                      onTap: () => setState(() => _activeFilter = filter),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
              children: [
                AdvertisementCarousel(onSelect: _selectAdvertisement),
                const SizedBox(height: 10),
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text('Search: $_searchQuery')),
                        TextButton(
                          onPressed: () => setState(() => _searchQuery = ''),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                if (products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text('No products found')),
                  )
                else
                  for (var index = 0; index < products.length; index++)
                    _ProductRow(
                      product: products[index],
                      background:
                          _thumbnailColors[index % _thumbnailColors.length],
                      onOpen: () => _openProduct(products[index]),
                      onAdd: () => _addProduct(products[index]),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _thumbnailColors = [
    Color(0xFFFFE1A8),
    Color(0xFFFFC277),
    Color(0xFFCF741E),
    Color(0xFFFFE8CB),
  ];

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(
          onNavigateTab: (index) {
            Navigator.of(context).pop();
            widget.onNavigateTab?.call(index);
          },
        ),
      ),
    );
  }

  void _showCategories() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Browse categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            for (final category in menuCategories)
              ListTile(
                leading: Icon(category.icon, color: AppColors.orange),
                title: Text(category.name),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CategoryProductsScreen(category: category),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openProduct(MenuProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _addProduct(MenuProduct product) {
    CartStore.add(OrderDraft(product: product));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
  }

  void _selectAdvertisement(Advertisement advertisement) {
    for (final product in menuProducts) {
      if (product.id == advertisement.productId) {
        _openProduct(product);
        return;
      }
    }
    _showCategories();
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.orange : AppColors.textMuted,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.orange : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCarousel extends StatelessWidget {
  const _CategoryCarousel({
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CategoryTab(
                  label: 'All',
                  icon: Icons.grid_view_rounded,
                  selected: selectedCategoryId == null,
                  onTap: () => onSelected(null),
                ),
                for (final category in menuCategories)
                  _CategoryTab(
                    label: category.name,
                    icon: category.icon,
                    selected: selectedCategoryId == category.id,
                    onTap: () => onSelected(category.id),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.orange : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Icon(icon, size: 19, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 2,
                decoration: BoxDecoration(
                  color: selected ? AppColors.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.background,
    required this.onOpen,
    required this.onAdd,
  });

  final MenuProduct product;
  final Color background;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CloudinaryImage(
                    url: product.imageUrl,
                    fallbackAsset: product.imageAsset,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (product.isBestSeller) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Best Seller',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'P${product.price}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Material(
                  color: Colors.black,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onAdd,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE7E7E7)),
      ],
    );
  }
}
