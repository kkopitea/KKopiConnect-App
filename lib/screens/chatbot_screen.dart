import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/menu_catalog.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Hi! I can help you explore our menu, check prices, find best sellers, and place an order.',
      fromUser: false,
    ),
  ];

  static const _quickPrompts = [
    'Show best sellers',
    'What fruit tea do you have?',
    'How do I place an order?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KKOPI.TEA Assistant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'MENU AND ORDER HELP',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
              itemCount: _messages.length == 1 ? 1 : _messages.length,
              itemBuilder: (context, index) {
                if (index == 0 && _messages.length == 1) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MessageBubble(message: _messages.first),
                      const SizedBox(height: 16),
                      const Text(
                        'TRY ASKING',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final prompt in _quickPrompts)
                            ActionChip(
                              label: Text(prompt),
                              onPressed: () => _send(prompt),
                              side: const BorderSide(color: Color(0xFFE5E5E5)),
                              backgroundColor: Colors.white,
                            ),
                        ],
                      ),
                    ],
                  );
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: 'Ask about the menu or your order',
                        filled: true,
                        fillColor: AppColors.inputFill,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: () => _send(_messageController.text),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    setState(() {
      _messages
        ..add(_ChatMessage(text: text, fromUser: true))
        ..add(_ChatMessage(text: _replyTo(text), fromUser: false));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _replyTo(String question) {
    final normalized = question.toLowerCase();
    final matchingProduct = menuProducts.where((product) {
      final normalizedName = product.name.toLowerCase();
      return normalized.contains(normalizedName) ||
          normalizedName.contains(normalized);
    });
    if (matchingProduct.isNotEmpty) {
      final product = matchingProduct.first;
      return '${product.name} is P${product.price}. ${product.description}';
    }

    if (_hasAny(normalized, ['best seller', 'popular', 'favorite'])) {
      final bestSellers = menuProducts
          .where((product) => product.isBestSeller)
          .map((product) => '${product.name} (P${product.price})')
          .join(', ');
      return 'Our best sellers are $bestSellers.';
    }

    final matchingCategory = menuCategories.where(
      (category) => normalized.contains(category.name.toLowerCase()),
    );
    if (matchingCategory.isNotEmpty) {
      final category = matchingCategory.first;
      final products = menuProducts
          .where((product) => product.categoryIds.contains(category.id))
          .map((product) => '${product.name} (P${product.price})')
          .join(', ');
      return products.isEmpty
          ? 'There are no ${category.name} products listed right now.'
          : '${category.name} options: $products.';
    }

    if (_hasAny(normalized, ['new', 'latest'])) {
      final newProducts = menuProducts
          .where((product) => product.isNew)
          .map((product) => '${product.name} (P${product.price})')
          .join(', ');
      return 'New on the menu: $newProducts.';
    }

    if (_hasAny(normalized, ['order', 'buy', 'checkout', 'place'])) {
      return 'Choose a product from the menu, customize it, add it to your cart, then tap Proceed to choose pickup and payment details.';
    }

    if (_hasAny(normalized, ['hello', 'hi', 'hey'])) {
      return 'Hello! Ask me about a product, its price, a menu category, or how to order.';
    }

    return 'I can help with menu items, prices, categories, best sellers, and ordering. Try asking “What fruit tea do you have?”';
  }

  bool _hasAny(String value, List<String> terms) =>
      terms.any((term) => value.contains(term));
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final fromUser = message.fromUser;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: fromUser ? AppColors.orange : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: fromUser ? null : Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: fromUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
