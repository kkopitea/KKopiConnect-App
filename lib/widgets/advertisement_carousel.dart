import 'dart:async';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/advertisement.dart';
import '../data/advertisement_repository.dart';

class AdvertisementCarousel extends StatefulWidget {
  const AdvertisementCarousel({super.key, required this.onSelect, this.height});

  final ValueChanged<Advertisement> onSelect;
  final double? height;

  @override
  State<AdvertisementCarousel> createState() => _AdvertisementCarouselState();
}

class _AdvertisementCarouselState extends State<AdvertisementCarousel> {
  final _pageController = PageController();
  late final _advertisementStream = _watchAdvertisements();
  int _activePage = 0;
  Timer? _autoAdvanceTimer;
  String? _advertisementSignature;

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Stream<List<Advertisement>> _watchAdvertisements() {
    try {
      return AdvertisementRepository().watchAll();
    } catch (error, stackTrace) {
      debugPrint('Unable to watch advertisements: $error');
      return Stream<List<Advertisement>>.error(
        error,
        stackTrace,
      ).asBroadcastStream();
    }
  }

  void _syncAutoAdvance(List<Advertisement> advertisements) {
    final signature = advertisements.map((ad) => ad.id).join('|');
    if (signature == _advertisementSignature) return;

    final hasExistingAdvertisements = _advertisementSignature != null;
    _advertisementSignature = signature;
    _autoAdvanceTimer?.cancel();
    if (hasExistingAdvertisements) {
      _activePage = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
    if (advertisements.length < 2) return;

    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final bannerHeight = widget.height ?? (compact ? 190.0 : 158.0);

    return StreamBuilder<List<Advertisement>>(
      stream: _advertisementStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Promotion carousel failed to load: ${snapshot.error}');
          return Container(
            height: bannerHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Promotions are temporarily unavailable',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        final advertisements = (snapshot.data ?? const <Advertisement>[])
            .where((advertisement) => advertisement.isActive)
            .toList(growable: false);
        _syncAutoAdvance(advertisements);

        if (advertisements.isEmpty) {
          return const SizedBox.shrink();
        }

        final selectedPage = _activePage % advertisements.length;

        return Container(
          height: bannerHeight,
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  key: ValueKey(advertisements.map((ad) => ad.id).join('|')),
                  controller: _pageController,
                  itemCount: 1000000,
                  onPageChanged: (index) => setState(() => _activePage = index),
                  itemBuilder: (context, index) {
                    final advertisement =
                        advertisements[index % advertisements.length];
                    final imageUrl = advertisement.imageUrl.trim();
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                advertisement.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 15 : 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: compact ? 5 : 8),
                              Text(
                                advertisement.eyebrow,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 9 : 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                advertisement.description,
                                maxLines: compact ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 9 : 10,
                                  height: 1.25,
                                ),
                              ),
                              SizedBox(height: compact ? 5 : 7),
                              SizedBox(
                                height: compact ? 27 : 29,
                                child: FilledButton(
                                  onPressed: () =>
                                      widget.onSelect(advertisement),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  child: Text(advertisement.buttonLabel),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: compact ? 88 : 126,
                                  height: compact ? 110 : 128,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _fallbackImage(compact),
                                )
                              : _fallbackImage(compact),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (advertisements.length > 1) ...[
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < advertisements.length; index++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Semantics(
                          button: true,
                          selected: index == selectedPage,
                          label: 'Announcement ${index + 1}',
                          child: GestureDetector(
                            onTap: () => _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: index == selectedPage
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _fallbackImage(bool compact) => Image.asset(
    'assets/images/login_drinks.png',
    width: compact ? 88 : 126,
    height: compact ? 110 : 128,
    fit: BoxFit.contain,
  );
}
