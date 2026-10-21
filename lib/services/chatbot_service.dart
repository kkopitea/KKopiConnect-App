import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/menu_catalog.dart';
import '../state/product_ratings_store.dart';
import 'chatbot_history_store.dart';

abstract interface class ChatbotReplyService {
  Future<String> replyTo(String question, List<MenuProduct> products);
}

class GroqChatbotService implements ChatbotReplyService {
  GroqChatbotService({
    http.Client? client,
    FirebaseAuth? auth,
    String? workerUrl,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _auth = auth ?? FirebaseAuth.instance,
       _workerUrl =
           workerUrl ??
           const String.fromEnvironment(
             'GROQ_WORKER_URL',
             defaultValue:
                 'https://kkopiconnect-groq-chat.kkopiconnect-chat.workers.dev',
           );

  static const _maxHistoryMessages = 10;
  final http.Client _client;
  final bool _ownsClient;
  final FirebaseAuth _auth;
  final String _workerUrl;
  final List<Map<String, String>> _conversation = [];

  void close() {
    if (_ownsClient) _client.close();
  }

  void restoreHistory(List<ChatbotHistoryMessage> messages) {
    _conversation
      ..clear()
      ..addAll(
        messages
            .where((message) => message.text.isNotEmpty)
            .map(
              (message) => {
                'role': message.fromUser ? 'user' : 'assistant',
                'content': message.text,
              },
            )
            .toList()
            .reversed
            .take(_maxHistoryMessages)
            .toList()
            .reversed,
      );
  }

  @override
  Future<String> replyTo(String question, List<MenuProduct> products) async {
    final bestSellers = Firebase.apps.isEmpty
        ? products.where((product) => product.isBestSeller).take(3).toList()
        : ProductRatingsStore.bestRatedProducts(products, limit: 3);
    final knownAnswer = MenuAssistantKnowledge.answer(
      question,
      products,
      bestSellingProducts: bestSellers,
    );
    if (knownAnswer != null) return knownAnswer;
    if (products.isEmpty) {
      return 'The menu is still loading. Please try again in a moment.';
    }
    if (_workerUrl.isEmpty) {
      throw StateError(
        'Set GROQ_WORKER_URL when building the app to enable the assistant.',
      );
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to use the assistant.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Could not verify your sign-in. Please sign in again.');
    }

    final bestSellerIds = bestSellers.map((product) => product.id).toSet();
    final catalog = products
        .map(
          (product) => {
            'id': product.id,
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'categories': product.categoryIds.map((categoryId) {
              final matchingCategories = menuCategories.where(
                (category) => category.id == categoryId,
              );
              return matchingCategories.isEmpty
                  ? categoryId
                  : matchingCategories.first.name;
            }).toList(),
            'bestSeller': bestSellerIds.contains(product.id),
            'ratingCount': Firebase.apps.isEmpty
                ? 0
                : ProductRatingsStore.summary(product.id).count,
            'ratingAverage': Firebase.apps.isEmpty
                ? 0
                : ProductRatingsStore.summary(product.id).average,
            'new': product.isNew,
            'classic': product.isClassic,
            'sizes': product.availableSizes
                .map((size) => {'name': size.$1, 'additionalPrice': size.$2})
                .toList(),
            'sugarLevels': product.sugarLevels,
          },
        )
        .toList();
    final response = await _client
        .post(
          Uri.parse(_workerUrl),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'question': question,
            'products': catalog,
            'history': _conversation
                .skip(
                  _conversation.length > _maxHistoryMessages
                      ? _conversation.length - _maxHistoryMessages
                      : 0,
                )
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 40));
    final responseData = jsonDecode(response.body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        responseData is! Map<String, dynamic>) {
      final message = responseData is Map<String, dynamic>
          ? responseData['error']
          : null;
      throw StateError(
        message is String
            ? message
            : 'The assistant is temporarily unavailable. Please try again.',
      );
    }
    final text = responseData['reply'];
    if (text is! String || text.trim().isEmpty) {
      return 'I could not find a clear answer. Are you asking about a menu item, its price, or how to order?';
    }
    _conversation
      ..add({'role': 'user', 'content': question})
      ..add({'role': 'assistant', 'content': text.trim()});
    if (_conversation.length > _maxHistoryMessages) {
      _conversation.removeRange(0, _conversation.length - _maxHistoryMessages);
    }
    return text.trim();
  }
}

class MenuAssistantKnowledge {
  MenuAssistantKnowledge._();

  static String? answer(
    String question,
    List<MenuProduct> products, {
    List<MenuProduct>? bestSellingProducts,
  }) {
    final text = _normalize(question);
    if (text.isEmpty) return 'What would you like to know about our menu?';

    if (RegExp(
      r'^(hi|hello|hey|good morning|good afternoon|good evening)\b',
    ).hasMatch(text)) {
      return 'Hi! I can help you find drinks, compare prices, and explain how to order. What are you looking for?';
    }
    if (_containsAny(text, ['thank you', 'thanks', 'that helps'])) {
      return 'You’re welcome! Let me know if you want help with another menu item or your order.';
    }

    if (_containsAny(text, [
      'how to order',
      'how do i order',
      'place an order',
      'how can i order',
      'how to buy',
      'checkout',
    ])) {
      return 'To order, add a product to your cart, tap Proceed, choose Pick up or Dine In and a payment method, then tap Place Order.';
    }

    if (products.isEmpty) {
      if (_containsAny(text, [
        'menu',
        'drink',
        'product',
        'price',
        'best seller',
      ])) {
        return 'The menu is still loading. Please try again in a moment.';
      }
      return null;
    }

    if (_containsAny(text, ['best seller', 'best sellers', 'popular drink'])) {
      final items =
          bestSellingProducts ??
          products.where((product) => product.isBestSeller).toList();
      if (items.isEmpty) {
        return 'There are no products currently marked as best sellers.';
      }
      return 'Our best sellers are: ${_formatProducts(items)}.';
    }

    if (_containsAny(text, [
      'new drink',
      'new drinks',
      'what is new',
      'new products',
    ])) {
      final items = products.where((product) => product.isNew).toList();
      return items.isEmpty
          ? 'There are no products currently marked as new.'
          : 'New on the menu: ${_formatProducts(items)}.';
    }

    final category = menuCategories.where(
      (item) =>
          text.contains(_normalize(item.name)) ||
          text.contains(_normalize(item.id.replaceAll('_', ' '))),
    );
    if (category.isNotEmpty &&
        (_containsAny(text, [
              'what',
              'which',
              'show',
              'have',
              'menu',
              'list',
              'drink',
              'product',
            ]) ||
            text == _normalize(category.first.name) ||
            text == _normalize(category.first.id.replaceAll('_', ' ')))) {
      final selected = category.first;
      final items = products
          .where((product) => product.categoryIds.contains(selected.id))
          .toList();
      return items.isEmpty
          ? 'There are no ${selected.name} products currently available.'
          : '${selected.name} on the menu: ${_formatProducts(items)}.';
    }

    final normalizedProduct =
        products
            .where((product) => text.contains(_normalize(product.name)))
            .toList()
          ..sort(
            (first, second) => _normalize(
              second.name,
            ).length.compareTo(_normalize(first.name).length),
          );
    if (normalizedProduct.isNotEmpty) {
      final product = normalizedProduct.first;
      if (_containsAny(text, ['price', 'how much', 'cost'])) {
        return '${product.name} is ₱${product.price}.';
      }
      final details = <String>[
        product.description,
        'Price: ₱${product.price}',
        'Sizes: ${product.availableSizes.map((size) => '${size.$1} (+₱${size.$2})').join(', ')}',
        if (product.sugarLevels.isNotEmpty)
          'Sugar levels: ${product.sugarLevels.join(', ')}',
      ];
      return details.join('\n');
    }

    if (_containsAny(text, ['price', 'how much', 'cost'])) {
      final queryWords = text
          .split(' ')
          .where((word) => word.length > 2)
          .toSet();
      final matches = products
          .where(
            (product) => _normalize(product.name)
                .split(' ')
                .where((word) => word.length > 2)
                .any(queryWords.contains),
          )
          .toList();
      if (matches.length == 1) {
        final product = matches.first;
        return '${product.name} is ₱${product.price}.';
      }
      if (matches.length > 1) {
        return 'Which drink do you mean? ${_formatProducts(matches)}.';
      }
    }

    if (_containsAny(text, [
      'menu',
      'what drinks',
      'what do you have',
      'show products',
    ])) {
      return 'Here is the menu: ${_formatProducts(products)}. Ask me about a drink for its details or price.';
    }
    return null;
  }

  static String _formatProducts(List<MenuProduct> products) => products
      .map((product) => '${product.name} (₱${product.price})')
      .join(', ');

  static bool _containsAny(String text, List<String> phrases) =>
      phrases.any((phrase) => text.contains(phrase));

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9% ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
