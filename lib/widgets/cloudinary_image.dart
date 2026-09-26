import 'package:flutter/material.dart';

class CloudinaryImage extends StatelessWidget {
  const CloudinaryImage({
    super.key,
    required this.fallbackAsset,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final String? url;
  final String fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    if (imageUrl == null || imageUrl.isEmpty) return _fallback();

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() => Image.asset(
    fallbackAsset,
    width: width,
    height: height,
    fit: fit,
    semanticLabel: semanticLabel,
  );
}
