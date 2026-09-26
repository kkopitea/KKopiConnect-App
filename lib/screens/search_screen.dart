import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/menu_catalog.dart';
import '../widgets/cloudinary_image.dart';
import 'category_products_screen.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.onNavigateTab});

  final ValueChanged<int> onNavigateTab;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final List<String> _recentSearches = [
    'Brown Sugar Milk Tea',
    'Matcha Latte',
    'Taro Milk Tea',
    'Coffee',
  ];

  static const _popularSearches = [
    'Brown Sugar Milk Tea',
    'Okinawa Milk Tea',
    'Taro Milk Tea',
    'Wintermelon Milk Tea',
  ];

  static final _searchCategories = menuCategories
      .map((category) => (category, category.name))
      .toList();

  List<MenuProduct> get _results {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return menuProducts.where((product) {
      final category = menuCategories
          .where((item) => product.categoryIds.contains(item.id))
          .map((item) => item.name)
          .join(' ');
      return product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          category.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.orange,
              padding: const EdgeInsets.fromLTRB(12, 4, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back',
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Search',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _submitSearch,
                      decoration: InputDecoration(
                        hintText: 'Search drinks, categories...',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 22),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded, size: 20),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    if (_searchController.text.isNotEmpty) ...[
                      _SectionHeading(
                        icon: Icons.search_rounded,
                        title: 'Search results',
                        trailing: '${results.length}',
                      ),
                      const SizedBox(height: 6),
                      if (results.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No matching drinks or categories',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        )
                      else
                        for (final product in results)
                          _SearchProductRow(
                            product: product,
                            onTap: () => _openProduct(product),
                          ),
                      const SizedBox(height: 16),
                    ],
                    if (_recentSearches.isNotEmpty) ...[
                      Row(
                        children: [
                          const Expanded(
                            child: _SectionHeading(
                              icon: Icons.history_rounded,
                              title: 'Recent Searches',
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(_recentSearches.clear),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.orange,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Clear All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final term in List<String>.of(_recentSearches))
                            InputChip(
                              label: Text(
                                term,
                                style: const TextStyle(fontSize: 13),
                              ),
                              onPressed: () => _applySearch(term),
                              onDeleted: () =>
                                  setState(() => _recentSearches.remove(term)),
                              deleteIconColor: AppColors.orange,
                              backgroundColor: AppColors.orangeTint,
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionHeading(
                            icon: Icons.category_outlined,
                            title: 'Categories',
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateTab(1),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 116,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _searchCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 9),
                        itemBuilder: (context, index) {
                          final item = _searchCategories[index];
                          return _SearchCategoryTile(
                            category: item.$1,
                            label: item.$2,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    CategoryProductsScreen(category: item.$1),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _SectionHeading(
                      icon: Icons.local_fire_department_outlined,
                      title: 'Popular Searches',
                    ),
                    const SizedBox(height: 5),
                    for (final term in _popularSearches)
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          leading: const Icon(Icons.search_rounded, size: 19),
                          title: Text(
                            term,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _applySearch(term),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _SearchBottomNavigationBar(
        selectedIndex: 1,
        onTap: widget.onNavigateTab,
      ),
    );
  }

  void _submitSearch(String value) {
    final term = value.trim();
    if (term.isEmpty) return;
    setState(() {
      _recentSearches.remove(term);
      _recentSearches.insert(0, term);
      if (_recentSearches.length > 8) _recentSearches.removeLast();
    });
  }

  void _applySearch(String term) {
    _searchController.text = term;
    _submitSearch(term);
  }

  void _openProduct(MenuProduct product) {
    _submitSearch(_searchController.text);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.orange, size: 20),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
      ],
    );
  }
}

class _SearchCategoryTile extends StatelessWidget {
  const _SearchCategoryTile({
    required this.category,
    required this.label,
    required this.onTap,
  });

  final MenuCategory category;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0BC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, size: 36, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchProductRow extends StatelessWidget {
  const _SearchProductRow({required this.product, required this.onTap});

  final MenuProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CloudinaryImage(
            url: product.imageUrl,
            fallbackAsset: product.imageAsset,
            width: 56,
            height: 56,
          ),
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'P${product.price} · ${product.description}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, height: 1.3),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _SearchBottomNavigationBar extends StatelessWidget {
  const _SearchBottomNavigationBar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.category_rounded, 'Categories'),
    (Icons.shopping_bag_outlined, 'Cart'),
    (Icons.receipt_long_rounded, 'Orders'),
    (Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            for (var index = 0; index < _items.length; index++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _items[index].$1,
                        color: index == selectedIndex
                            ? AppColors.orange
                            : AppColors.iconMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _items[index].$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: index == selectedIndex
                              ? AppColors.orange
                              : AppColors.iconMuted,
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
}
