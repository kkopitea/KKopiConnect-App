import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_colors.dart';
import '../data/menu_catalog.dart';
import '../state/product_ratings_store.dart';
import '../services/chatbot_service.dart';
import '../services/chatbot_history_store.dart';
import '../widgets/cloudinary_image.dart';
import 'product_detail_screen.dart';
import 'register_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key, this.chatbotService, this.onNavigateTab});

  final ChatbotReplyService? chatbotService;
  final ValueChanged<int>? onNavigateTab;

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _historyStore = ChatbotHistoryStore();
  late final ChatbotReplyService _chatbotService;
  late final Future<void> _historyLoadFuture;
  bool _isSending = false;
  bool _isLoadingHistory = true;
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Hi! I can help you explore our menu, check prices, find best sellers, and place an order.',
      fromUser: false,
    ),
  ];

  static const _quickPrompts = [
    'Recommend a drink for me',
    'Show best sellers',
    'What fruit tea do you have?',
    'How do I place an order?',
  ];

  @override
  void initState() {
    super.initState();
    _chatbotService = widget.chatbotService ?? GroqChatbotService();
    _historyLoadFuture = _loadHistory();
  }

  @override
  void dispose() {
    if (widget.chatbotService == null) {
      (_chatbotService as GroqChatbotService).close();
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _historyStore.load();
      if (!mounted) return;
      if (history.isNotEmpty) {
        setState(() {
          _messages
            ..clear()
            ..addAll(
              history.map(
                (message) => _ChatMessage(
                  text: message.text,
                  fromUser: message.fromUser,
                  products: menuProducts
                      .where(
                        (product) => message.productIds.contains(product.id),
                      )
                      .toList(),
                ),
              ),
            );
        });
        if (_chatbotService is GroqChatbotService) {
          _chatbotService.restoreHistory(history);
        }
        _scrollToLatestMessage();
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Could not load chatbot history: $error\n$stackTrace');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat history could not be loaded.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _saveHistory() async {
    try {
      await _historyStore.save(
        _messages
            .map(
              (message) => ChatbotHistoryMessage(
                text: message.text,
                fromUser: message.fromUser,
                productIds: message.products
                    .map((product) => product.id)
                    .toList(),
              ),
            )
            .toList(),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Could not save chatbot history: $error\n$stackTrace');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat history could not be saved.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chatbotService == null &&
        FirebaseAuth.instance.currentUser?.isAnonymous != false) {
      return _AccountRequiredChatScreen();
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.white,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF87818),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.orangeGradient),
          ),
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
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.orangeGradient),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(
                        message: _messages[index],
                        onProductTap: _openProduct,
                      );
                    },
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
                ),
                padding: const EdgeInsets.fromLTRB(12, 4, 8, 10),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _quickPrompts.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 18),
                          itemBuilder: (context, index) {
                            final prompt = _quickPrompts[index];
                            return Center(
                              child: Semantics(
                                button: true,
                                label: prompt,
                                child: InkWell(
                                  onTap: _isSending
                                      ? null
                                      : () => _send(prompt),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      prompt,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: _isSending ? null : _send,
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
                            onPressed: _isSending
                                ? null
                                : () => _send(_messageController.text),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.orange,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isSending) return;
    _messageController.clear();
    setState(() => _isSending = true);
    if (_isLoadingHistory) await _historyLoadFuture;
    if (!mounted) return;
    setState(() => _messages.add(_ChatMessage(text: text, fromUser: true)));
    await _saveHistory();
    _scrollToLatestMessage();

    late final String reply;
    var requestFailed = false;
    try {
      reply = await _chatbotService
          .replyTo(text, menuProducts)
          .timeout(const Duration(seconds: 45));
    } on TimeoutException catch (error, stackTrace) {
      requestFailed = true;
      if (kDebugMode) {
        debugPrint('Chatbot request timed out: $error\n$stackTrace');
      }
      reply = kDebugMode
          ? 'The assistant request timed out after 45 seconds. Check your '
                'connection and Cloudflare Worker setup.'
          : 'The assistant took too long to respond. Please try again.';
    } catch (error, stackTrace) {
      requestFailed = true;
      if (kDebugMode) {
        debugPrint('Chatbot request failed: $error\n$stackTrace');
      }
      reply = error is StateError
          ? error.message.toString()
          : kDebugMode
          ? 'Chatbot error (${error.runtimeType}): $error'
          : 'I could not reach the assistant just now. Please check your connection and try again in a moment.';
    }
    if (!mounted) return;
    final relatedProducts = _productsForReply(
      text,
      reply,
      includeRecommendations: !requestFailed,
    );
    setState(() {
      _isSending = false;
      _messages.add(
        _ChatMessage(text: reply, fromUser: false, products: relatedProducts),
      );
    });
    await _saveHistory();
    _scrollToLatestMessage();
  }

  List<MenuProduct> _productsForReply(
    String question,
    String reply, {
    required bool includeRecommendations,
  }) {
    final normalizedQuestion = question.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9 ]'),
      ' ',
    );
    final isBestSellerQuestion = RegExp(
      r'\b(best sellers?|best selling|popular drinks?)\b',
    ).hasMatch(normalizedQuestion);
    final isRecommendation = RegExp(
      r'\b(recommend|recommendation|suggest)\b',
    ).hasMatch(normalizedQuestion);
    if (isBestSellerQuestion) {
      return _bestSellingProducts();
    }

    final requestedCategory = menuCategories
        .where(
          (category) =>
              normalizedQuestion.contains(category.name.toLowerCase()) ||
              normalizedQuestion.contains(
                category.id.replaceAll('_', ' ').toLowerCase(),
              ),
        )
        .firstOrNull;
    if (requestedCategory != null) {
      final hasProductIntent = RegExp(
        r'\b(what|which|show|have|menu|list|drink|product|recommend)\b',
      ).hasMatch(normalizedQuestion);
      if (hasProductIntent) {
        return menuProducts
            .where(
              (product) => product.categoryIds.contains(requestedCategory.id),
            )
            .take(isRecommendation ? 2 : 6)
            .toList();
      }
    }

    final normalizedReply = reply.toLowerCase();
    final mentionedProducts =
        menuProducts
            .where(
              (product) => normalizedReply.contains(product.name.toLowerCase()),
            )
            .toList()
          ..sort(
            (first, second) => normalizedReply
                .indexOf(first.name.toLowerCase())
                .compareTo(normalizedReply.indexOf(second.name.toLowerCase())),
          );
    if (mentionedProducts.isNotEmpty) {
      return mentionedProducts.take(isRecommendation ? 2 : 6).toList();
    }

    if (includeRecommendations && isRecommendation) {
      return _bestSellingProducts(limit: 2);
    }
    return const [];
  }

  List<MenuProduct> _bestSellingProducts({int limit = 3}) {
    final products = Firebase.apps.isEmpty
        ? menuProducts.where((product) => product.isBestSeller).toList()
        : ProductRatingsStore.bestRatedProducts(menuProducts);
    return products.take(limit).toList();
  }

  void _openProduct(MenuProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          product: product,
          onNavigateTab: widget.onNavigateTab,
        ),
      ),
    );
  }

  void _scrollToLatestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }
}

class _AccountRequiredChatScreen extends StatelessWidget {
  const _AccountRequiredChatScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KKOPI.TEA Assistant',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.orangeGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 56,
                  color: AppColors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'For KKOPI.TEA account users',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Register or sign in to chat with the KKOPI.TEA assistant. Guest ordering is still available without an account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Register now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.fromUser,
    this.products = const [],
  });

  final String text;
  final bool fromUser;
  final List<MenuProduct> products;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onProductTap});

  final _ChatMessage message;
  final ValueChanged<MenuProduct> onProductTap;

  @override
  Widget build(BuildContext context) {
    final fromUser = message.fromUser;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: fromUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.82,
            ),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: fromUser ? AppColors.orange : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: fromUser
                  ? null
                  : Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: _FormattedChatText(
              text: message.text,
              style: TextStyle(
                color: fromUser ? Colors.white : Colors.black87,
                fontSize: 16,
                height: 1.35,
              ),
            ),
          ),
          if (message.products.isNotEmpty)
            ...message.products.map(
              (product) => _ChatProductCard(
                product: product,
                onTap: () => onProductTap(product),
              ),
            ),
        ],
      ),
    );
  }
}

class _FormattedChatText extends StatelessWidget {
  const _FormattedChatText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final lines = text.trim().split('\n');
    final children = <TextSpan>[];
    for (var index = 0; index < lines.length; index++) {
      var line = lines[index].trimRight();
      final heading = RegExp(r'^#{1,6}\s+').firstMatch(line);
      final isHeading = heading != null;
      if (heading != null) line = line.substring(heading.end);
      final listMarker = RegExp(
        r'^\s*(?:[-*+]\s+|\d+[.)]\s+)',
      ).firstMatch(line);
      if (listMarker != null) {
        final marker = listMarker.group(0)!.trimLeft();
        final replacement = RegExp(r'^\d+[.)]').hasMatch(marker)
            ? '$marker '
            : '•  ';
        children.add(
          TextSpan(
            text: replacement,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
        line = line.substring(listMarker.end);
      }
      children.addAll(_inlineSpans(line, style, bold: isHeading));
      if (index < lines.length - 1) children.add(const TextSpan(text: '\n'));
    }
    return RichText(
      text: TextSpan(style: style, children: children),
    );
  }

  List<TextSpan> _inlineSpans(
    String text,
    TextStyle baseStyle, {
    bool bold = false,
  }) {
    final spans = <TextSpan>[];
    final pattern = RegExp(
      r'(\*\*.+?\*\*|__.+?__|\*[^*\n]+\*|(?<![a-zA-Z0-9])_[^_\n]+_(?![a-zA-Z0-9]))',
    );
    final plainStyle = bold
        ? baseStyle.copyWith(fontWeight: FontWeight.w800)
        : null;
    var previousEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > previousEnd) {
        spans.add(
          TextSpan(
            text: text.substring(previousEnd, match.start),
            style: plainStyle,
          ),
        );
      }
      final token = match.group(0)!;
      final isBold = token.startsWith('**') || token.startsWith('__');
      final content = token.substring(
        isBold ? 2 : 1,
        token.length - (isBold ? 2 : 1),
      );
      spans.add(
        TextSpan(
          text: content,
          style: baseStyle.copyWith(
            fontWeight: bold || isBold ? FontWeight.w800 : baseStyle.fontWeight,
            fontStyle: isBold ? baseStyle.fontStyle : FontStyle.italic,
          ),
        ),
      );
      previousEnd = match.end;
    }
    if (previousEnd < text.length) {
      final tail = text.substring(previousEnd);
      spans.add(TextSpan(text: tail, style: plainStyle));
    }
    if (spans.isEmpty && text.isNotEmpty) {
      spans.add(TextSpan(text: text, style: plainStyle));
    }
    return spans;
  }
}

class _ChatProductCard extends StatelessWidget {
  const _ChatProductCard({required this.product, required this.onTap});

  final MenuProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.82,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CloudinaryImage(
                    url: product.imageUrl,
                    fallbackAsset: product.imageAsset,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    semanticLabel: product.name,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From ₱${product.price}',
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'View and order ${product.name}',
                  onPressed: onTap,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: AppColors.orange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
