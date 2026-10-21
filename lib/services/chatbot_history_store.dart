import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ChatbotHistoryMessage {
  const ChatbotHistoryMessage({
    required this.text,
    required this.fromUser,
    this.productIds = const [],
  });

  final String text;
  final bool fromUser;
  final List<String> productIds;

  Map<String, Object> toJson() => {
    'text': text,
    'fromUser': fromUser,
    'productIds': productIds,
  };

  static ChatbotHistoryMessage? fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['text'] is! String ||
        value['fromUser'] is! bool) {
      return null;
    }
    final productIds = value['productIds'];
    return ChatbotHistoryMessage(
      text: value['text'] as String,
      fromUser: value['fromUser'] as bool,
      productIds: productIds is List
          ? productIds.whereType<String>().toList()
          : const [],
    );
  }
}

class ChatbotHistoryStore {
  ChatbotHistoryStore({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const retention = Duration(hours: 24);
  static const _preferenceKey = 'chatbotConversation';

  final DateTime Function() _clock;

  Future<List<ChatbotHistoryMessage>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_preferenceKey);
    if (encoded == null) return const [];

    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic> ||
        decoded['savedAt'] is! int ||
        decoded['messages'] is! List) {
      await preferences.remove(_preferenceKey);
      return const [];
    }

    final savedAt = DateTime.fromMillisecondsSinceEpoch(
      decoded['savedAt'] as int,
    );
    if (_clock().difference(savedAt) >= retention) {
      await preferences.remove(_preferenceKey);
      return const [];
    }

    return (decoded['messages'] as List)
        .map(ChatbotHistoryMessage.fromJson)
        .whereType<ChatbotHistoryMessage>()
        .toList();
  }

  Future<void> save(List<ChatbotHistoryMessage> messages) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _preferenceKey,
      jsonEncode({
        'savedAt': _clock().millisecondsSinceEpoch,
        'messages': messages.map((message) => message.toJson()).toList(),
      }),
    );
  }
}
