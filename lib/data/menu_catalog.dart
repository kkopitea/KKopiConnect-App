import 'package:flutter/material.dart';

import 'drink_extra.dart';

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
    'iced_lattes' => Icons.local_cafe_outlined,
    'bubble_teas' => Icons.local_drink_outlined,
    'fruit_teas' => Icons.emoji_food_beverage_outlined,
    'non_caffeine' => Icons.soup_kitchen_outlined,
    'amerikano' => Icons.coffee_outlined,
    _ => icon,
  };

  factory MenuCategory.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) => MenuCategory(
    id: id,
    name: data['name'] as String? ?? '',
    icon: _categoryIcons[data['iconKey'] as String?] ?? Icons.category_rounded,
    sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
  );
}

const _categoryIcons = <String, IconData>{
  'icedLattes': Icons.local_cafe_rounded,
  'bubbleTeas': Icons.local_drink_rounded,
  'fruitTea': Icons.emoji_food_beverage_rounded,
  'nonCaffeine': Icons.soup_kitchen_rounded,
  'amerikano': Icons.coffee_rounded,
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
    this.addOns = const [],
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
  final List<DrinkExtra> addOns;

  List<(String, int)> get availableSizes {
    int? explicitPriceFor(int ounces) {
      final matchingSize = sizes.where(
        (size) => RegExp(
          '(?<!\\d)$ounces\\s*(?:oz|ounces?)\\b',
          caseSensitive: false,
        ).hasMatch(size.$1),
      );
      return matchingSize.firstOrNull?.$2;
    }

    final hasExplicitOunceSizes = sizes.any(
      (size) => RegExp(
        r'(?<!\d)(16|22)\s*(?:oz|ounces?)\b',
        caseSensitive: false,
      ).hasMatch(size.$1),
    );
    if (hasExplicitOunceSizes) {
      return [
        ('16oz', explicitPriceFor(16) ?? 0),
        ('22oz', explicitPriceFor(22) ?? 0),
      ];
    }
    if (sizes.length > 1) {
      return [('16oz', sizes[0].$2), ('22oz', sizes[1].$2)];
    }
    return [('16oz', 0), ('22oz', sizes.firstOrNull?.$2 ?? 0)];
  }

  static MenuProduct? fromFirestore(String id, Map<String, dynamic> data) {
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
    final rawAddOns = data['addons'] ?? data['addOns'];
    final addOns = rawAddOns is List
        ? rawAddOns
              .whereType<Map>()
              .map(
                (option) => DrinkExtra.fromMap(
                  option['id'] is String ? option['id'] as String : '',
                  Map<String, dynamic>.from(option),
                ),
              )
              .where(
                (option) =>
                    option.isAvailable &&
                    option.name.trim().isNotEmpty &&
                    option.price >= 0,
              )
              .toList()
        : <DrinkExtra>[];
    addOns.sort((first, second) {
      final byOrder = first.sortOrder.compareTo(second.sortOrder);
      return byOrder != 0 ? byOrder : first.name.compareTo(second.name);
    });

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
      addOns: addOns,
    );
  }
}

enum MenuProductsLoadPhase { loading, loaded, error }

class MenuProductsLoadStatus {
  const MenuProductsLoadStatus({
    required this.phase,
    this.documentCount,
    this.availableCount,
    this.errorCode,
  });

  const MenuProductsLoadStatus.loading()
    : this(phase: MenuProductsLoadPhase.loading);

  final MenuProductsLoadPhase phase;
  final int? documentCount;
  final int? availableCount;
  final String? errorCode;

  String message(String projectId) => switch (phase) {
    MenuProductsLoadPhase.loading => 'Connecting to Firebase...',
    MenuProductsLoadPhase.error =>
      'Could not read products from Firebase project $projectId '
          '(${errorCode ?? 'unknown error'}). Check sign-in, Firestore rules, '
          'network access, and App Check enforcement.',
    MenuProductsLoadPhase.loaded when documentCount == 0 =>
      'Connected to Firebase project $projectId, but its products collection '
          'has no documents. Check the Firebase Console project or restore '
          'the product records from a backup.',
    MenuProductsLoadPhase.loaded when availableCount == 0 =>
      'Firebase returned $documentCount product document(s), but none are '
          'available to the app. Each needs a name, price/basePrice, and '
          'available/isAvailable set to true.',
    _ => '',
  };
}

final ValueNotifier<MenuProductsLoadStatus> menuProductsLoadStatus =
    ValueNotifier(const MenuProductsLoadStatus.loading());

String _categoryIdForValue(String value) {
  final normalizedValue = value.trim().toLowerCase();
  final category = menuCategories.where(
    (item) =>
        item.id.toLowerCase() == normalizedValue ||
        item.name.toLowerCase() == normalizedValue,
  );
  if (category.isNotEmpty) return category.first.id;
  return switch (normalizedValue) {
    'icedlattes' || 'iced latte' || 'iced lattes' => 'iced_lattes',
    'coffee' => 'amerikano',
    'milk tea' || 'milktea' => 'bubble_teas',
    'fruit tea' || 'fruit_tea' => 'fruit_teas',
    'frappe' || 'snacks' => 'non_caffeine',
    _ => value.trim(),
  };
}

const defaultMenuCategories = <MenuCategory>[
  MenuCategory(
    id: 'iced_lattes',
    name: 'Iced Lattes',
    icon: Icons.local_cafe_rounded,
  ),
  MenuCategory(
    id: 'bubble_teas',
    name: 'Bubble Teas',
    icon: Icons.local_drink_rounded,
  ),
  MenuCategory(
    id: 'fruit_teas',
    name: 'Fruit Teas',
    icon: Icons.emoji_food_beverage_rounded,
  ),
  MenuCategory(
    id: 'non_caffeine',
    name: 'Non Caffeine',
    icon: Icons.soup_kitchen_rounded,
  ),
  MenuCategory(id: 'amerikano', name: 'Amerikano', icon: Icons.coffee_rounded),
];

List<MenuCategory> menuCategories = List.unmodifiable(defaultMenuCategories);
final ValueNotifier<List<MenuCategory>> menuCategoriesNotifier = ValueNotifier(
  menuCategories,
);

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
    description:
        'Bold, refreshing iced black coffee sweetened with a smooth swirl of rich caramel syrup.',
    price: 50,
    categoryId: 'amerikano',
    categoryIds: ['amerikano'],
    isBestSeller: true,
    isNew: true,
  ),
  MenuProduct(
    id: 'vanilla-americano-latte-tea',
    name: 'Vanilla Americano Latte Tea',
    description:
        'A refreshing blend of bold espresso, creamy milk, and sweet vanilla over chewy boba pearls.',
    price: 50,
    categoryId: 'iced_lattes',
    categoryIds: ['iced_lattes'],
    isBestSeller: true,
  ),
  MenuProduct(
    id: 'caramel-caffuccino',
    name: 'Caramel Caffuccino',
    description:
        'A warm, comforting cup of rich espresso and frothy milk, balanced with a sweet splash of caramel.',
    price: 50,
    categoryId: 'iced_lattes',
    categoryIds: ['iced_lattes'],
    isClassic: true,
  ),
  MenuProduct(
    id: 'pearl-milk-tea',
    name: 'White Chocolate Milk Tea',
    description: 'Classic milk tea served with chewy tapioca pearls.',
    price: 60,
    categoryId: 'bubble_teas',
    categoryIds: ['bubble_teas'],
    isBestSeller: true,
    isClassic: true,
  ),
  MenuProduct(
    id: 'oreo-smoothie',
    name: 'Oreo Smoothie',
    description: 'A cool and creamy cookie smoothie.',
    price: 90,
    categoryId: 'non_caffeine',
    categoryIds: ['non_caffeine'],
  ),
  MenuProduct(
    id: 'mango-fruit-tea',
    name: 'Mango Fruit Tea',
    description: 'Bright fruit tea with a refreshing mango finish.',
    price: 65,
    categoryId: 'fruit_teas',
    categoryIds: ['fruit_teas'],
    isNew: true,
  ),
  MenuProduct(
    id: 'cheese-snack',
    name: 'Cream Cheese Snack',
    description: 'A savory bite to pair with your drink.',
    price: 40,
    categoryId: 'non_caffeine',
    categoryIds: ['non_caffeine'],
  ),
];
