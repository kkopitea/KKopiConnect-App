import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract interface class FavoritesRepository {
  Future<void> setFavorite(String productId, bool isFavorite);
}

class ProductFavoritesRepository implements FavoritesRepository {
  const ProductFavoritesRepository({
    required this.firestore,
    required this.auth,
  });

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  @override
  Future<void> setFavorite(String productId, bool isFavorite) async {
    final user = auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to save or remove a favorite.');
    }

    final uid = user.uid;
    final summary = firestore.collection('productLikes').doc(productId);
    final like = summary.collection('users').doc(uid);
    final favorite = firestore
        .collection('users')
        .doc(uid)
        .collection('favoriteProducts')
        .doc(productId);

    await firestore.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(like);
      final summarySnapshot = await transaction.get(summary);
      final favoriteSnapshot = await transaction.get(favorite);
      final wasFavorite = likeSnapshot.exists;

      if (wasFavorite != isFavorite) {
        final previousCount = summarySnapshot.data()?['favoriteCount'];
        final count = previousCount is num ? previousCount.toInt() : 0;
        if (!isFavorite && (!summarySnapshot.exists || count == 0)) {
          throw StateError(
            'The favorite count is out of sync. Please try again later.',
          );
        }
        transaction.set(summary, {
          'productId': productId,
          'favoriteCount': isFavorite ? count + 1 : count - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (isFavorite) {
        if (!likeSnapshot.exists) {
          transaction.set(like, {
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        if (!favoriteSnapshot.exists) {
          transaction.set(favorite, {
            'productId': productId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        if (likeSnapshot.exists) transaction.delete(like);
        if (favoriteSnapshot.exists) transaction.delete(favorite);
      }
    });
  }
}
