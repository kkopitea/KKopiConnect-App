import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/advertisement.dart';
import '../data/menu_catalog.dart';
import '../data/order_draft.dart';
import '../state/cart_store.dart';
import '../state/product_ratings_store.dart';
import 'cart_screen.dart';
import 'category_products_screen.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import '../widgets/advertisement_carousel.dart';
import '../widgets/curved_content_page.dart';
import '../widgets/menu_product_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({
    super.key,
    this.onNavigateTab,
    this.selectedCategoryId,
  });

  final ValueChanged<int>? onNavigateTab;
  final String? selectedCategoryId;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const _filters = ['All', 'Best Sellers', 'New', 'Classic'];
  String _activeFilter = 'All';
  String? _activeCategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _activeCategoryId = widget.selectedCategoryId;
    menuCategoriesNotifier.addListener(_categoriesChanged);
    ProductRatingsStore.summaries.addListener(_categoriesChanged);
  }

  @override
  void didUpdateWidget(covariant CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      _activeCategoryId = widget.selectedCategoryId;
    }
  }

  @override
  void dispose() {
    menuCategoriesNotifier.removeListener(_categoriesChanged);
    ProductRatingsStore.summaries.removeListener(_categoriesChanged);
    super.dispose();
  }

  void _categoriesChanged() {
    if (!mounted) return;
    if (_activeCategoryId != null &&
        !menuCategories.any((category) => category.id == _activeCategoryId)) {
      _activeCategoryId = null;
    }
    setState(() {});
  }

  List<MenuProduct> get _visibleProducts {
    final matchingCategory = menuProducts.where((product) {
      final matchesCategory =
          _activeCategoryId == null ||
          product.categoryIds.contains(_activeCategoryId);
      return matchesCategory &&
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    if (_activeFilter == 'Best Sellers') {
      return ProductRatingsStore.bestRatedProducts(matchingCategory);
    }
    return matchingCategory.where((product) {
      return switch (_activeFilter) {
        'New' => product.isNew,
        'Classic' => product.isClassic,
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _visibleProducts;
    return CurvedContentPage(
      title: 'MENU',
      actions: [
        IconButton(
          tooltip: 'Search products',
          onPressed: _openSearch,
          color: Colors.white,
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: 'Open cart',
          onPressed: () {
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(2);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CartScreen()),
              );
            }
          },
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
                  for (final product in products)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MenuProductCard(
                        product: product,
                        onTap: () => _openProduct(product),
                        onAdd: () => _addProduct(product),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                leading: Icon(category.displayIcon, color: AppColors.orange),
                title: Text(category.name),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CategoryProductsScreen(
                        category: category,
                        onNavigateTab: widget.onNavigateTab,
                      ),
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
        builder: (_) => ProductDetailScreen(
          product: product,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );
  }

  void _addProduct(MenuProduct product) {
    CartStore.add(OrderDraft(product: product));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
  }

  void _selectAdvertisement(Advertisement advertisement) {
    final products = advertisement.selectedProductIds
        .map(
          (id) => menuProducts.where((product) => product.id == id).firstOrNull,
        )
        .whereType<MenuProduct>()
        .toList(growable: false);
    if (products.isEmpty) {
      _showCategories();
    } else if (products.length == 1) {
      _openProduct(products.first);
    } else {
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  advertisement.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final product in products)
                ListTile(
                  title: Text(product.name),
                  subtitle: Text('${AppColors.pesoSymbol}${product.price}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openProduct(product);
                  },
                ),
            ],
          ),
        ),
      );
    }
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
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.orangeGradient : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
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
      height: 76,
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
                    label: _categoryLabel(category),
                    icon: category.displayIcon,
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

  String _categoryLabel(MenuCategory category) {
    if (category.id == 'milktea') return 'Milk Tea';
    return category.name
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
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
    final color = selected ? Colors.white : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.orangeGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 23, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
