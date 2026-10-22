import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_motivation.dart';

class MotivationRepository {
  MotivationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _docRef(String uid, String dateKey) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('motivation')
        .doc(dateKey);
  }

  Stream<DailyMotivation?> watchTodayMotivation(String uid, String dateKey) {
    return _docRef(uid, dateKey).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DailyMotivation.fromDoc(doc);
    });
  }

  Future<DailyMotivation?> getTodayMotivation(String uid, String dateKey) async {
    final doc = await _docRef(uid, dateKey).get();
    if (!doc.exists) return null;
    return DailyMotivation.fromDoc(doc);
  }

  Future<DailyMotivation> getOrCreateTodayMotivation({
    required String uid,
    required String dateKey,
    required Future<List<MotivationOption>> Function() optionGenerator,
  }) async {
    final ref = _docRef(uid, dateKey);
    final doc = await ref.get();
    if (doc.exists) {
      return DailyMotivation.fromDoc(doc);
    }

    final options = await optionGenerator();
    final newMotivation = DailyMotivation(
      date: dateKey,
      options: options,
      selectedIndex: null,
      selectedAt: null,
    );

    await ref.set(newMotivation.toMap(), SetOptions(merge: true));
    return newMotivation;
  }

  Future<void> selectOption({
    required String uid,
    required String dateKey,
    required int optionIndex,
  }) async {
    final ref = _docRef(uid, dateKey);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        throw StateError('Günün motivasyon kartları bulunamadı.');
      }

      final data = snapshot.data();
      final currentSelected = data?['selectedIndex'];

      // Only allow selection if not already chosen
      if (currentSelected != null) {
        return; // Already chosen today, lock prevents overwrite
      }

      transaction.update(ref, {
        'selectedIndex': optionIndex,
        'selectedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
