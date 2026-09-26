import 'package:cloud_firestore/cloud_firestore.dart';

import 'advertisement.dart';

class AdvertisementRepository {
  AdvertisementRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _advertisements =>
      _firestore.collection('advertisements');

  Stream<List<Advertisement>> watchAll() => _advertisements.snapshots().map((
    snapshot,
  ) {
    final advertisements = snapshot.docs
        .map((document) => Advertisement.fromMap(document.id, document.data()))
        .toList();
    advertisements.sort((first, second) {
      final byOrder = first.sortOrder.compareTo(second.sortOrder);
      return byOrder != 0 ? byOrder : first.title.compareTo(second.title);
    });
    return advertisements;
  });

  Stream<List<Advertisement>> watchActive() => watchAll().map(
    (advertisements) => advertisements
        .where((advertisement) => advertisement.isActive)
        .toList(growable: false),
  );

  Future<String> save(Advertisement advertisement) async {
    final data = advertisement.toMap();
    if (advertisement.id.isEmpty) {
      final document = await _advertisements.add(data);
      return document.id;
    }
    await _advertisements.doc(advertisement.id).set(data);
    return advertisement.id;
  }

  Future<void> delete(String id) => _advertisements.doc(id).delete();
}
