import 'package:cloud_firestore/cloud_firestore.dart';

import 'drink_extra.dart';

class DrinkExtraRepository {
  DrinkExtraRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String type) =>
      _firestore.collection(type == 'addIn' ? 'drinkAddIns' : 'drinkAddOns');

  Stream<List<DrinkExtra>> watchAddIns() => _watch('addIn');

  Stream<List<DrinkExtra>> watchAddOns() => _watch('addOn');

  Stream<List<DrinkExtra>> _watch(String type) => _collection(type)
      .snapshots()
      .map((snapshot) {
        final options = snapshot.docs
            .map((document) => DrinkExtra.fromMap(document.id, document.data()))
            .where(
              (option) =>
                  option.isAvailable &&
                  option.name.trim().isNotEmpty &&
                  option.price >= 0,
            )
            .toList();
        options.sort((first, second) {
          final byOrder = first.sortOrder.compareTo(second.sortOrder);
          return byOrder != 0 ? byOrder : first.name.compareTo(second.name);
        });
        return options;
      });

  Future<void> saveAddIn(DrinkExtra option) => _save('addIn', option);

  Future<void> saveAddOn(DrinkExtra option) => _save('addOn', option);

  Future<void> _save(String type, DrinkExtra option) async {
    final collection = _collection(type);
    final data = {
      ...option.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (option.id.isEmpty) {
      await collection.add(data);
    } else {
      await collection.doc(option.id).set(data, SetOptions(merge: true));
    }
  }
}
