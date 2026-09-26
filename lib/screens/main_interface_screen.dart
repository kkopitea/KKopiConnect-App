import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'chatbot_screen.dart';
import 'home_screen.dart';
import 'order_list_screen.dart';
import 'profile_screen.dart';

class MainInterfaceScreen extends StatefulWidget {
  const MainInterfaceScreen({super.key});

  @override
  State<MainInterfaceScreen> createState() => _MainInterfaceScreenState();
}

class _MainInterfaceScreenState extends State<MainInterfaceScreen> {
  int _selectedIndex = 0;

  late final _pages = <Widget>[
    HomeScreen(onSeeAllCategories: () => _selectTab(1)),
    CategoriesScreen(onNavigateTab: _selectTab),
    CartScreen(),
    OrderListScreen(),
    ProfileScreen(onNavigateTab: _selectTab),
  ];

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  static const _navigationItems = [
    (Icons.home_rounded, 'Home'),
    (Icons.category_rounded, 'Categories'),
    (Icons.shopping_bag_outlined, 'Cart'),
    (Icons.receipt_long_rounded, 'Orders'),
    (Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      floatingActionButton: _selectedIndex == 4
          ? null
          : FloatingActionButton.extended(
              heroTag: 'main-ai-chat-fab',
              tooltip: 'Chat with KKOPI.TEA Assistant',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ChatbotScreen()),
              ),
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.smart_toy_rounded, size: 25),
              label: const Text(
                'KKOPI.BOT',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(4, 7, 4, bottomInset + 7),
        child: Row(
          children: [
            for (var index = 0; index < _navigationItems.length; index++)
              Expanded(
                child: _NavigationItem(
                  icon: _navigationItems[index].$1,
                  label: _navigationItems[index].$2,
                  selected: _selectedIndex == index,
                  onTap: () => _selectTab(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.orange : AppColors.iconMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w700,
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
