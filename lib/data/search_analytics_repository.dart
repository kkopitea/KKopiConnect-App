import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class SearchAnalyticsRepository {
  SearchAnalyticsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _popularSearches =>
      _firestore.collection('popularSearches');

  Stream<List<String>> watchPopularSearches({int limit = 5}) =>
      _popularSearches
          .orderBy('searchCount', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((document) => document.data()['term'])
                .whereType<String>()
                .toList(growable: false),
          );

  Future<void> recordSearch(String rawTerm) async {
    final term = rawTerm.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (term.isEmpty) return;

    final normalizedTerm = term.toLowerCase();
    final documentId = base64Url
        .encode(utf8.encode(normalizedTerm))
        .replaceAll('=', '');
    await _popularSearches.doc(documentId).set({
      'term': term,
      'searchCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
