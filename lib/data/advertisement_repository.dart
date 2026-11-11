import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'advertisement.dart';

class AdvertisementRepository {
  AdvertisementRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _advertisements =>
      _firestore.collection('advertisements');

  Stream<List<Advertisement>> watchAll() {
    final controller = StreamController<List<Advertisement>>();
    List<Advertisement>? advertisements;
    List<Advertisement>? promotions;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    advertisementsSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    promotionsSubscription;

    void emitIfReady() {
      final currentAdvertisements = advertisements;
      final currentPromotions = promotions;
      if (currentAdvertisements == null || currentPromotions == null) return;
      controller.add(sort([...currentAdvertisements, ...currentPromotions]));
    }

    controller.onListen = () {
      advertisementsSubscription = _advertisements.snapshots().listen(
        (snapshot) {
          advertisements = snapshot.docs
              .map(
                (document) =>
                    Advertisement.fromMap(document.id, document.data()),
              )
              .toList(growable: false);
          emitIfReady();
        },
        onError: (Object error, StackTrace stackTrace) {
          controller.addError(error, stackTrace);
        },
      );
      promotionsSubscription = _firestore
          .collection('promotions')
          .snapshots()
          .listen(
            (snapshot) {
              promotions = snapshot.docs
                  .map(
                    (document) => Advertisement.fromMap(
                      'promotions-${document.id}',
                      document.data(),
                    ),
                  )
                  .toList(growable: false);
              emitIfReady();
            },
            onError: (Object error, StackTrace stackTrace) {
              controller.addError(error, stackTrace);
            },
          );
    };
    controller.onPause = () {
      advertisementsSubscription?.pause();
      promotionsSubscription?.pause();
    };
    controller.onResume = () {
      advertisementsSubscription?.resume();
      promotionsSubscription?.resume();
    };
    controller.onCancel = () async {
      await advertisementsSubscription?.cancel();
      await promotionsSubscription?.cancel();
    };

    return controller.stream;
  }

  static List<Advertisement> sort(List<Advertisement> advertisements) {
    final sorted = List<Advertisement>.of(advertisements);
    sorted.sort((first, second) {
      final byOrder = first.sortOrder.compareTo(second.sortOrder);
      if (byOrder != 0) return byOrder;
      final byTitle = first.title.compareTo(second.title);
      return byTitle != 0 ? byTitle : first.id.compareTo(second.id);
    });
    return sorted;
  }

  Stream<List<Advertisement>> watchActive() => watchAll().map(
    (advertisements) => advertisements
        .where((advertisement) => advertisement.isAvailableAt(DateTime.now()))
        .toList(growable: false),
  );

  Future<String> save(Advertisement advertisement) async {
    if (advertisement.startAt case final startAt?) {
      final endAt = advertisement.endAt;
      if (endAt != null && !endAt.isAfter(startAt)) {
        throw ArgumentError('Promotion endAt must be after startAt.');
      }
    }
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
