import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/order_draft.dart';
import '../state/cart_store.dart';
import '../widgets/cloudinary_image.dart';
import '../widgets/curved_content_page.dart';
import 'categories_screen.dart';
import 'order_type_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.onNavigateTab});

  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    return CurvedContentPage(
      title: 'My Cart',
      body: ValueListenableBuilder<List<OrderDraft>>(
        valueListenable: CartStore.items,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 44,
                      color: AppColors.orange,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose a drink from the menu to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () {
                        if (onNavigateTab != null) {
                          onNavigateTab!(1);
                        } else if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CategoriesScreen(),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Browse menu'),
                    ),
                  ],
                ),
              ),
            );
          }

          final subtotal = items.fold<int>(0, (sum, item) => sum + item.total);
          final count = items.fold<int>(0, (sum, item) => sum + item.quantity);
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _CartItemTile(
                    draft: items[index],
                    onQuantityChanged: (quantity) =>
                        CartStore.updateQuantity(index, quantity),
                    onRemove: () => CartStore.removeAt(index),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(color: Colors.white),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal ($count ${count == 1 ? 'item' : 'items'})',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'P$subtotal',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'P$subtotal',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => OrderTypeScreen(
                                drafts: items,
                                onNavigateTab: onNavigateTab,
                              ),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Proceed',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.draft,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final OrderDraft draft;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final details = [
      '${draft.size} · ${draft.sugar} sugar',
      ...draft.addIns,
      ...draft.addOns,
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CloudinaryImage(
              url: draft.product.imageUrl,
              fallbackAsset: draft.product.imageAsset,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                for (final detail in details)
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'P${draft.total}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                _QuantityStepper(
                  quantity: draft.quantity,
                  onChanged: onQuantityChanged,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove item',
            onPressed: onRemove,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          icon: const Icon(Icons.remove_rounded, size: 16),
          visualDensity: VisualDensity.compact,
          tooltip: 'Decrease quantity',
        ),
        Text(
          '$quantity',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: () => onChanged(quantity + 1),
          icon: const Icon(Icons.add_rounded, size: 16),
          visualDensity: VisualDensity.compact,
          tooltip: 'Increase quantity',
        ),
      ],
    );
  }
}
