import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      'Milk Tea',
      'Coffee',
      'Snacks',
      'Frappe',
      'Fruit Tea',
    ]);
    expect(menuProducts.first.categoryIds, contains('coffee'));
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

    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pumpAndSettle();

    expect(find.text('Search results'), findsOneWidget);
    expect(find.text('Iced Americano Caramel'), findsOneWidget);
    expect(find.text('Caramel Caffuccino'), findsOneWidget);
  });

  testWidgets(
    'each search category circle selects its category in the menu section',
    (tester) async {
      updateMenuCategories([
        for (final category in defaultMenuCategories)
          if (category.id == 'coffee')
            MenuCategory(
              id: category.id,
              name: 'coffee',
              icon: category.icon,
              sortOrder: category.sortOrder,
            )
          else
            category,
      ]);
      await tester.pumpWidget(const MaterialApp(home: CategoriesScreen()));
      await tester.pumpAndSettle();

      const categories = [
        ('Coffee', 'coffee'),
        ('Milk Tea', 'milktea'),
        ('Frappe', 'frappe'),
        ('Fruit Tea', 'fruit_tea'),
        ('Snacks', 'snacks'),
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
          categoryId == 'frappe' ? findsOneWidget : findsNothing,
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

  testWidgets('top category carousel filters products by category', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CategoriesScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Coffee').first);
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

      await tester.tap(find.text('Coffee').first);

      expect(selectedCategoryId, 'coffee');
    },
  );

  testWidgets('categories screen opens with the requested category selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CategoriesScreen(selectedCategoryId: 'coffee')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsWidgets);
    expect(find.text('Iced Americano Caramel'), findsOneWidget);
    expect(find.text('Oreo Smoothie'), findsNothing);
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
