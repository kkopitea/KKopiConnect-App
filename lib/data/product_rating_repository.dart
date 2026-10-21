import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductRatingSummary {
  const ProductRatingSummary({
    required this.average,
    required this.count,
    required this.total,
  });

  const ProductRatingSummary.empty() : average = 0, count = 0, total = 0;

  final double average;
  final int count;
  final int total;

  factory ProductRatingSummary.fromData(Map<String, dynamic>? data) {
    final rawAverage = data?['ratingAverage'];
    final rawCount = data?['ratingCount'];
    final rawTotal = data?['ratingTotal'];
    final count = rawCount is num ? rawCount.toInt() : 0;
    final average = rawAverage is num
        ? rawAverage.toDouble().clamp(0, 5).toDouble()
        : 0.0;
    final total = rawTotal is num ? rawTotal.toInt() : 0;
    if (count <= 0 || total < count || total > count * 5) {
      return const ProductRatingSummary.empty();
    }
    final expectedAverage = total / count;
    if (rawAverage is! num ||
        (rawAverage.toDouble() - expectedAverage).abs() > 0.000001) {
      return const ProductRatingSummary.empty();
    }
    return ProductRatingSummary(average: average, count: count, total: total);
  }
}

class ProductRatingRepository {
  const ProductRatingRepository({required this.firestore, required this.auth});

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  Stream<ProductRatingSummary> watchSummary(String productId) => firestore
      .collection('productRatings')
      .doc(productId)
      .snapshots()
      .map((snapshot) => ProductRatingSummary.fromData(snapshot.data()));

  Stream<int?> watchUserRating(String productId) =>
      auth.authStateChanges().asyncExpand((user) {
        if (user == null) return Stream<int?>.value(null);
        return firestore
            .collection('productRatings')
            .doc(productId)
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .map((snapshot) {
              final rating = snapshot.data()?['rating'];
              return rating is num ? rating.toInt() : null;
            });
      });

  Future<void> setRating(String productId, int rating) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Must be between 1 and 5.');
    }
    final user = auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to rate this product.');
    }

    final summary = firestore.collection('productRatings').doc(productId);
    final userRating = summary.collection('users').doc(user.uid);
    await firestore.runTransaction((transaction) async {
      final summarySnapshot = await transaction.get(summary);
      final userRatingSnapshot = await transaction.get(userRating);
      final data = summarySnapshot.data();
      final oldCount = (data?['ratingCount'] as num?)?.toInt() ?? 0;
      final oldTotal = (data?['ratingTotal'] as num?)?.toInt() ?? 0;
      final previousRating = (userRatingSnapshot.data()?['rating'] as num?)
          ?.toInt();
      if (previousRating == rating) return;

      final count = oldCount + (previousRating == null ? 1 : 0);
      final total = oldTotal - (previousRating ?? 0) + rating;
      if (count <= 0 || total < count || total > count * 5) {
        throw StateError(
          'The product rating summary is out of sync. Please try again later.',
        );
      }

      transaction.set(summary, {
        'productId': productId,
        'ratingCount': count,
        'ratingTotal': total,
        'ratingAverage': total / count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(userRating, {
        'uid': user.uid,
        'rating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
