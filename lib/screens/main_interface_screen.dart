import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/menu_catalog.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'chatbot_screen.dart';
import 'home_screen.dart';
import 'order_list_screen.dart';
import 'profile_screen.dart';

class MainInterfaceScreen extends StatefulWidget {
  const MainInterfaceScreen({super.key});

  @override
  State<MainInterfaceScreen> createState() => _MainInterfaceScreenState();
}

class _MainInterfaceScreenState extends State<MainInterfaceScreen> {
  int _selectedIndex = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _productsSubscription;

  @override
  void initState() {
    super.initState();
    menuProducts = [];
    _productsSubscription = FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen((snapshot) {
          final items = snapshot.docs.where((doc) {
            final data = doc.data();
            return data['isAvailable'] == true &&
                data['name'] is String &&
                data['basePrice'] is num;
          }).map((doc) {
            final data = doc.data();
            final categoryId = data['categoryId'] as String? ?? '';
            final rawSizes = data['sizes'];
            final sizes = rawSizes is List
                ? rawSizes.whereType<Map>().where((size) =>
                    size['name'] is String &&
                    (size['additionalPrice'] ?? size['additional']) is num)
                    .map((size) => (
                      size['name'] as String,
                      ((size['additionalPrice'] ?? size['additional']) as num).toInt(),
                    )).toList()
                : <(String, int)>[];
            final rawSugar = data['sugarLevels'];
            return MenuProduct(
              id: doc.id,
              name: data['name'] as String,
              description: data['description'] as String? ?? '',
              price: (data['basePrice'] as num).toInt(),
              categoryId: categoryId,
              categoryIds: [categoryId],
              imageUrl: data['imageUrl'] as String?,
              sizes: sizes,
              sugarLevels: rawSugar is List
                  ? rawSugar.whereType<String>().toList()
                  : [],
            );
          }).toList();
          if (mounted) setState(() => menuProducts = items);
        }, onError: (Object error) {
          debugPrint('Unable to load menu products: $error');
        });
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  List<Widget> get _pages => <Widget>[
    HomeScreen(onSeeAllCategories: () => _selectTab(1)),
    CategoriesScreen(onNavigateTab: _selectTab),
    CartScreen(),
    OrderListScreen(),
    ProfileScreen(onNavigateTab: _selectTab),
  ];

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  static const _navigationItems = [
    (Icons.home_rounded, 'Home'),
    (Icons.category_rounded, 'Categories'),
    (Icons.shopping_bag_outlined, 'Cart'),
    (Icons.receipt_long_rounded, 'Orders'),
    (Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      floatingActionButton: _selectedIndex == 4
          ? null
          : FloatingActionButton.extended(
              heroTag: 'main-ai-chat-fab',
              tooltip: 'Chat with KKOPI.TEA Assistant',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ChatbotScreen()),
              ),
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.smart_toy_rounded, size: 25),
              label: const Text(
                'KKOPI.BOT',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(4, 7, 4, bottomInset + 7),
        child: Row(
          children: [
            for (var index = 0; index < _navigationItems.length; index++)
              Expanded(
                child: _NavigationItem(
                  icon: _navigationItems[index].$1,
                  label: _navigationItems[index].$2,
                  selected: _selectedIndex == index,
                  onTap: () => _selectTab(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.orange : AppColors.iconMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
