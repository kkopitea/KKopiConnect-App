import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/advertisement.dart';
import '../data/advertisement_repository.dart';
import '../data/app_notification.dart';
import '../data/app_notification_repository.dart';
import '../data/menu_catalog.dart';
import '../data/order_repository.dart';
import '../data/placed_order.dart';
import '../data/order_draft.dart';
import '../services/advertisement_navigation.dart';
import '../state/cart_store.dart';
import '../state/orders_store.dart';
import '../state/product_ratings_store.dart';
import 'category_products_screen.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
import '../widgets/advertisement_carousel.dart';
import '../widgets/category_icon_circle.dart';
import '../widgets/menu_product_card.dart';
import '../widgets/menu_products_status_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onSeeAllCategories,
    this.onNavigateTab,
    this.onSelectCategory,
    this.advertisements,
    this.onRefresh,
  });

  final VoidCallback onSeeAllCategories;
  final ValueChanged<int>? onNavigateTab;
  final ValueChanged<String>? onSelectCategory;
  final Stream<List<Advertisement>>? advertisements;
  final Future<void> Function()? onRefresh;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    menuCategoriesNotifier.addListener(_categoriesChanged);
    ProductRatingsStore.summaries.addListener(_categoriesChanged);
  }

  @override
  void dispose() {
    menuCategoriesNotifier.removeListener(_categoriesChanged);
    ProductRatingsStore.summaries.removeListener(_categoriesChanged);
    super.dispose();
  }

  void _categoriesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF87818),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.orangeGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 96,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: AppColors.orangeGradient,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'KKOPI'),
                                  TextSpan(
                                    text: '.TEA',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _NotificationBell(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => NotificationsScreen(
                                  onNavigateTab: widget.onNavigateTab,
                                  onSelectCategory: widget.onSelectCategory,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                top: 96,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: widget.onRefresh ?? _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 24, 14, 24),
                      children: [
                        AdvertisementCarousel(
                          advertisements: widget.advertisements,
                          onSelect: _selectAdvertisement,
                        ),
                        const SizedBox(height: 18),
                        _SectionHeading(
                          title: 'CATEGORIES',
                          onSeeAll: widget.onSeeAllCategories,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: menuCategories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final category = menuCategories[index];
                              return SizedBox(
                                width: 72,
                                child: _HomeCategoryButton(
                                  categoryId: category.id,
                                  icon: category.displayIcon,
                                  label: _categoryLabel(category),
                                  onTap: () => _openCategory(category.id),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        const MenuProductsStatusBanner(),
                        _SectionHeading(
                          title: 'Best Selling',
                          onSeeAll: widget.onSeeAllCategories,
                        ),
                        const SizedBox(height: 10),
                        for (final product
                            in ProductRatingsStore.bestRatedProducts(
                              menuProducts,
                              limit: 3,
                            )) ...[
                          MenuProductCard(
                            product: product,
                            onTap: () => _openProduct(product),
                            onAdd: () {
                              CartStore.add(OrderDraft(product: product));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.name} added to cart',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    if (mounted) setState(() {});
  }

  void _selectAdvertisement(Advertisement advertisement) {
    AdvertisementNavigation.open(
      context,
      advertisement,
      onNavigateTab: widget.onNavigateTab,
      onSelectCategory: widget.onSelectCategory,
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

  void _openCategory(String categoryId) {
    final matching = menuCategories.where((item) => item.id == categoryId);
    if (matching.isEmpty) return;
    final category = matching.first;
    if (widget.onSelectCategory case final onSelectCategory?) {
      onSelectCategory(category.id);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryProductsScreen(
          category: category,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );
  }

  String _categoryLabel(MenuCategory category) {
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

class _NotificationBell extends StatefulWidget {
  const _NotificationBell({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  final Set<String> _notificationIds = {};
  final Set<String> _readNotificationIds = {};
  StreamSubscription<List<AppNotification>>? _notificationsSubscription;
  StreamSubscription<List<Advertisement>>? _advertisementsSubscription;
  StreamSubscription<List<PlacedOrder>>? _ordersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _readSubscription;
  String? _userId;
  bool _readStateLoaded = false;

  @override
  void initState() {
    super.initState();
    OrdersStore.orders.addListener(_ordersChanged);

    try {
      _userId = FirebaseAuth.instance.currentUser?.uid;
    } catch (error) {
      debugPrint('Unable to initialize notification badge auth: $error');
    }
    _readStateLoaded = _userId == null;

    try {
      _notificationsSubscription = AppNotificationRepository()
          .watchActive()
          .listen(
            (notifications) => _replaceIds(
              'notification-',
              notifications.map((notification) => notification.id),
            ),
            onError: (Object error) {
              debugPrint('Unable to load notification badge items: $error');
            },
          );
    } catch (error) {
      debugPrint('Unable to subscribe to notification badge items: $error');
    }
    try {
      _advertisementsSubscription = AdvertisementRepository()
          .watchActive()
          .listen(
            (advertisements) => _replaceIds(
              'promotion-',
              advertisements.map((advertisement) => advertisement.id),
            ),
            onError: (Object error) {
              debugPrint('Unable to load promotion badge items: $error');
            },
          );
    } catch (error) {
      debugPrint('Unable to subscribe to promotion badge items: $error');
    }

    final userId = _userId;
    if (userId != null) {
      try {
        _ordersSubscription = FirestoreOrderRepository()
            .watchOrders(userId)
            .listen(
              (orders) =>
                  _replaceIds('order-', orders.map((order) => order.id)),
              onError: (Object error) {
                debugPrint('Unable to load order notification badge: $error');
              },
            );
        _readSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notificationReads')
            .where('isRead', isEqualTo: true)
            .snapshots()
            .listen(
              (snapshot) {
                if (!mounted) return;
                setState(() {
                  _readNotificationIds
                    ..clear()
                    ..addAll(snapshot.docs.map((document) => document.id));
                  _readStateLoaded = true;
                });
              },
              onError: (Object error) {
                debugPrint(
                  'Unable to load notification badge read state: $error',
                );
              },
            );
      } catch (error) {
        debugPrint(
          'Unable to subscribe to notification badge read state: $error',
        );
      }
    }
  }

  void _replaceIds(String prefix, Iterable<String> ids) {
    if (!mounted) return;
    setState(() {
      _notificationIds.removeWhere((id) => id.startsWith(prefix));
      _notificationIds.addAll(ids.map((id) => '$prefix$id'));
    });
  }

  void _ordersChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasUnreadNotifications {
    if (!_readStateLoaded) return false;
    final allIds = {
      ..._notificationIds,
      ...OrdersStore.orders.value.map((order) => 'order-${order.id}'),
    };
    return allIds.any((id) => !_readNotificationIds.contains(id));
  }

  @override
  void dispose() {
    OrdersStore.orders.removeListener(_ordersChanged);
    unawaited(_notificationsSubscription?.cancel());
    unawaited(_advertisementsSubscription?.cancel());
    unawaited(_ordersSubscription?.cancel());
    unawaited(_readSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: _hasUnreadNotifications
        ? 'Notifications (unread)'
        : 'Notifications',
    onPressed: widget.onPressed,
    icon: SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 2,
            bottom: 1,
            child: Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          if (_hasUnreadNotifications)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    ),
  );
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
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
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
          child: const Text('See all', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

class _HomeCategoryButton extends StatelessWidget {
  const _HomeCategoryButton({
    required this.categoryId,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String categoryId;
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
            CategoryIconCircle(
              categoryId: categoryId,
              fallbackIcon: icon,
              size: 60,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
