import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/menu_catalog.dart';
import '../data/menu_category_repository.dart';
import '../state/favorites_store.dart';
import '../state/product_ratings_store.dart';
import '../services/push_notification_service.dart';
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
  String? _requestedCategoryId;
  bool _isListeningToMenuData = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _productsSubscription;
  StreamSubscription<List<MenuCategory>>? _categoriesSubscription;

  @override
  void initState() {
    super.initState();
    menuProducts = [];
    menuProductsLoadStatus.value = const MenuProductsLoadStatus.loading();
    FavoritesStore.startListening();
    ProductRatingsStore.startListening();
    PushNotificationService.instance.setDashboardNavigation(
      onNavigateTab: _selectTab,
      onSelectCategory: _openCategory,
    );
    unawaited(PushNotificationService.instance.start());
    _listenToMenuData();
  }

  void _listenToMenuData() {
    _isListeningToMenuData = true;
    _categoriesSubscription = MenuCategoryRepository().watchCategories().listen(
      (categories) {
        updateMenuCategories(categories);
      },
      onError: (Object error) {
        if (!_isListeningToMenuData ||
            FirebaseAuth.instance.currentUser == null) {
          return;
        }
        debugPrint('Unable to load menu categories: $error');
        _showFirebaseReadError('menu categories', error);
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
            menuProducts = items;
            menuProductsLoadStatus.value = MenuProductsLoadStatus(
              phase: MenuProductsLoadPhase.loaded,
              documentCount: snapshot.docs.length,
              availableCount: items.length,
            );
            if (mounted) setState(() {});
          },
          onError: (Object error) {
            debugPrint('Unable to load menu products: $error');
            menuProductsLoadStatus.value = MenuProductsLoadStatus(
              phase: MenuProductsLoadPhase.error,
              errorCode: error is FirebaseException
                  ? error.code
                  : error.runtimeType.toString(),
            );
          },
        );
  }

  Future<void> _refreshMenuData() async {
    await _stopListeningToMenuData();
    if (!mounted) return;
    menuProductsLoadStatus.value = const MenuProductsLoadStatus.loading();
    _listenToMenuData();
  }

  Future<void> _stopListeningToMenuData() async {
    _isListeningToMenuData = false;
    final categoriesSubscription = _categoriesSubscription;
    final productsSubscription = _productsSubscription;
    _categoriesSubscription = null;
    _productsSubscription = null;
    await categoriesSubscription?.cancel();
    await productsSubscription?.cancel();
  }

  void _showFirebaseReadError(String dataType, Object error) {
    if (!mounted) return;
    final code = error is FirebaseException
        ? error.code
        : error.runtimeType.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not load $dataType from Firebase ($code).'),
      ),
    );
  }

  @override
  void dispose() {
    PushNotificationService.instance.clearDashboardNavigation();
    unawaited(_stopListeningToMenuData());
    super.dispose();
  }

  List<Widget> get _pages => <Widget>[
    HomeScreen(
      onSeeAllCategories: () => _selectTab(1),
      onNavigateTab: _selectTab,
      onSelectCategory: _openCategory,
      onRefresh: _refreshMenuData,
    ),
    CategoriesScreen(
      onNavigateTab: _selectTab,
      selectedCategoryId: _requestedCategoryId,
      onRefresh: _refreshMenuData,
    ),
    CartScreen(onNavigateTab: _selectTab),
    OrderListScreen(onNavigateTab: _selectTab),
    ProfileScreen(
      onNavigateTab: _selectTab,
      onSelectCategory: _openCategory,
      onBeforeLogout: _stopListeningToMenuData,
    ),
  ];

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  void _openCategory(String categoryId) {
    setState(() {
      _requestedCategoryId = categoryId;
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canUseChatbot =
        FirebaseAuth.instance.currentUser?.isAnonymous == false;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      floatingActionButton:
          !canUseChatbot || _selectedIndex == 2 || _selectedIndex == 4
          ? null
          : FloatingActionButton(
              heroTag: 'main-ai-chat-fab',
              tooltip: 'Chat with KKOPI.TEA Assistant',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatbotScreen(onNavigateTab: _selectTab),
                ),
              ),
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              shape: const CircleBorder(
                side: BorderSide(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 25),
            ),
      bottomNavigationBar: MainBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _selectTab,
      ),
    );
  }
}
