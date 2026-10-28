import 'dart:async';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/advertisement.dart';
import '../data/advertisement_repository.dart';

class AdvertisementCarousel extends StatefulWidget {
  const AdvertisementCarousel({
    super.key,
    required this.onSelect,
    this.height,
    this.advertisements,
  });

  final ValueChanged<Advertisement> onSelect;
  final double? height;
  final Stream<List<Advertisement>>? advertisements;

  @override
  State<AdvertisementCarousel> createState() => _AdvertisementCarouselState();
}

class _AdvertisementCarouselState extends State<AdvertisementCarousel> {
  final _pageController = PageController();
  late final _advertisementStream =
      widget.advertisements ?? _watchAdvertisements();
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
      return AdvertisementRepository().watchActive();
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
      final nextPage = (_activePage + 1) % advertisements.length;
      _pageController.animateToPage(
        nextPage,
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
          return _statusCard(
            bannerHeight,
            'Promotions are temporarily unavailable',
            icon: Icons.wifi_off_rounded,
          );
        }
        final advertisements = (snapshot.data ?? const <Advertisement>[])
            .where((advertisement) => advertisement.isActive)
            .toList(growable: false);
        _syncAutoAdvance(advertisements);

        if (advertisements.isEmpty) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _statusCard(
              bannerHeight,
              'Loading promotions...',
              loading: true,
            );
          }
          return _statusCard(bannerHeight, 'No active promotions');
        }

        final selectedPage = _activePage % advertisements.length;

        final borderRadius = BorderRadius.circular(14);
        return Container(
          height: bannerHeight,
          decoration: BoxDecoration(
            gradient: AppColors.orangeGradient,
            borderRadius: borderRadius,
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onSelect(advertisements[selectedPage]),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      key: ValueKey(
                        advertisements.map((ad) => ad.id).join('|'),
                      ),
                      controller: _pageController,
                      itemCount: advertisements.length,
                      onPageChanged: (index) =>
                          setState(() => _activePage = index),
                      itemBuilder: (context, index) {
                        final advertisement =
                            advertisements[index % advertisements.length];
                        return Semantics(
                          label: advertisement.title,
                          button: true,
                          child: _AdvertisementImageGallery(
                            key: ValueKey(advertisement.id),
                            imageUrls: advertisement.campaignImageUrls,
                          ),
                        );
                      },
                    ),
                    if (advertisements.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (
                              var index = 0;
                              index < advertisements.length;
                              index++
                            )
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Semantics(
                                  button: true,
                                  selected: index == selectedPage,
                                  label: 'Announcement ${index + 1}',
                                  child: GestureDetector(
                                    onTap: () => _pageController.animateToPage(
                                      index,
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOut,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: index == selectedPage
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusCard(
    double height,
    String message, {
    bool loading = false,
    IconData icon = Icons.local_offer_outlined,
  }) => Container(
    height: height,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: AppColors.orangeGradient,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        else
          Icon(icon, color: Colors.white),
        const SizedBox(width: 9),
        Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _AdvertisementImageGallery extends StatefulWidget {
  const _AdvertisementImageGallery({super.key, required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_AdvertisementImageGallery> createState() =>
      _AdvertisementImageGalleryState();
}

class _AdvertisementImageGalleryState
    extends State<_AdvertisementImageGallery> {
  final _pageController = PageController();
  int _activePage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.imageUrls.length;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageCount == 0)
          _fallbackImage()
        else
          PageView.builder(
            controller: _pageController,
            itemCount: imageCount,
            onPageChanged: (index) => setState(() => _activePage = index),
            itemBuilder: (context, index) => Image.network(
              widget.imageUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallbackImage(),
            ),
          ),
        if (imageCount > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < imageCount; index++)
                  Semantics(
                    label: 'Campaign image ${index + 1}',
                    selected: index == _activePage,
                    child: Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index == _activePage
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _fallbackImage() =>
      Image.asset('assets/images/login_drinks.png', fit: BoxFit.cover);
}
