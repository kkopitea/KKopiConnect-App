import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/product_favorites_repository.dart';

class FavoritesStore {
  FavoritesStore._();

  static final ValueNotifier<Set<String>> productIds = ValueNotifier({});
  static final ValueNotifier<bool> isLoading = ValueNotifier(false);
  static final ValueNotifier<String?> loadError = ValueNotifier(null);
  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _favoritesSubscription;
  static FavoritesRepository? _repositoryOverride;
  static FavoritesRepository get _repository =>
      _repositoryOverride ??
      ProductFavoritesRepository(
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
      );

  @visibleForTesting
  static set repositoryForTesting(FavoritesRepository? repository) {
    _repositoryOverride = repository;
  }

  static bool contains(String productId) =>
      productIds.value.contains(productId);

  static void startListening() {
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen(
      _listenToUserFavorites,
      onError: (Object error) {
        debugPrint('Unable to observe favorite sign-in state: $error');
        isLoading.value = false;
        loadError.value = 'Unable to load favorites. Please try again.';
      },
    );
  }

  static Future<void> toggle(String productId) =>
      setFavorite(productId, !contains(productId));

  static Future<void> remove(String productId) => setFavorite(productId, false);

  static Future<void> setFavorite(String productId, bool isFavorite) async {
    await _repository.setFavorite(productId, isFavorite);
  }

  static void _listenToUserFavorites(User? user) {
    _favoritesSubscription?.cancel();
    productIds.value = const {};
    loadError.value = null;
    isLoading.value = user != null;
    if (user == null) return;

    _favoritesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favoriteProducts')
        .snapshots()
        .listen(
          (snapshot) {
            if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
            productIds.value = Set.unmodifiable(
              snapshot.docs.map((document) => document.id),
            );
            isLoading.value = false;
            loadError.value = null;
          },
          onError: (Object error) {
            debugPrint('Unable to load saved favorites: $error');
            isLoading.value = false;
            loadError.value = 'Unable to load favorites. Please try again.';
          },
        );
  }
}
