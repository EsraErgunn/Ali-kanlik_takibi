import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final uidProvider = Provider<String?>((ref) {
  return 'current';
});

final appUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(userRepositoryProvider).watchUser('current');
});
