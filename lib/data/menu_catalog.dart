import 'package:flutter/material.dart';

class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final IconData icon;
}

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
}

const menuCategories = <MenuCategory>[
  MenuCategory(
    id: 'milk-tea',
    name: 'Milk Tea',
    icon: Icons.local_drink_rounded,
  ),
  MenuCategory(id: 'coffee', name: 'Coffee', icon: Icons.coffee_rounded),
  MenuCategory(
    id: 'fruit-tea',
    name: 'Fruit Tea',
    icon: Icons.emoji_food_beverage_rounded,
  ),
  MenuCategory(id: 'boba', name: 'Boba', icon: Icons.icecream_rounded),
  MenuCategory(
    id: 'smoothie',
    name: 'Smoothie',
    icon: Icons.soup_kitchen_rounded,
  ),
  MenuCategory(id: 'snacks', name: 'Snacks', icon: Icons.fastfood_rounded),
];

const menuProducts = <MenuProduct>[
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
    categoryId: 'milk-tea',
    categoryIds: ['milk-tea', 'coffee', 'boba'],
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
    categoryId: 'milk-tea',
    categoryIds: ['milk-tea', 'boba'],
    isBestSeller: true,
    isClassic: true,
  ),
  MenuProduct(
    id: 'oreo-smoothie',
    name: 'Oreo Smoothie',
    description: 'A cool and creamy cookie smoothie.',
    price: 90,
    categoryId: 'smoothie',
    categoryIds: ['smoothie'],
  ),
  MenuProduct(
    id: 'mango-fruit-tea',
    name: 'Mango Fruit Tea',
    description: 'Bright fruit tea with a refreshing mango finish.',
    price: 65,
    categoryId: 'fruit-tea',
    categoryIds: ['fruit-tea'],
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
