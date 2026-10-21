import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import '../app_colors.dart';
import '../data/menu_catalog.dart';
import '../data/order_draft.dart';
import '../data/product_rating_repository.dart';
import '../state/favorites_store.dart';
import '../state/product_ratings_store.dart';
import '../state/cart_store.dart';
import '../widgets/cloudinary_image.dart';
import '../widgets/product_rating_control.dart';
import 'customize_drink_screen.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.onNavigateTab,
  });

  final MenuProduct product;
  final ValueChanged<int>? onNavigateTab;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  String _selectedSize = '16oz';
  int _selectedPrice = 0;
  Stream<ProductRatingSummary>? _ratingSummaryStream;
  Stream<int?>? _userRatingStream;
  bool _isSubmittingRating = false;

  List<(String, int)> get _sizes => widget.product.availableSizes
      .map((size) => (size.$1, widget.product.price + size.$2))
      .toList();

  @override
  void initState() {
    super.initState();
    _selectedSize = _sizes.first.$1;
    _selectedPrice = _sizes.first.$2;
    if (Firebase.apps.isNotEmpty) {
      _watchProductRatings();
      ProductRatingsStore.summaries.addListener(_ratingsChanged);
    }
  }

  @override
  void didUpdateWidget(covariant ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id && Firebase.apps.isNotEmpty) {
      _watchProductRatings();
    }
  }

  @override
  void dispose() {
    if (Firebase.apps.isNotEmpty) {
      ProductRatingsStore.summaries.removeListener(_ratingsChanged);
    }
    super.dispose();
  }

  void _watchProductRatings() {
    _ratingSummaryStream = ProductRatingsStore.watchSummary(widget.product.id);
    _userRatingStream = ProductRatingsStore.watchUserRating(widget.product.id);
  }

  void _ratingsChanged() {
    if (mounted) setState(() {});
  }

  Widget _productRating() {
    if (Firebase.apps.isEmpty) {
      return ProductRatingControl(
        summary: const ProductRatingSummary.empty(),
        userRating: null,
        onRate: _rateProduct,
      );
    }
    return StreamBuilder<ProductRatingSummary>(
      stream: _ratingSummaryStream,
      builder: (context, summarySnapshot) {
        if (summarySnapshot.hasError) {
          return const Text(
            'Ratings unavailable',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          );
        }
        if (summarySnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          );
        }
        return StreamBuilder<int?>(
          stream: _userRatingStream,
          builder: (context, userRatingSnapshot) {
            if (userRatingSnapshot.hasError) {
              return const Text(
                'Your rating is unavailable',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              );
            }
            return ProductRatingControl(
              summary:
                  summarySnapshot.data ?? const ProductRatingSummary.empty(),
              userRating: userRatingSnapshot.data,
              isSubmitting: _isSubmittingRating,
              onRate: _rateProduct,
            );
          },
        );
      },
    );
  }

  Future<void> _rateProduct(int rating) async {
    if (_isSubmittingRating) return;
    setState(() => _isSubmittingRating = true);
    try {
      if (Firebase.apps.isEmpty) {
        throw StateError('Sign in to rate this product.');
      }
      await ProductRatingsStore.setRating(widget.product.id, rating);
    } catch (error) {
      debugPrint('Unable to rate product: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message.toString()
                  : 'Could not save your rating. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingRating = false);
    }
  }

  Future<void> _toggleFavorite(String productId) async {
    try {
      await FavoritesStore.toggle(productId);
    } catch (error) {
      debugPrint('Unable to update product favorite: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Could not update this favorite. Please try again.',
          ),
        ),
      );
    }
  }

  OrderDraft get _draft => OrderDraft(
    product: widget.product,
    quantity: _quantity,
    size: _selectedSize,
    sizePrice: _selectedPrice,
  );

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isBestSeller = Firebase.apps.isEmpty
        ? product.isBestSeller
        : ProductRatingsStore.isBestSeller(product.id, menuProducts);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFA338), AppColors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: CloudinaryImage(
                        url: product.imageUrl,
                        fallbackAsset: product.imageAsset,
                        width: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 8,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 8,
                    child: Row(
                      children: [
                        ValueListenableBuilder<Set<String>>(
                          valueListenable: FavoritesStore.productIds,
                          builder: (context, favorites, _) {
                            final isFavorite = favorites.contains(product.id);
                            return IconButton(
                              tooltip: isFavorite
                                  ? 'Remove favorite'
                                  : 'Add favorite',
                              onPressed: () => _toggleFavorite(product.id),
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Share product',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: product.name),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Product name copied'),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.share_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    top: -16,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    if (isBestSeller)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.orange,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Best seller',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  product.description,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _productRating(),
                              ],
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFFE9E9E9)),
                              ),
                            ),
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${AppColors.pesoSymbol}$_selectedPrice',
                                      style: const TextStyle(
                                        color: AppColors.orange,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          'Quantity',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _QuantityControl(
                                          quantity: _quantity,
                                          onDecrease: () => setState(
                                            () => _quantity = _quantity > 1
                                                ? _quantity - 1
                                                : 1,
                                          ),
                                          onIncrease: () =>
                                              setState(() => _quantity++),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Sizes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    for (final option in _sizes)
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 7,
                                          ),
                                          child: InkWell(
                                            onTap: () => setState(() {
                                              _selectedSize = option.$1;
                                              _selectedPrice = option.$2;
                                            }),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 7,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    _selectedSize == option.$1
                                                    ? AppColors.orangeTint
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color:
                                                      _selectedSize == option.$1
                                                      ? AppColors.orange
                                                      : const Color(0xFFE1E1E1),
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    option.$1,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${AppColors.pesoSymbol}${option.$2}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => CustomizeDrinkScreen(
                                          draft: _draft,
                                          onNavigateTab: widget.onNavigateTab,
                                        ),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.orange,
                                      side: const BorderSide(
                                        color: AppColors.orange,
                                      ),
                                    ),
                                    child: const Text('Customize'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: FilledButton(
                                    onPressed: () {
                                      CartStore.add(_draft);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${product.name} added to cart',
                                          ),
                                          action: SnackBarAction(
                                            label: 'View cart',
                                            onPressed: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        const CartScreen(),
                                                  ),
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Add to cart'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E2E2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove, size: 16),
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add, size: 16),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
