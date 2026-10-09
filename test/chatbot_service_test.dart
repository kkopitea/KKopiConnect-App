import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/data/menu_catalog.dart';
import 'package:kkopiconnect_app/services/chatbot_service.dart';

void main() {
  group('MenuAssistantKnowledge', () {
    test('answers order-flow questions with the actual app steps', () {
      final answer = MenuAssistantKnowledge.answer(
        'How do I place an order?',
        menuProducts,
      );

      expect(answer, contains('add a product to your cart'));
      expect(answer, contains('tap Proceed'));
      expect(answer, contains('Place Order'));
    });

    test('lists catalog-marked best sellers with prices', () {
      final answer = MenuAssistantKnowledge.answer(
        'Show best sellers',
        menuProducts,
      );

      expect(answer, contains('Iced Americano Caramel'));
      expect(answer, contains('(P50)'));
    });

    test('lists products in the requested category', () {
      final answer = MenuAssistantKnowledge.answer(
        'What fruit tea do you have?',
        menuProducts,
      );

      expect(answer, contains('Mango Fruit Tea'));
      expect(answer, contains('(P65)'));
    });

    test('answers a specific product price from the catalog', () {
      final answer = MenuAssistantKnowledge.answer(
        'How much is Iced Americano Caramel?',
        menuProducts,
      );

      expect(answer, 'Iced Americano Caramel is P50.');
    });

    test('asks which product when a price question is ambiguous', () {
      final answer = MenuAssistantKnowledge.answer(
        'How much is Americano?',
        menuProducts,
      );

      expect(answer, contains('Which drink do you mean?'));
      expect(answer, contains('Iced Americano Caramel'));
      expect(answer, contains('Vanilla Americano Latte Tea'));
    });

    test('politely redirects unrelated topics', () {
      expect(
        MenuAssistantKnowledge.answer('Who won the game?', menuProducts),
        isNull,
      );
    });
  });
}
