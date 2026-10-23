import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_motivation.dart';
import 'auth_repository.dart';

class MotivationRepository {
  MotivationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static final Map<String, DailyMotivation> _localCache = {};
  static final Map<String, StreamController<DailyMotivation?>> _controllers = {};

  StreamController<DailyMotivation?> _controllerFor(String key) {
    return _controllers.putIfAbsent(
      key,
      () => StreamController<DailyMotivation?>.broadcast(),
    );
  }

  DocumentReference<Map<String, dynamic>> _docRef(String uid, String dateKey) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('motivation')
        .doc(dateKey);
  }

  Stream<DailyMotivation?> watchTodayMotivation(String uid, String dateKey) {
    final key = '${uid}_$dateKey';
    if (AuthRepository.isLocalUid(uid)) {
      final ctrl = _controllerFor(key);
      final initial = _localCache[key];
      return () async* {
        yield initial;
        yield* ctrl.stream;
      }();
    }

    try {
      return _docRef(uid, dateKey).snapshots().map((doc) {
        if (!doc.exists) return _localCache[key];
        return DailyMotivation.fromDoc(doc);
      }).handleError((_) => _localCache[key]);
    } catch (_) {
      return Stream.value(_localCache[key]);
    }
  }

  Future<DailyMotivation?> getTodayMotivation(String uid, String dateKey) async {
    final key = '${uid}_$dateKey';
    if (AuthRepository.isLocalUid(uid)) {
      return _localCache[key];
    }

    try {
      final doc = await _docRef(uid, dateKey).get();
      if (!doc.exists) return _localCache[key];
      return DailyMotivation.fromDoc(doc);
    } catch (_) {
      return _localCache[key];
    }
  }

  Future<DailyMotivation> getOrCreateTodayMotivation({
    required String uid,
    required String dateKey,
    required Future<List<MotivationOption>> Function() optionGenerator,
  }) async {
    final key = '${uid}_$dateKey';

    if (AuthRepository.isLocalUid(uid)) {
      final cached = _localCache[key];
      if (cached != null) return cached;

      final options = await optionGenerator();
      final created = DailyMotivation(
        date: dateKey,
        options: options,
        selectedIndex: null,
        selectedAt: null,
      );
      _localCache[key] = created;
      _controllerFor(key).add(created);
      return created;
    }

    try {
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
    } catch (_) {
      final cached = _localCache[key];
      if (cached != null) return cached;

      final options = await optionGenerator();
      final created = DailyMotivation(
        date: dateKey,
        options: options,
        selectedIndex: null,
        selectedAt: null,
      );
      _localCache[key] = created;
      _controllerFor(key).add(created);
      return created;
    }
  }

  Future<void> selectOption({
    required String uid,
    required String dateKey,
    required int optionIndex,
  }) async {
    final key = '${uid}_$dateKey';
    final current = _localCache[key];
    if (current != null && current.selectedIndex == null) {
      final updated = DailyMotivation(
        date: current.date,
        options: current.options,
        selectedIndex: optionIndex,
        selectedAt: DateTime.now(),
      );
      _localCache[key] = updated;
      _controllerFor(key).add(updated);
    }

    if (!AuthRepository.isLocalUid(uid)) {
      try {
        final ref = _docRef(uid, dateKey);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) return;
          final data = snapshot.data();
          if (data?['selectedIndex'] != null) return;
          transaction.update(ref, {
            'selectedIndex': optionIndex,
            'selectedAt': FieldValue.serverTimestamp(),
          });
        });
      } catch (_) {}
    }
  }
}
