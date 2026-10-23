import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final authUidProvider = StreamProvider<String?>((ref) {
  return ref.watch(authRepositoryProvider).authUidChanges();
});

final uidProvider = Provider<String?>((ref) {
  final streamVal = ref.watch(authUidProvider).value;
  return streamVal ?? ref.watch(authRepositoryProvider).currentUid;
});

final appUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(userRepositoryProvider).watchUser(uid);
});
