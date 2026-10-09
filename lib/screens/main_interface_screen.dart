import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/menu_catalog.dart';
import '../data/menu_category_repository.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'chatbot_screen.dart';
import 'home_screen.dart';
import 'order_list_screen.dart';
import 'profile_screen.dart';
import '../widgets/main_bottom_navigation_bar.dart';

class MainInterfaceScreen extends StatefulWidget {
  const MainInterfaceScreen({super.key});

  @override
  State<MainInterfaceScreen> createState() => _MainInterfaceScreenState();
}

class _MainInterfaceScreenState extends State<MainInterfaceScreen> {
  int _selectedIndex = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _productsSubscription;
  StreamSubscription<List<MenuCategory>>? _categoriesSubscription;

  @override
  void initState() {
    super.initState();
    menuProducts = [];
    _categoriesSubscription = MenuCategoryRepository()
        .watchCategories()
        .listen(
          (categories) {
            updateMenuCategories(categories);
          },
          onError: (Object error) {
            debugPrint('Unable to load menu categories: $error');
          },
        );
    _productsSubscription = FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen(
          (snapshot) {
            final items = snapshot.docs
                .map((doc) => MenuProduct.fromFirestore(doc.id, doc.data()))
                .whereType<MenuProduct>()
                .toList();
            if (mounted) setState(() => menuProducts = items);
          },
          onError: (Object error) {
            debugPrint('Unable to load menu products: $error');
          },
        );
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _productsSubscription?.cancel();
    super.dispose();
  }

  List<Widget> get _pages => <Widget>[
    HomeScreen(
      onSeeAllCategories: () => _selectTab(1),
      onNavigateTab: _selectTab,
    ),
    CategoriesScreen(onNavigateTab: _selectTab),
    CartScreen(onNavigateTab: _selectTab),
    OrderListScreen(),
    ProfileScreen(onNavigateTab: _selectTab),
  ];

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      floatingActionButton: _selectedIndex == 2 || _selectedIndex == 4
          ? null
          : FloatingActionButton(
              heroTag: 'main-ai-chat-fab',
              tooltip: 'Chat with KKOPI.TEA Assistant',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ChatbotScreen()),
              ),
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              child: const Icon(Icons.smart_toy_rounded, size: 25),
            ),
      bottomNavigationBar: MainBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _selectTab,
      ),
    );
  }
}
