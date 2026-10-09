import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/drink_extra.dart';
import '../data/drink_extra_repository.dart';
import '../data/menu_catalog.dart';
import '../data/order_draft.dart';
import '../state/cart_store.dart';
import '../widgets/cloudinary_image.dart';
import '../widgets/curved_content_page.dart';
import '../widgets/main_bottom_navigation_bar.dart';
import 'cart_screen.dart';

class CustomizeDrinkScreen extends StatefulWidget {
  const CustomizeDrinkScreen({
    super.key,
    required this.draft,
    this.onNavigateTab,
  });

  final OrderDraft draft;
  final ValueChanged<int>? onNavigateTab;

  @override
  State<CustomizeDrinkScreen> createState() => _CustomizeDrinkScreenState();
}

class _CustomizeDrinkScreenState extends State<CustomizeDrinkScreen> {
  late int quantity;
  late String size;
  late int sizePrice;
  String sugar = '50%';
  final Set<String> addIns = {};
  final Set<String> addOns = {};
  final Map<String, int> _addInUnitPrices = {};
  final Map<String, int> _addOnUnitPrices = {};
  late final Stream<List<DrinkExtra>> _addInsStream;
  late final Stream<List<DrinkExtra>> _addOnsStream;
  static const _sugarOptions = [
    ('0%', 'No sugar'),
    ('25%', 'Less'),
    ('50%', 'Normal'),
    ('75%', 'Slightly sweet'),
    ('100%', 'Sweet'),
  ];
  @override
  void initState() {
    super.initState();
    try {
      final repository = DrinkExtraRepository();
      _addInsStream = repository.watchAddIns();
      _addOnsStream = repository.watchAddOns();
    } catch (error, stackTrace) {
      debugPrint('Unable to connect to drink options: $error');
      _addInsStream = Stream<List<DrinkExtra>>.error(error, stackTrace);
      _addOnsStream = Stream<List<DrinkExtra>>.error(error, stackTrace);
    }
    quantity = widget.draft.quantity;
    size = widget.draft.size;
    sizePrice = widget.draft.unitPrice;
    sugar = widget.draft.sugar;
    addIns
      ..clear()
      ..addAll(widget.draft.addIns);
    addOns
      ..clear()
      ..addAll(widget.draft.addOns);
    _addInUnitPrices.addAll(widget.draft.addInUnitPrices);
    _addOnUnitPrices.addAll(widget.draft.addOnUnitPrices);
  }

  OrderDraft _draftForOptions(
    List<DrinkExtra> addInOptions,
    List<DrinkExtra> addOnOptions,
  ) {
    final addInPrices = Map<String, int>.of(_addInUnitPrices);
    final addOnPrices = Map<String, int>.of(_addOnUnitPrices);
    for (final option in addInOptions) {
      if (addIns.contains(option.name)) addInPrices[option.name] = option.price;
    }
    for (final option in addOnOptions) {
      if (addOns.contains(option.name)) addOnPrices[option.name] = option.price;
    }
    return OrderDraft(
      product: widget.draft.product,
      quantity: quantity,
      size: size,
      sizePrice: sizePrice,
      sugar: sugar,
      addIns: Set.unmodifiable(addIns),
      addOns: Set.unmodifiable(addOns),
      addInUnitPrices: Map.unmodifiable(addInPrices),
      addOnUnitPrices: Map.unmodifiable(addOnPrices),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.draft.product;
    return StreamBuilder<List<DrinkExtra>>(
      stream: _addInsStream,
      builder: (context, addInSnapshot) => StreamBuilder<List<DrinkExtra>>(
        stream: _addOnsStream,
        builder: (context, addOnSnapshot) =>
            _buildPage(product, addInSnapshot, addOnSnapshot),
      ),
    );
  }

  Widget _buildPage(
    MenuProduct product,
    AsyncSnapshot<List<DrinkExtra>> addInSnapshot,
    AsyncSnapshot<List<DrinkExtra>> addOnSnapshot,
  ) {
    final addInOptions = addInSnapshot.data ?? const <DrinkExtra>[];
    final addOnOptions = addOnSnapshot.data ?? const <DrinkExtra>[];
    final currentDraft = _draftForOptions(addInOptions, addOnOptions);
    final total = currentDraft.total;
    return CurvedContentPage(
      title: 'Customize your drink',
      bottomNavigationBar: widget.onNavigateTab == null
          ? null
          : MainBottomNavigationBar(
              selectedIndex: 2,
              onTap: (index) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                widget.onNavigateTab!(index);
              },
            ),
      actions: [
        IconButton(
          tooltip: 'Reset options',
          color: Colors.white,
          onPressed: () => setState(() {
            quantity = 1;
            size = product.sizes.isEmpty ? 'Regular' : product.sizes.first.$1;
            sizePrice = product.sizes.isEmpty
                ? product.price
                : product.price + product.sizes.first.$2;
            sugar = '50%';
            addIns.clear();
            addOns.clear();
          }),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _ProductSummary(
                  name: product.name,
                  size: size,
                  price: sizePrice,
                  image: product.imageAsset,
                  imageUrl: product.imageUrl,
                  isBestSeller: product.isBestSeller,
                  quantity: quantity,
                  onQuantity: (value) => setState(() => quantity = value),
                ),
                const SizedBox(height: 14),
                _OptionSection(
                  title: '1. Sugar',
                  options: _sugarOptionsFor(product),
                  selected: sugar,
                  onSelect: (value) => setState(() => sugar = value),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _panelDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '2. Add ins / your liking',
                        style: _sectionTitle,
                      ),
                      const SizedBox(height: 10),
                      if (addInSnapshot.hasError)
                        const _OptionsError(label: 'add-ins')
                      else if (addInSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !addInSnapshot.hasData)
                        const _OptionsLoading()
                      else if (addInOptions.isEmpty)
                        const _OptionsEmpty()
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final option in addInOptions)
                              FilterChip(
                                label: Text(
                                  '${option.name} · P${option.price}',
                                ),
                                selected: addIns.contains(option.name),
                                onSelected: (selected) => setState(() {
                                  if (selected) {
                                    addIns.add(option.name);
                                    _addInUnitPrices[option.name] =
                                        option.price;
                                  } else {
                                    addIns.remove(option.name);
                                  }
                                }),
                                selectedColor: AppColors.orangeTint,
                                checkmarkColor: AppColors.orange,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _panelDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3. Add-ons', style: _sectionTitle),
                      if (addOnSnapshot.hasError)
                        const _OptionsError(label: 'add-ons')
                      else if (addOnSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !addOnSnapshot.hasData)
                        const _OptionsLoading()
                      else if (addOnOptions.isEmpty)
                        const _OptionsEmpty()
                      else
                        for (final option in addOnOptions)
                          Material(
                            color: Colors.transparent,
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              activeColor: AppColors.orange,
                              title: Text(
                                '${option.name} (P${option.price})',
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: addOns.contains(option.name),
                              onChanged: (selected) => setState(() {
                                if (selected == true) {
                                  addOns.add(option.name);
                                  _addOnUnitPrices[option.name] = option.price;
                                } else {
                                  addOns.remove(option.name);
                                }
                              }),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            color: Colors.white,
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.local_cafe_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        'P$total',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    CartStore.add(currentDraft);
                    if (widget.onNavigateTab != null) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      widget.onNavigateTab!(2);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CartScreen(),
                        ),
                      );
                    }
                  },
                  child: Text('Add to cart  P$total'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<(String, String)> _sugarOptionsFor(MenuProduct product) {
    if (product.sugarLevels.isEmpty) return _sugarOptions;
    final options = product.sugarLevels.map((level) => (level, level)).toList();
    if (!product.sugarLevels.contains('50%')) options.insert(0, ('50%', '50%'));
    return options;
  }
}

class _OptionsLoading extends StatelessWidget {
  const _OptionsLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text('Loading options...', style: TextStyle(fontSize: 12)),
  );
}

class _OptionsEmpty extends StatelessWidget {
  const _OptionsEmpty();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      'No options available right now.',
      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
    ),
  );
}

class _OptionsError extends StatelessWidget {
  const _OptionsError({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      'Unable to load $label. Check your connection and Firestore access.',
      style: const TextStyle(fontSize: 12, color: Colors.red),
    ),
  );
}

const _panelDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(12)),
  border: Border.fromBorderSide(BorderSide(color: Color(0xFFE7E7E7))),
);

const _sectionTitle = TextStyle(fontSize: 14, fontWeight: FontWeight.w800);

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({
    required this.name,
    required this.size,
    required this.price,
    required this.image,
    required this.imageUrl,
    required this.isBestSeller,
    required this.quantity,
    required this.onQuantity,
  });

  final String name;
  final String size;
  final int price;
  final String image;
  final String? imageUrl;
  final bool isBestSeller;
  final int quantity;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _panelDecoration,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CloudinaryImage(
              url: imageUrl,
              fallbackAsset: image,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$size · P$price',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                if (isBestSeller)
                  const Text(
                    'Best Seller',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          _QuantityControl(quantity: quantity, onChanged: onQuantity),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          icon: const Icon(Icons.remove, size: 16),
          visualDensity: VisualDensity.compact,
        ),
        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          onPressed: () => onChanged(quantity + 1),
          icon: const Icon(Icons.add, size: 16),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _OptionSection extends StatelessWidget {
  const _OptionSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _sectionTitle),
          const SizedBox(height: 10),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selected == option.$1;
                return SizedBox(
                  width: 62,
                  child: InkWell(
                    onTap: () => onSelect(option.$1),
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 7,
                        horizontal: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.orangeTint : Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.orange
                              : const Color(0xFFE6E6E6),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_drink_rounded,
                            color: isSelected
                                ? AppColors.orange
                                : const Color(0xFF555555),
                            size: 19,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            option.$1,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            option.$2,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
