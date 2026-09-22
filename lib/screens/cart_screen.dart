import 'package:flutter/material.dart';

import '../app_colors.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<_CartItem> _items = [
    _CartItem(
      name: 'Vanilla Americano Latte Tea',
      size: 'Medium',
      details: ['50% Sugar', '50% Ice'],
      image: 'assets/images/welcome_drink.png',
      price: 50,
    ),
    _CartItem(
      name: 'Cookies and Cream boba',
      size: 'Regular',
      details: ['50% Sugar', '25% Ice'],
      image: 'assets/images/welcome_customize.png',
      price: 50,
    ),
    _CartItem(
      name: 'Caramel Caffuccino',
      size: 'Regular',
      details: ['50% Sugar'],
      image: 'assets/images/kkopitea_drink.png',
      price: 50,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.orange,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 42),
            decoration: const BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40),
                ),
                const Expanded(
                  child: Text(
                    'My Cart',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _items.isEmpty
                        ? const Center(child: Text('Your cart is empty'))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                            itemCount: _items.length,
                            separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFE6E6E6)),
                            itemBuilder: (context, index) => _buildCartItem(context, index),
                          ),
                  ),
                  _buildSummary(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, int index) {
    final item = _items[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD9B0),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(7),
            child: Image.asset(item.image, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 84,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        Text('Size: ${item.size}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ...item.details.map((detail) => Text('• $detail', style: const TextStyle(fontSize: 10, color: AppColors.textMuted))),
                        const Spacer(),
                        Text('P${item.price * item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      onPressed: () => setState(() => _items.removeAt(index)),
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF888888)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: -2,
                    child: _QuantityStepper(
                      quantity: item.quantity,
                      onDecrease: () => setState(() => item.quantity = item.quantity > 1 ? item.quantity - 1 : 1),
                      onIncrease: () => setState(() => item.quantity++),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final subtotal = _items.fold<int>(0, (sum, item) => sum + item.price * item.quantity);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal (2 items)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)), Text('P$subtotal', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), Text('P$subtotal', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _items.isEmpty ? null : () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Proceed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItem {
  _CartItem({required this.name, required this.size, required this.details, required this.image, required this.price});
  final String name;
  final String size;
  final List<String> details;
  final String image;
  final int price;
  int quantity = 1;
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onDecrease, required this.onIncrease});
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(color: const Color(0xFFF4F4F4), border: Border.all(color: const Color(0xFFD7D7D7)), borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepButton(Icons.remove, onDecrease),
          SizedBox(width: 24, child: Center(child: Text('$quantity', style: const TextStyle(fontSize: 12)))),
          _stepButton(Icons.add, onIncrease),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onPressed) {
    return InkWell(onTap: onPressed, child: SizedBox(width: 27, height: 28, child: Icon(icon, size: 14, color: const Color(0xFF555555))));
  }
}
