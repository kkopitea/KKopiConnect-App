import 'package:flutter/material.dart';

import '../app_colors.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('Milk Tea', Icons.local_drink_rounded),
      ('Coffee', Icons.coffee_rounded),
      ('Fruit Tea', Icons.emoji_food_beverage_rounded),
      ('Boba', Icons.icecream_rounded),
      ('Smoothie', Icons.soup_kitchen_rounded),
      ('Snacks', Icons.fastfood_rounded),
    ];

    return Scaffold(
      backgroundColor: AppColors.orange,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1080,
              maxHeight: 2400,
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Expanded(
                        child: Text(
                          'Categories',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                      itemCount: categories.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        final entry = categories[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.orangeTint,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(entry.$2, color: AppColors.orange, size: 28),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                entry.$1,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
