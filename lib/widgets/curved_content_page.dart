import 'package:flutter/material.dart';

import '../app_colors.dart';

class CurvedContentPage extends StatelessWidget {
  const CurvedContentPage({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.orange,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 108,
              child: Align(
                alignment: const Alignment(0, -0.18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      if (canPop)
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                          color: Colors.white,
                          icon: const Icon(Icons.arrow_back_rounded),
                        )
                      else
                        const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ).copyWith(
                                fontSize: title.length > 22
                                    ? 16
                                    : title.length > 18
                                    ? 18
                                    : 21,
                              ),
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: 84,
              child: Material(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
