import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/services/chatbot_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads saved messages and their product IDs before expiry', () async {
    var now = DateTime(2026, 10, 21, 10);
    final store = ChatbotHistoryStore(clock: () => now);
    const messages = [
      ChatbotHistoryMessage(text: 'What should I try?', fromUser: true),
      ChatbotHistoryMessage(
        text: 'Try Mango Fruit Tea.',
        fromUser: false,
        productIds: ['mango-fruit-tea'],
      ),
    ];

    await store.save(messages);
    now = now.add(const Duration(hours: 23, minutes: 59));

    final restored = await store.load();
    expect(restored.map((message) => message.text), [
      'What should I try?',
      'Try Mango Fruit Tea.',
    ]);
    expect(restored.last.productIds, ['mango-fruit-tea']);
  });

  test('clears the conversation after 24 hours', () async {
    var now = DateTime(2026, 10, 21, 10);
    final store = ChatbotHistoryStore(clock: () => now);
    await store.save(const [
      ChatbotHistoryMessage(text: 'Hello', fromUser: true),
    ]);

    now = now.add(const Duration(hours: 24));

    expect(await store.load(), isEmpty);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('chatbotConversation'), isNull);
  });
}
