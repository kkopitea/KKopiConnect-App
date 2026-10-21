import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/menu_catalog.dart';
import '../data/product_rating_repository.dart';

class ProductRatingsStore {
  ProductRatingsStore._();

  static final ValueNotifier<Map<String, ProductRatingSummary>> summaries =
      ValueNotifier(const {});
  static final ValueNotifier<bool> isLoading = ValueNotifier(true);
  static final ValueNotifier<String?> loadError = ValueNotifier(null);
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  static void startListening() {
    if (_subscription != null) return;
    isLoading.value = true;
    _subscription = FirebaseFirestore.instance
        .collection('productRatings')
        .snapshots()
        .listen(
          (snapshot) {
            summaries.value = Map.unmodifiable({
              for (final document in snapshot.docs)
                document.id: ProductRatingSummary.fromData(document.data()),
            });
            isLoading.value = false;
            loadError.value = null;
          },
          onError: (Object error) {
            debugPrint('Unable to load product ratings: $error');
            isLoading.value = false;
            loadError.value =
                'Unable to load product ratings. Please try again.';
          },
        );
  }

  static ProductRatingSummary summary(String productId) =>
      summaries.value[productId] ?? const ProductRatingSummary.empty();

  static List<MenuProduct> bestRatedProducts(
    List<MenuProduct> products, {
    int? limit,
  }) {
    final ranked =
        products.where((product) => summary(product.id).count > 0).toList()
          ..sort((first, second) {
            final byAverage = summary(
              second.id,
            ).average.compareTo(summary(first.id).average);
            if (byAverage != 0) return byAverage;
            final byCount = summary(
              second.id,
            ).count.compareTo(summary(first.id).count);
            return byCount != 0 ? byCount : first.name.compareTo(second.name);
          });
    final productsToShow = ranked.isEmpty
        ? products.where((product) => product.isBestSeller).toList()
        : ranked;
    return limit == null ? productsToShow : productsToShow.take(limit).toList();
  }

  static bool isBestSeller(String productId, List<MenuProduct> products) =>
      bestRatedProducts(
        products,
        limit: 3,
      ).any((product) => product.id == productId);

  static final ProductRatingRepository _repository = ProductRatingRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );

  static Stream<ProductRatingSummary> watchSummary(String productId) =>
      _repository.watchSummary(productId);

  static Stream<int?> watchUserRating(String productId) =>
      _repository.watchUserRating(productId);

  static Future<void> setRating(String productId, int rating) =>
      _repository.setRating(productId, rating);
}
