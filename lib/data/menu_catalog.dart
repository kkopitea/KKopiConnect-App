import 'package:flutter/material.dart';

class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final IconData icon;
  final int sortOrder;

  IconData get displayIcon => switch (id) {
    'milktea' => Icons.local_drink_outlined,
    'coffee' => Icons.coffee_outlined,
    'snacks' => Icons.fastfood_outlined,
    'frappe' => Icons.soup_kitchen_outlined,
    'fruit_tea' => Icons.emoji_food_beverage_outlined,
    _ => icon,
  };

  factory MenuCategory.fromFirestore(String id, Map<String, dynamic> data) =>
      MenuCategory(
        id: id,
        name: data['name'] as String? ?? '',
        icon:
            _categoryIcons[data['iconKey'] as String?] ??
            Icons.category_rounded,
        sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

const _categoryIcons = <String, IconData>{
  'milktea': Icons.local_drink_rounded,
  'coffee': Icons.coffee_rounded,
  'snacks': Icons.fastfood_rounded,
  'frappe': Icons.soup_kitchen_rounded,
  'fruitTea': Icons.emoji_food_beverage_rounded,
  'default': Icons.category_rounded,
};

class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.categoryIds,
    this.isBestSeller = false,
    this.isNew = false,
    this.isClassic = false,
    this.imageAsset = 'assets/images/welcome_drink.png',
    this.imageUrl,
    this.sizes = const [],
    this.sugarLevels = const [],
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final String categoryId;
  final List<String> categoryIds;
  final bool isBestSeller;
  final bool isNew;
  final bool isClassic;
  final String imageAsset;
  final String? imageUrl;
  final List<(String, int)> sizes;
  final List<String> sugarLevels;

  static MenuProduct? fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final name = data['name'];
    final rawPrice = data['price'] ?? data['basePrice'];
    final available = data['available'] ?? data['isAvailable'];
    if (name is! String || rawPrice is! num || available != true) return null;

    final rawCategory = data['category'] ?? data['categoryId'];
    final rawCategories = data['categories'];
    final categories = rawCategories is List
        ? rawCategories.whereType<String>().toList()
        : rawCategory is String
        ? [rawCategory]
        : <String>[];
    final categoryIds = categories
        .map(_categoryIdForValue)
        .where((categoryId) => categoryId.isNotEmpty)
        .toSet()
        .toList();
    final categoryId = categoryIds.firstOrNull ?? '';
    final rawSizes = data['sizes'];
    final sizes = rawSizes is List
        ? rawSizes
              .whereType<Map>()
              .where(
                (size) =>
                    size['name'] is String &&
                    (size['additionalPrice'] ?? size['additional']) is num,
              )
              .map(
                (size) => (
                  size['name'] as String,
                  ((size['additionalPrice'] ?? size['additional']) as num)
                      .toInt(),
                ),
              )
              .toList()
        : <(String, int)>[];
    final rawSugarLevels = data['sugarLevels'];

    return MenuProduct(
      id: id,
      name: name,
      description: data['description'] is String
          ? data['description'] as String
          : '',
      price: rawPrice.toInt(),
      categoryId: categoryId,
      categoryIds: categoryIds,
      isBestSeller: data['isBestSeller'] == true,
      isNew: data['isNew'] == true,
      isClassic: data['isClassic'] == true,
      imageUrl: data['imageUrl'] is String ? data['imageUrl'] as String : null,
      sizes: sizes,
      sugarLevels: rawSugarLevels is List
          ? rawSugarLevels.whereType<String>().toList()
          : [],
    );
  }
}

String _categoryIdForValue(String value) {
  final category = menuCategories.where(
    (item) =>
        item.id.toLowerCase() == value.toLowerCase() ||
        item.name.toLowerCase() == value.toLowerCase(),
  );
  return category.isEmpty ? value.trim() : category.first.id;
}

const defaultMenuCategories = <MenuCategory>[
  MenuCategory(
    id: 'milktea',
    name: 'Milktea',
    icon: Icons.local_drink_rounded,
  ),
  MenuCategory(id: 'coffee', name: 'Coffee', icon: Icons.coffee_rounded),
  MenuCategory(id: 'snacks', name: 'Snacks', icon: Icons.fastfood_rounded),
  MenuCategory(id: 'frappe', name: 'Frappe', icon: Icons.soup_kitchen_rounded),
  MenuCategory(
    id: 'fruit_tea',
    name: 'Fruit Tea',
    icon: Icons.emoji_food_beverage_rounded,
  ),
];

List<MenuCategory> menuCategories = List.unmodifiable(defaultMenuCategories);
final ValueNotifier<List<MenuCategory>> menuCategoriesNotifier =
    ValueNotifier(menuCategories);

void updateMenuCategories(List<MenuCategory> categories) {
  menuCategories = List.unmodifiable(
    categories.isEmpty ? defaultMenuCategories : categories,
  );
  menuCategoriesNotifier.value = menuCategories;
}

List<MenuProduct> menuProducts = <MenuProduct>[
  MenuProduct(
    id: 'iced-americano-caramel',
    name: 'Iced Americano Caramel',
    description: 'Bold, refreshing iced black coffee sweetened with a smooth swirl of rich caramel syrup.',
    price: 50,
    categoryId: 'coffee',
    categoryIds: ['coffee'],
    isBestSeller: true,
    isNew: true,
  ),
  MenuProduct(
    id: 'vanilla-americano-latte-tea',
    name: 'Vanilla Americano Latte Tea',
    description: 'A refreshing blend of bold espresso, creamy milk, and sweet vanilla over chewy boba pearls.',
    price: 50,
    categoryId: 'milktea',
    categoryIds: ['milktea', 'coffee'],
    isBestSeller: true,
  ),
  MenuProduct(
    id: 'caramel-caffuccino',
    name: 'Caramel Caffuccino',
    description: 'A warm, comforting cup of rich espresso and frothy milk, balanced with a sweet splash of caramel.',
    price: 50,
    categoryId: 'coffee',
    categoryIds: ['coffee'],
    isClassic: true,
  ),
  MenuProduct(
    id: 'pearl-milk-tea',
    name: 'White Chocolate Milk Tea',
    description: 'Classic milk tea served with chewy tapioca pearls.',
    price: 60,
    categoryId: 'milktea',
    categoryIds: ['milktea'],
    isBestSeller: true,
    isClassic: true,
  ),
  MenuProduct(
    id: 'oreo-smoothie',
    name: 'Oreo Smoothie',
    description: 'A cool and creamy cookie smoothie.',
    price: 90,
    categoryId: 'frappe',
    categoryIds: ['frappe'],
  ),
  MenuProduct(
    id: 'mango-fruit-tea',
    name: 'Mango Fruit Tea',
    description: 'Bright fruit tea with a refreshing mango finish.',
    price: 65,
    categoryId: 'fruit_tea',
    categoryIds: ['fruit_tea'],
    isNew: true,
  ),
  MenuProduct(
    id: 'cheese-snack',
    name: 'Cream Cheese Snack',
    description: 'A savory bite to pair with your drink.',
    price: 40,
    categoryId: 'snacks',
    categoryIds: ['snacks'],
  ),
];
