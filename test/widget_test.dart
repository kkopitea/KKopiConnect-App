// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kkopiconnect_app/main.dart';
import 'package:kkopiconnect_app/screens/cart_screen.dart';
import 'package:kkopiconnect_app/screens/chatbot_screen.dart';
import 'package:kkopiconnect_app/screens/customize_drink_screen.dart';
import 'package:kkopiconnect_app/screens/home_screen.dart';
import 'package:kkopiconnect_app/screens/order_type_screen.dart';
import 'package:kkopiconnect_app/screens/product_detail_screen.dart';
import 'package:kkopiconnect_app/data/menu_catalog.dart';
import 'package:kkopiconnect_app/data/order_draft.dart';
import 'package:kkopiconnect_app/services/chatbot_service.dart';
import 'package:kkopiconnect_app/state/cart_store.dart';

void main() {
  testWidgets('app starts on the splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KkopiTeaApp());

    expect(find.text('KKOPI.TEA'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('home rounded content panel fits a narrow screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(onSeeAllCategories: () {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('All Products'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat assistant answers menu price questions', (tester) async {
    final chatbotService = _FakeChatbotReplyService();
    await tester.pumpWidget(
      MaterialApp(home: ChatbotScreen(chatbotService: chatbotService)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Mango Fruit Tea price');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Here is the current menu information.'), findsOneWidget);
    expect(chatbotService.lastQuestion, 'Mango Fruit Tea price');
    expect(
      chatbotService.lastProducts.any(
        (product) => product.name == 'Mango Fruit Tea',
      ),
      isTrue,
    );
  });

  testWidgets('product actions stay pinned at the bottom on a small screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: ProductDetailScreen(product: menuProducts.first)),
    );
    await tester.pumpAndSettle();

    final customize = find.widgetWithText(OutlinedButton, 'Customize');
    final addToCart = find.widgetWithText(FilledButton, 'Add to cart');
    expect(customize, findsOneWidget);
    expect(addToCart, findsOneWidget);
    expect(
      find.ancestor(of: addToCart, matching: find.byType(Scrollable)),
      findsNothing,
    );
    for (final control in [find.text('Sizes'), find.text('Quantity')]) {
      expect(
        find.ancestor(of: control, matching: find.byType(Scrollable)),
        findsNothing,
      );
    }
    expect(
      tester.getRect(customize).top,
      lessThan(tester.getRect(addToCart).top),
    );
    expect(tester.getRect(addToCart).bottom, greaterThan(720));
    expect(tester.takeException(), isNull);
  });

  testWidgets('curved cart page keeps empty-state text in view', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    CartStore.clear();

    await tester.pumpWidget(const MaterialApp(home: CartScreen()));
    await tester.pumpAndSettle();

    expect(find.text('My Cart'), findsOneWidget);
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coffee Jelly is unchecked by default and after reset', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomizeDrinkScreen(
          draft: OrderDraft(product: menuProducts.first),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final coffeeJellyFinder = find.widgetWithText(
      CheckboxListTile,
      'Coffee Jelly (P30)',
    );
    await tester.scrollUntilVisible(
      find.text('Coffee Jelly (P30)'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(coffeeJellyFinder).value, isFalse);

    await tester.tap(coffeeJellyFinder);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(coffeeJellyFinder).value, isTrue);

    await tester.tap(find.byTooltip('Reset options'));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(coffeeJellyFinder).value, isFalse);
  });

  testWidgets('order type page has no duplicate bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderTypeScreen(
          drafts: [OrderDraft(product: menuProducts.first)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order type & payment method'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeChatbotReplyService implements ChatbotReplyService {
  String? lastQuestion;
  List<MenuProduct> lastProducts = [];

  @override
  Future<String> replyTo(String question, List<MenuProduct> products) async {
    lastQuestion = question;
    lastProducts = products;
    return 'Here is the current menu information.';
  }
}
