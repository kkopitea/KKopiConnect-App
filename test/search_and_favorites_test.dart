import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/data/advertisement.dart';
import 'package:kkopiconnect_app/data/app_notification.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkopiconnect_app/data/menu_catalog.dart';
import 'package:kkopiconnect_app/data/order_draft.dart';
import 'package:kkopiconnect_app/data/placed_order.dart';
import 'package:kkopiconnect_app/data/search_analytics_repository.dart';
import 'package:kkopiconnect_app/data/product_favorites_repository.dart';
import 'package:kkopiconnect_app/screens/categories_screen.dart';
import 'package:kkopiconnect_app/screens/favorites_screen.dart';
import 'package:kkopiconnect_app/screens/home_screen.dart';
import 'package:kkopiconnect_app/screens/notifications_screen.dart';
import 'package:kkopiconnect_app/screens/search_screen.dart';
import 'package:kkopiconnect_app/state/favorites_store.dart';
import 'package:kkopiconnect_app/state/orders_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    updateMenuCategories(defaultMenuCategories);
    FavoritesStore.productIds.value = <String>{};
    OrdersStore.orders.value = [];
    FavoritesStore.repositoryForTesting = null;
  });

  test('menu categories match the requested lineup', () {
    expect(menuCategories.map((category) => category.name).toList(), [
      'Iced Lattes',
      'Bubble Teas',
      'Fruit Teas',
      'Non Caffeine',
      'Amerikano',
    ]);
    expect(menuProducts.first.categoryIds, contains('amerikano'));
  });

  testWidgets('menu no longer shows a Classic section', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CategoriesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Classic'), findsNothing);
    expect(find.text('All'), findsWidgets);
    expect(find.text('Iced Lattes'), findsWidgets);
    expect(find.text('Bubble Teas'), findsWidgets);
    expect(find.text('Fruit Teas'), findsWidgets);
    expect(find.text('Non Caffeine'), findsWidgets);
    expect(find.text('Amerikano'), findsWidgets);
    expect(find.byType(SvgPicture), findsNWidgets(6));
  });

  test('popular search terms resolve only to complete product names', () {
    final names = SearchAnalyticsRepository.matchingProductNames(
      searchTerms: [
        'iced americano caramel',
        'coffee',
        'Mango Fruit',
        'MANGO FRUIT TEA',
      ],
      productNames: menuProducts.map((product) => product.name),
    );

    expect(names, ['Iced Americano Caramel', 'Mango Fruit Tea']);
  });

  testWidgets('search filters menu products as the query changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(onNavigateTab: (_) {}, onSelectCategory: (_) {}),
      ),
    );

    expect(find.text('Recent Searches'), findsOneWidget);
    expect(find.text('Popular Searches'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Iced Lattes');
    await tester.pumpAndSettle();

    expect(find.text('Search results'), findsOneWidget);
    expect(find.text('Caramel Caffuccino'), findsOneWidget);
    expect(find.text('Vanilla Americano Latte Tea'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(5));
  });

  testWidgets(
    'adding a customized product from search keeps the menu screen mounted',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(home: CategoriesScreen(onNavigateTab: (_) {})),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Search products'));
      await tester.pumpAndSettle();

      final product = menuProducts.first;
      await tester.enterText(find.byType(TextField), product.name);
      await tester.pumpAndSettle();
      await tester.tap(find.text(product.name).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Customize'));
      await tester.pumpAndSettle();
      final addToCart = find.textContaining('Add to cart');
      final addToCartButton = tester.widget<FilledButton>(
        find.ancestor(of: addToCart, matching: find.byType(FilledButton)),
      );
      addToCartButton.onPressed!();
      await tester.pumpAndSettle();

      expect(find.text('MENU'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'each search category circle selects its category in the menu section',
    (tester) async {
      updateMenuCategories([
        for (final category in defaultMenuCategories)
          if (category.id == 'amerikano')
            MenuCategory(
              id: category.id,
              name: 'amerikano',
              icon: category.icon,
              sortOrder: category.sortOrder,
            )
          else
            category,
      ]);
      await tester.pumpWidget(const MaterialApp(home: CategoriesScreen()));
      await tester.pumpAndSettle();

      const categories = [
        ('Iced Lattes', 'iced_lattes'),
        ('Bubble Teas', 'bubble_teas'),
        ('Fruit Teas', 'fruit_teas'),
        ('Non Caffeine', 'non_caffeine'),
        ('Amerikano', 'amerikano'),
      ];

      for (final (label, categoryId) in categories) {
        await tester.tap(find.byTooltip('Search products'));
        await tester.pumpAndSettle();

        final searchCircle = find.text(label).last;
        await tester.ensureVisible(searchCircle);
        await tester.tap(searchCircle);
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == label &&
                widget.properties.selected == true,
          ),
          findsOneWidget,
          reason: '$label should be selected in the Categories screen',
        );
        expect(
          find.text('Oreo Smoothie'),
          categoryId == 'non_caffeine' ? findsOneWidget : findsNothing,
        );
      }
    },
  );

  testWidgets('popular searches stay above results after opening a product', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(onNavigateTab: (_) {}, onSelectCategory: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pumpAndSettle();

    final popularHeading = find.text('Popular Searches');
    final resultsHeading = find.text('Search results');
    expect(popularHeading, findsOneWidget);
    expect(
      tester.getTopLeft(popularHeading).dy,
      lessThan(tester.getTopLeft(resultsHeading).dy),
    );

    await tester.tap(find.text('Iced Americano Caramel').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
    await tester.pumpAndSettle();

    expect(popularHeading, findsOneWidget);
    expect(
      tester.getTopLeft(popularHeading).dy,
      lessThan(tester.getTopLeft(resultsHeading).dy),
    );
  });

  testWidgets('recent searches are saved on the device and reloaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(onNavigateTab: (_) {}, onSelectCategory: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mango Tea');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList('recentSearches'), ['Mango Tea']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(onNavigateTab: (_) {}, onSelectCategory: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mango Tea'), findsOneWidget);
  });

  testWidgets('order notification switches to the Orders tab', (tester) async {
    var selectedTab = -1;
    OrdersStore.orders.value = [
      PlacedOrder(
        id: '#KK777',
        items: [OrderDraft(product: menuProducts.first)],
        fulfillment: 'Pickup',
        paymentMethod: 'Pay At The Counter',
        instructions: '',
        status: 'Pending',
        createdAt: DateTime(2026),
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          onNavigateTab: (index) => selectedTab = index,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Order Pending'));
    await tester.pumpAndSettle();

    expect(selectedTab, 3);
    expect(find.text('MY ORDERS'), findsNothing);
  });

  testWidgets('saved order notifications survive an empty local store', (
    tester,
  ) async {
    final order = PlacedOrder(
      id: 'KK009',
      items: [OrderDraft(product: menuProducts.first, quantity: 2)],
      fulfillment: 'Pickup',
      paymentMethod: 'Pay At The Counter',
      instructions: '',
      status: 'Pending',
      createdAt: DateTime(2026),
    );
    OrdersStore.orders.value = [];
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          advertisements: Stream.value(const <Advertisement>[]),
          notifications: Stream.value(const <AppNotification>[]),
          orderUpdates: Stream.value([order]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();

    expect(find.text('Order Pending'), findsOneWidget);
    expect(
      find.textContaining('${menuProducts.first.name} × 2'),
      findsOneWidget,
    );
  });

  testWidgets('promotion notification opens its image and announcement', (
    tester,
  ) async {
    final advertisement = Advertisement.fromMap('weekend-promo', {
      'title': 'Weekend offer',
      'eyebrow': 'This weekend only',
      'description': 'Save on iced lattes this weekend.',
      'buttonLabel': 'Shop the offer',
      'imageUrl': 'https://example.com/promo.png',
      'isActive': true,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          advertisements: Stream.value([advertisement]),
          notifications: Stream.value(const <AppNotification>[]),
          onNavigateTab: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Weekend offer'));
    await tester.pumpAndSettle();

    expect(find.text('This weekend only'.toUpperCase()), findsOneWidget);
    expect(find.text('Save on iced lattes this weekend.'), findsOneWidget);
    expect(find.text('Shop the offer'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image && widget.semanticLabel == 'Promotion image',
      ),
      findsOneWidget,
    );
  });

  testWidgets('description-only promotion appears in notifications', (
    tester,
  ) async {
    final notification = AppNotification.fromFirestore('new-promotion', {
      'title': 'New promotion',
      'description': 'Save on iced lattes this week.',
      'type': 'Promotion',
      'isActive': true,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          advertisements: Stream.value(const <Advertisement>[]),
          notifications: Stream.value([notification!]),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('New promotion'), findsOneWidget);
    expect(find.text('Save on iced lattes this week.'), findsOneWidget);
    await tester.tap(find.text('Promotion'));
    await tester.pump();
    expect(find.text('New promotion'), findsOneWidget);
  });

  testWidgets('promotion action uses the dashboard destination', (
    tester,
  ) async {
    var selectedTab = -1;
    final advertisement = Advertisement.fromMap('menu-promo', {
      'title': 'Menu offer',
      'description': 'See the menu offer.',
      'buttonLabel': 'Order now',
      'buttonActionType': 'menu',
      'isActive': true,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          advertisements: Stream.value([advertisement]),
          notifications: Stream.value(const <AppNotification>[]),
          onNavigateTab: (index) => selectedTab = index,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Menu offer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Order now'));
    await tester.pumpAndSettle();

    expect(selectedTab, 0);
    expect(find.text('Menu offer'), findsOneWidget);
    expect(find.text('Promotion'), findsOneWidget);
  });

  testWidgets('system notification opens its release version details', (
    tester,
  ) async {
    const update = AppNotification(
      id: 'release-2-1-0',
      title: 'App update',
      message: 'A new version is available with performance improvements.',
      type: 'System',
      isActive: true,
      sortOrder: 1,
      version: '2.1.0',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(
          advertisements: Stream.value(const <Advertisement>[]),
          notifications: Stream.value(const [update]),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('App update'));
    await tester.pumpAndSettle();

    expect(find.text('Version 2.1.0'), findsOneWidget);
    expect(
      find.text('A new version is available with performance improvements.'),
      findsOneWidget,
    );
  });

  testWidgets('top category carousel filters products by category', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CategoriesScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Amerikano').first);
    await tester.pumpAndSettle();

    expect(find.text('Iced Americano Caramel'), findsOneWidget);
    expect(find.text('Oreo Smoothie'), findsNothing);
  });

  testWidgets(
    'dashboard category buttons navigate with that category selected',
    (tester) async {
      String? selectedCategoryId;
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            onSeeAllCategories: () {},
            onSelectCategory: (categoryId) => selectedCategoryId = categoryId,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SvgPicture), findsNWidgets(5));

      await tester.tap(find.text('Amerikano').first);

      expect(selectedCategoryId, 'amerikano');
    },
  );

  testWidgets('notification bell marks unread orders with a red dot', (
    tester,
  ) async {
    OrdersStore.orders.value = [
      PlacedOrder(
        id: 'KK888',
        items: [OrderDraft(product: menuProducts.first)],
        fulfillment: 'Pickup',
        paymentMethod: 'Pay At The Counter',
        instructions: '',
        status: 'Pending',
        createdAt: DateTime(2026),
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(onSeeAllCategories: () {}, onNavigateTab: (_) {}),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Notifications (unread)'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                const Color(0xFFD32F2F),
      ),
      findsOneWidget,
    );

    OrdersStore.orders.value = [];
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('categories screen opens with the requested category selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategoriesScreen(selectedCategoryId: 'amerikano'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amerikano'), findsWidgets);
    expect(find.text('Iced Americano Caramel'), findsOneWidget);
    expect(find.text('Oreo Smoothie'), findsNothing);
  });

  testWidgets('categories screen refreshes when pulled down', (tester) async {
    var refreshCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CategoriesScreen(
          onRefresh: () async {
            refreshCount++;
          },
        ),
      ),
    );

    await tester.drag(find.byType(ListView).last, const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(refreshCount, 1);
  });

  testWidgets('favorites page reflects added and removed products', (
    tester,
  ) async {
    FavoritesStore.repositoryForTesting = _FakeFavoritesRepository();
    await tester.pumpWidget(
      MaterialApp(home: FavoritesScreen(onBrowseMenu: () {})),
    );

    expect(find.text('No favorites yet'), findsOneWidget);

    await FavoritesStore.toggle('iced-americano-caramel');
    await tester.pumpAndSettle();
    expect(find.text('Iced Americano Caramel'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pumpAndSettle();
    expect(find.text('No favorites yet'), findsOneWidget);
  });

  testWidgets('notification filters show only their matching items', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));

    expect(find.text('Order Update'), findsNothing);
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('No notifications in this section'), findsOneWidget);

    OrdersStore.createOrder(
      items: [OrderDraft(product: menuProducts.first)],
      fulfillment: 'Pickup',
      paymentMethod: 'Pay At The Counter',
      instructions: '',
    );
    await tester.pumpAndSettle();
    expect(find.text('Order Pending'), findsOneWidget);

    await tester.tap(find.text('Promotion'));
    await tester.pumpAndSettle();

    expect(find.text('Special Promo'), findsNothing);
    expect(find.text('Loyalty Reward'), findsNothing);
    expect(find.text('Order Pending'), findsNothing);
  });

  testWidgets('notifications no longer show hard-coded demo content', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Special Promo'), findsNothing);
    expect(find.text('New Menu'), findsNothing);
    expect(find.text('Loyalty Reward'), findsNothing);
  });

  testWidgets('dismissed notification stays archived after reopening', (
    tester,
  ) async {
    const notification = AppNotification(
      id: 'persistent-message',
      title: 'Archived announcement',
      message: 'This announcement should stay archived.',
      type: 'System',
      isActive: true,
      sortOrder: 0,
    );

    Widget buildScreen() => MaterialApp(
      home: NotificationsScreen(
        advertisements: Stream.value(const <Advertisement>[]),
        notifications: Stream.value(const [notification]),
      ),
    );

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(find.text('Archived announcement'), findsOneWidget);

    await tester.drag(find.byType(Dismissible), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.text('Archived announcement'), findsNothing);
    expect(find.text('Notification archived on this device.'), findsOneWidget);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(find.text('Archived announcement'), findsNothing);
  });
}

class _FakeFavoritesRepository implements FavoritesRepository {
  @override
  Future<void> setFavorite(String productId, bool isFavorite) async {
    final updatedIds = Set<String>.from(FavoritesStore.productIds.value);
    if (isFavorite) {
      updatedIds.add(productId);
    } else {
      updatedIds.remove(productId);
    }
    FavoritesStore.productIds.value = updatedIds;
  }
}
