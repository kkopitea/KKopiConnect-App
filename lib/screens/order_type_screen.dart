import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/order_draft.dart';
import '../state/cart_store.dart';
import '../state/orders_store.dart';
import '../widgets/cloudinary_image.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'order_confirmation_screen.dart';
import 'order_list_screen.dart';
import 'profile_screen.dart';

class OrderTypeScreen extends StatefulWidget {
  const OrderTypeScreen({super.key, required this.drafts});

  final List<OrderDraft> drafts;

  @override
  State<OrderTypeScreen> createState() => _OrderTypeScreenState();
}

class _OrderTypeScreenState extends State<OrderTypeScreen> {
  bool _pickup = true;
  String _paymentMethod = 'Pay At The Counter';
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drafts = widget.drafts;
    final total = drafts.fold<int>(0, (sum, draft) => sum + draft.total);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Order type & Payment method'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'How would you like to receive your order?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ReceiveOption(
                    icon: Icons.table_restaurant_rounded,
                    title: 'Dine In',
                    subtitle: 'Enjoy in our store',
                    selected: !_pickup,
                    onTap: () => setState(() => _pickup = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReceiveOption(
                    icon: Icons.delivery_dining_rounded,
                    title: 'Place Order',
                    subtitle: 'Ready for pickup',
                    selected: _pickup,
                    onTap: () => setState(() => _pickup = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE1E1E1)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: RadioGroup<String>(
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    if (value != null) setState(() => _paymentMethod = value);
                  },
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        value: 'Pay At The Counter',
                        title: Text(
                          'Pay At The Counter',
                          style: TextStyle(fontSize: 13),
                        ),
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.orange,
                      ),
                      Divider(height: 1),
                      RadioListTile<String>(
                        value: 'Gcash',
                        title: Text('Gcash', style: TextStyle(fontSize: 13)),
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.orange,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Special Instructions (Optional)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Less ice, extra creamy...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.orange,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < drafts.length; index++) ...[
                    if (index > 0) const Divider(height: 18),
                    _OrderLineSummary(draft: drafts[index]),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'P$total',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                final order = OrdersStore.createOrder(
                  items: drafts,
                  fulfillment: _pickup ? 'Pickup' : 'Dine In',
                  paymentMethod: _paymentMethod,
                  instructions: _noteController.text.trim(),
                );
                CartStore.clear();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderConfirmationScreen(order: order),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
              ),
              child: const Text(
                'Place Order',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.iconMuted,
        onTap: (index) => _openNavigation(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_rounded),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _openNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
        );
        break;
      case 2:
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const CartScreen()));
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const OrderListScreen()),
        );
        break;
      case 4:
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
        break;
    }
  }
}

class _OrderLineSummary extends StatelessWidget {
  const _OrderLineSummary({required this.draft});

  final OrderDraft draft;

  @override
  Widget build(BuildContext context) {
    final customizations = [
      '${draft.size} · ${draft.sugar} sugar · ${draft.ice} ice',
      ...draft.addIns,
      ...draft.addOns,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CloudinaryImage(
            url: draft.product.imageUrl,
            fallbackAsset: draft.product.imageAsset,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${draft.product.name} × ${draft.quantity}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                customizations.join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'P${draft.total}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _ReceiveOption extends StatelessWidget {
  const _ReceiveOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 128),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppColors.orangeTint : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.orange : const Color(0xFFE0E0E0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 38, color: Colors.black87),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
              if (selected)
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.orange,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
