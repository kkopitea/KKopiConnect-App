import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkopiconnect_app/data/menu_catalog.dart';
import 'package:kkopiconnect_app/data/order_draft.dart';
import 'package:kkopiconnect_app/screens/categories_screen.dart';
import 'package:kkopiconnect_app/screens/favorites_screen.dart';
import 'package:kkopiconnect_app/screens/notifications_screen.dart';
import 'package:kkopiconnect_app/screens/search_screen.dart';
import 'package:kkopiconnect_app/state/favorites_store.dart';
import 'package:kkopiconnect_app/state/orders_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FavoritesStore.productIds.value = <String>{};
    OrdersStore.orders.value = [];
  });

  test('menu categories match the requested lineup', () {
    expect(menuCategories.map((category) => category.name).toList(), [
      'Milktea',
      'Coffee',
      'Snacks',
      'Frappe',
      'Fruit Tea',
    ]);
    expect(menuProducts.first.categoryIds, contains('coffee'));
  });

  testWidgets('search filters menu products as the query changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SearchScreen(onNavigateTab: (_) {})),
    );

    expect(find.text('Recent Searches'), findsOneWidget);
    expect(find.text('Popular Searches'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pumpAndSettle();

    expect(find.text('Search results'), findsOneWidget);
    expect(find.text('Iced Americano Caramel'), findsOneWidget);
    expect(find.text('Caramel Caffuccino'), findsOneWidget);
  });

  testWidgets('recent searches are saved on the device and reloaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SearchScreen(onNavigateTab: (_) {})),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mango Tea');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList('recentSearches'), ['Mango Tea']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(home: SearchScreen(onNavigateTab: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mango Tea'), findsOneWidget);
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

  testWidgets('favorites page reflects added and removed products', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: FavoritesScreen(onBrowseMenu: () {})),
    );

    expect(find.text('No favorites yet'), findsOneWidget);

    FavoritesStore.toggle('iced-americano-caramel');
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
