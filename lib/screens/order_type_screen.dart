import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/order_draft.dart';
import '../data/payment_method.dart';
import '../data/payment_method_repository.dart';
import '../data/order_repository.dart';
import '../state/cart_store.dart';
import '../state/orders_store.dart';
import '../widgets/cloudinary_image.dart';
import '../widgets/curved_content_page.dart';
import '../widgets/main_bottom_navigation_bar.dart';
import 'order_confirmation_screen.dart';

class OrderTypeScreen extends StatefulWidget {
  const OrderTypeScreen({super.key, required this.drafts, this.onNavigateTab});

  final List<OrderDraft> drafts;
  final ValueChanged<int>? onNavigateTab;

  @override
  State<OrderTypeScreen> createState() => _OrderTypeScreenState();
}

class _OrderTypeScreenState extends State<OrderTypeScreen> {
  bool _pickup = true;
  bool _isPlacingOrder = false;
  String _paymentMethod = 'Pay At The Counter';
  bool _paymentMethodsLoaded = false;
  String? _paymentMethodsError;
  List<PaymentMethod> _paymentMethods = defaultPaymentMethods;
  late final StreamSubscription<List<PaymentMethod>>
  _paymentMethodsSubscription;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _paymentMethodsSubscription = PaymentMethodRepository()
        .watchActive()
        .listen(
          (methods) {
            if (!mounted) return;
            setState(() {
              _paymentMethods = methods;
              _paymentMethodsLoaded = true;
              _paymentMethodsError = null;
              if (!methods.any((method) => method.name == _paymentMethod) &&
                  methods.isNotEmpty) {
                _paymentMethod = methods.first.name;
              }
            });
          },
          onError: (Object error) {
            debugPrint('Unable to load payment methods: $error');
            if (mounted) {
              setState(() {
                _paymentMethodsLoaded = true;
                _paymentMethodsError = 'Payment methods could not be loaded.';
              });
            }
          },
        );
  }

  @override
  void dispose() {
    _paymentMethodsSubscription.cancel();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drafts = widget.drafts;
    final total = drafts.fold<int>(0, (sum, draft) => sum + draft.total);
    return CurvedContentPage(
      title: 'Order type & payment method',
      bottomNavigationBar: widget.onNavigateTab == null
          ? null
          : MainBottomNavigationBar(selectedIndex: 2, onTap: _navigateToTab),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                  title: 'Pick up',
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
              child: Column(
                children: [
                  if (_paymentMethodsError case final error?)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else if (!_paymentMethodsLoaded)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(),
                    )
                  else if (_paymentMethods.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No payment methods are available.'),
                    )
                  else
                    RadioGroup<String>(
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        if (value != null) setState(() => _paymentMethod = value);
                      },
                      child: Column(
                        children: [
                          for (var index = 0;
                              index < _paymentMethods.length;
                              index++) ...[
                            if (index > 0) const Divider(height: 1),
                            RadioListTile<String>(
                              value: _paymentMethods[index].name,
                              title: Text(
                                _paymentMethods[index].name,
                                style: const TextStyle(fontSize: 13),
                              ),
                              subtitle:
                                  _paymentMethods[index].instructions.isEmpty
                                  ? null
                                  : Text(_paymentMethods[index].instructions),
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.orange,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
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
              hintText: 'e.g. Extra creamy...',
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
            onPressed:
                _isPlacingOrder ||
                    drafts.isEmpty ||
                    _paymentMethodsError != null ||
                    !_paymentMethodsLoaded ||
                    _paymentMethods.isEmpty
                ? null
                : () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Your session expired. Please sign in again.',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() => _isPlacingOrder = true);
                    String? pendingOrderId;
                    try {
                      final order = OrdersStore.createOrder(
                        items: drafts,
                        fulfillment: _pickup ? 'Pickup' : 'Dine In',
                        paymentMethod: _paymentMethod,
                        instructions: _noteController.text.trim(),
                      );
                      pendingOrderId = order.id;

                      await FirestoreOrderRepository().saveOrder(
                        user.uid,
                        order,
                      );
                      CartStore.clear();

                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrderConfirmationScreen(
                            order: order,
                            onNavigateTab: widget.onNavigateTab,
                          ),
                        ),
                      );
                    } on FirebaseException catch (error, stackTrace) {
                      debugPrint(
                        'Unable to place order (${error.code}): $error\n$stackTrace',
                      );
                      if (pendingOrderId != null) {
                        OrdersStore.removeOrder(pendingOrderId);
                      }
                      if (!context.mounted) return;
                      final message = switch (error.code) {
                        'permission-denied' =>
                          'Order was not saved. Check Firestore order permissions and App Check setup.',
                        'unauthenticated' =>
                          'Your session expired. Please sign in again.',
                        'unavailable' || 'deadline-exceeded' =>
                          'Could not reach the order service. Check your connection and try again.',
                        _ =>
                          'Could not save your order (${error.code}). Please try again.',
                      };
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    } catch (error, stackTrace) {
                      debugPrint('Unable to place order: $error\n$stackTrace');
                      if (pendingOrderId != null) {
                        OrdersStore.removeOrder(pendingOrderId);
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not place the order. Please try again.',
                          ),
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isPlacingOrder = false);
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
            ),
            child: _isPlacingOrder
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Place Order',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }

  void _navigateToTab(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onNavigateTab?.call(index);
  }
}

class _OrderLineSummary extends StatelessWidget {
  const _OrderLineSummary({required this.draft});

  final OrderDraft draft;

  @override
  Widget build(BuildContext context) {
    final customizations = [
      '${draft.size} · ${draft.sugar} sugar',
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
