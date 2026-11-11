import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/menu_catalog.dart';

class MenuProductsStatusBanner extends StatelessWidget {
  const MenuProductsStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) return const SizedBox.shrink();
    final projectId = Firebase.app().options.projectId;
    return ValueListenableBuilder<MenuProductsLoadStatus>(
      valueListenable: menuProductsLoadStatus,
      builder: (context, status, _) {
        final message = status.message(projectId);
        if (message.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: status.phase == MenuProductsLoadPhase.loading
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: status.phase == MenuProductsLoadPhase.loading
                  ? AppColors.orange
                  : const Color(0xFFD32F2F),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (status.phase == MenuProductsLoadPhase.loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              else
                const Icon(Icons.cloud_off_rounded, color: Color(0xFFD32F2F)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
