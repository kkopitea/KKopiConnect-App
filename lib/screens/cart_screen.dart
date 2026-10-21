import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/order_draft.dart';
import '../state/cart_store.dart';
import '../widgets/cloudinary_image.dart';
import '../widgets/curved_content_page.dart';
import 'categories_screen.dart';
import 'order_type_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.onNavigateTab, this.checkoutBuilder});

  final ValueChanged<int>? onNavigateTab;
  final Widget Function(List<OrderDraft> drafts)? checkoutBuilder;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<OrderDraft> _knownItems;
  final Set<int> _selectedIndexes = {};

  @override
  void initState() {
    super.initState();
    _knownItems = CartStore.items.value;
    _selectedIndexes.addAll(
      List<int>.generate(_knownItems.length, (index) => index),
    );
    CartStore.items.addListener(_cartChanged);
  }

  @override
  void dispose() {
    CartStore.items.removeListener(_cartChanged);
    super.dispose();
  }

  void _cartChanged() {
    final currentItems = CartStore.items.value;
    final previousItems = _knownItems;
    final matchedPreviousIndexes = <int>{};
    final updatedSelection = <int>{};

    for (
      var currentIndex = 0;
      currentIndex < currentItems.length;
      currentIndex++
    ) {
      final item = currentItems[currentIndex];
      var previousIndex = -1;
      for (var index = 0; index < previousItems.length; index++) {
        if (!matchedPreviousIndexes.contains(index) &&
            identical(previousItems[index], item)) {
          previousIndex = index;
          break;
        }
      }
      if (previousIndex >= 0) {
        matchedPreviousIndexes.add(previousIndex);
        if (_selectedIndexes.contains(previousIndex)) {
          updatedSelection.add(currentIndex);
        }
      } else if (currentItems.length == previousItems.length &&
          currentIndex < previousItems.length &&
          currentItems[currentIndex].product.id ==
              previousItems[currentIndex].product.id &&
          _selectedIndexes.contains(currentIndex)) {
        updatedSelection.add(currentIndex);
      } else if (currentIndex >= previousItems.length) {
        updatedSelection.add(currentIndex);
      }
    }

    _knownItems = currentItems;
    if (mounted) {
      setState(() {
        _selectedIndexes
          ..clear()
          ..addAll(updatedSelection);
      });
    }
  }

  void _removeAt(int index) {
    CartStore.removeAt(index);
  }

  void _toggleSelection(int index, bool selected) {
    setState(() {
      if (selected) {
        _selectedIndexes.add(index);
      } else {
        _selectedIndexes.remove(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CurvedContentPage(
      title: 'MY CART',
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
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(1);
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

          final selectedItems = [
            for (var index = 0; index < items.length; index++)
              if (_selectedIndexes.contains(index)) items[index],
          ];
          final subtotal = selectedItems.fold<int>(
            0,
            (sum, item) => sum + item.total,
          );
          final count = selectedItems.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          );
          return Column(
            children: [
              CheckboxListTile(
                value:
                    items.isNotEmpty && _selectedIndexes.length == items.length,
                tristate: true,
                title: const Text(
                  'Select all for order',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.orange,
                onChanged: (selected) {
                  setState(() {
                    _selectedIndexes
                      ..clear()
                      ..addAll(
                        selected == true
                            ? List<int>.generate(items.length, (index) => index)
                            : const <int>[],
                      );
                  });
                },
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _CartItemTile(
                    draft: items[index],
                    selected: _selectedIndexes.contains(index),
                    onSelectionChanged: (selected) =>
                        _toggleSelection(index, selected),
                    onQuantityChanged: (quantity) =>
                        CartStore.updateQuantity(index, quantity),
                    onRemove: () => _removeAt(index),
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
                            '${AppColors.pesoSymbol}$subtotal',
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
                            '${AppColors.pesoSymbol}$subtotal',
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
                          onPressed: selectedItems.isEmpty
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        widget.checkoutBuilder?.call(
                                          List.unmodifiable(selectedItems),
                                        ) ??
                                        OrderTypeScreen(
                                          drafts: List.unmodifiable(
                                            selectedItems,
                                          ),
                                          onNavigateTab: widget.onNavigateTab,
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
    required this.selected,
    required this.onSelectionChanged,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final OrderDraft draft;
  final bool selected;
  final ValueChanged<bool> onSelectionChanged;
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
          Checkbox(
            value: selected,
            activeColor: AppColors.orange,
            semanticLabel: 'Select ${draft.product.name} for order',
            onChanged: (value) => onSelectionChanged(value ?? false),
          ),
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
                  '${AppColors.pesoSymbol}${draft.total}',
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
