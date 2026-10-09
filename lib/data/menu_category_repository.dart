import 'package:cloud_firestore/cloud_firestore.dart';

import 'menu_catalog.dart';

class MenuCategoryRepository {
  MenuCategoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');

  Stream<List<MenuCategory>> watchCategories() =>
      _categories.snapshots().map((snapshot) {
        final categories = snapshot.docs
            .map(
              (document) =>
                  MenuCategory.fromFirestore(document.id, document.data()),
            )
            .where((category) => category.name.trim().isNotEmpty)
            .toList();
        categories.sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          return byOrder == 0 ? a.name.compareTo(b.name) : byOrder;
        });
        return List.unmodifiable(categories);
      });

  Future<void> save(
    MenuCategory category, {
    required String iconKey,
    int sortOrder = 0,
  }) async {
    if (category.id.trim().isEmpty || category.name.trim().isEmpty) {
      throw ArgumentError('Category id and name are required.');
    }
    await _categories.doc(category.id).set({
      'name': category.name.trim(),
      'iconKey': iconKey,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
