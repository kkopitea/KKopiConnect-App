import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/data/menu_catalog.dart';
import 'package:kkopiconnect_app/data/order_draft.dart';
import 'package:kkopiconnect_app/screens/favorites_screen.dart';
import 'package:kkopiconnect_app/screens/notifications_screen.dart';
import 'package:kkopiconnect_app/screens/search_screen.dart';
import 'package:kkopiconnect_app/state/favorites_store.dart';
import 'package:kkopiconnect_app/state/orders_store.dart';

void main() {
  setUp(() {
    FavoritesStore.productIds.value = <String>{};
    OrdersStore.orders.value = [];
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

    expect(find.text('Special Promo'), findsOneWidget);
    expect(find.text('Loyalty Reward'), findsOneWidget);
    expect(find.text('Order Pending'), findsNothing);
  });
}
