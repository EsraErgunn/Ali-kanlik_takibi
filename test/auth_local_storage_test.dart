import 'package:bloom_habit/data/models/habit.dart';
import 'package:bloom_habit/data/repositories/auth_repository.dart';
import 'package:bloom_habit/data/repositories/habit_repository.dart';
import 'package:bloom_habit/data/repositories/user_repository.dart';
import 'package:bloom_habit/data/services/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStorageService.instance.init();
  });

  test('Local registration, login, and duplicate rejection work properly', () async {
    final authRepo = AuthRepository();

    // 1. Register local account
    final email = 'test_flora_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final password = 'password123';
    final regResult = await authRepo.registerWithEmail(email, password);

    expect(regResult.uid, isNotEmpty);
    expect(regResult.uid.startsWith('local_'), isTrue);
    expect(authRepo.currentUid, equals(regResult.uid));

    // 2. Duplicate registration fails
    expect(
      () => authRepo.registerWithEmail(email, 'anotherpassword'),
      throwsA(isA<String>().having((msg) => msg, 'message', contains('zaten'))),
    );

    // 3. Log out
    await authRepo.signOut();
    expect(authRepo.currentUid, isNull);

    // 4. Log in with wrong password fails
    expect(
      () => authRepo.signInWithEmail(email, 'wrongpass'),
      throwsA(isA<String>().having((msg) => msg, 'message', contains('hatalı'))),
    );

    // 5. Log in with correct password succeeds
    final loginResult = await authRepo.signInWithEmail(email, password);
    expect(loginResult.uid, equals(regResult.uid));
    expect(authRepo.currentUid, equals(regResult.uid));
  });

  test('UserRepository and HabitRepository operate seamlessly with local UIDs', () async {
    final userRepo = UserRepository();
    final habitRepo = HabitRepository();

    final localUid = 'local_user_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Initial user creation
    await userRepo.createInitialUser(uid: localUid, characterId: 'char_2');
    final user = await userRepo.getUser(localUid);
    expect(user, isNotNull);
    expect(user!.characterId, equals('char_2'));
    expect(user.shields, equals(1));

    // 2. Update character & username
    await userRepo.updateCharacter(localUid, 'char_3');
    await userRepo.claimUsername(localUid, 'botanik_deniz');
    final updatedUser = await userRepo.getUser(localUid);
    expect(updatedUser!.characterId, equals('char_3'));
    expect(updatedUser.username, equals('botanik_deniz'));

    // 3. Add and mark habit
    final habitId = await habitRepo.addHabit(
      localUid,
      Habit(
        id: '',
        title: 'Günde 2 Litre Su',
        type: HabitType.build,
        icon: '💧',
        color: 0xFF2D6A4F,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );

    expect(habitId, isNotEmpty);
    final habits = await habitRepo.fetchActiveHabits(localUid);
    expect(habits.length, equals(1));
    expect(habits.first.title, equals('Günde 2 Litre Su'));

    // 4. Mark today
    await habitRepo.markToday(localUid, habitId);
    final todayLog = await habitRepo.watchTodayLog(localUid, habitId).first;
    expect(todayLog, isNotNull);
    expect(todayLog!.status, equals('done'));
  });

  test('Anonymous guest login works offline and unregistered email shows guidance', () async {
    final authRepo = AuthRepository();

    // 1. Unregistered user gives clear guidance
    expect(
      () => authRepo.signInWithEmail('nonexistent@example.com', '123456'),
      throwsA(isA<String>().having((msg) => msg, 'message', contains('Kayıtlı hesap bulunamadı'))),
    );

    // 2. Anonymous guest login creates guest session immediately
    final guestResult = await authRepo.signInAnonymously();
    expect(guestResult.uid, startsWith('guest_'));
    expect(authRepo.currentUid, equals(guestResult.uid));
    expect(AuthRepository.isLocalUid(guestResult.uid), isTrue);

    await authRepo.signOut();
    expect(authRepo.currentUid, isNull);
  });
}

