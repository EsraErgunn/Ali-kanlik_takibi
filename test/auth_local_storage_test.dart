import 'package:bloom_habit/data/models/habit.dart';
import 'package:bloom_habit/data/models/daily_motivation.dart';
import 'package:bloom_habit/data/repositories/habit_repository.dart';
import 'package:bloom_habit/data/repositories/motivation_repository.dart';
import 'package:bloom_habit/data/repositories/user_repository.dart';
import 'package:bloom_habit/data/services/hive_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await HiveService.instance.init();
    await HiveService.instance.clearAll();
  });

  test('HiveService profile state and UserRepository onboarding operate seamlessly', () async {
    final userRepo = UserRepository();

    // 1. Initial state: hasProfile is false
    expect(HiveService.instance.hasProfile, isFalse);
    expect(await userRepo.getUser(), isNull);

    // 2. Initial user creation
    await userRepo.createInitialUser(uid: 'current', characterId: 'char_2');
    final user = await userRepo.getUser();
    expect(user, isNotNull);
    expect(user!.characterId, equals('char_2'));
    expect(user.shields, equals(1));

    // 3. Update character
    await userRepo.updateCharacter('current', 'char_3');
    final updatedChar = await userRepo.getUser();
    expect(updatedChar!.characterId, equals('char_3'));

    // 4. Username format validation (3-20 chars, [a-zA-Z0-9_.])
    expect(
      () => userRepo.claimUsername('current', 'ab'), // too short
      throwsA(isA<String>().having((msg) => msg, 'message', contains('3-20'))),
    );
    expect(
      () => userRepo.claimUsername('current', 'invalid name with space'),
      throwsA(isA<String>().having((msg) => msg, 'message', contains('yalnızca'))),
    );

    // 5. Valid username claim succeeds and activates profile
    await userRepo.claimUsername('current', 'deniz_bahce.01');
    final activeUser = await userRepo.getUser();
    expect(activeUser!.username, equals('deniz_bahce.01'));
    expect(activeUser.usernameLower, equals('deniz_bahce.01'));
    expect(HiveService.instance.hasProfile, isTrue);

    // 6. Reset garden / clearAll wipes everything
    await userRepo.deleteUserAccount('current');
    expect(HiveService.instance.hasProfile, isFalse);
    expect(await userRepo.getUser(), isNull);
  });

  test('HabitRepository operates with Hive boxes, key prefixes, and year logs', () async {
    final habitRepo = HabitRepository();

    // 1. Add habit
    final habitId = await habitRepo.addHabit(
      'current',
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
    final habits = await habitRepo.fetchActiveHabits('current');
    expect(habits.length, equals(1));
    expect(habits.first.title, equals('Günde 2 Litre Su'));

    // 2. Mark today
    await habitRepo.markToday('current', habitId);
    final todayLog = await habitRepo.watchTodayLog('current', habitId).first;
    expect(todayLog, isNotNull);
    expect(todayLog!.status, equals('done'));

    // 3. Filter year logs with "habitId|YYYY-" prefix
    final year = DateTime.now().year;
    final yearLogs = await habitRepo.fetchYearLogs('current', habitId, year);
    expect(yearLogs.isNotEmpty, isTrue);

    // 4. Soft delete / archive habit
    await habitRepo.deleteHabit('current', habitId);
    final activeAfterDelete = await habitRepo.fetchActiveHabits('current');
    expect(activeAfterDelete.isEmpty, isTrue);

    final archived = await habitRepo.watchArchivedHabits('current').first;
    expect(archived.length, equals(1));
    expect(archived.first.id, equals(habitId));

    // 5. Unmark today
    await habitRepo.unmarkToday('current', habitId);
    final todayLogAfterUnmark = await habitRepo.watchTodayLog('current', habitId).first;
    expect(todayLogAfterUnmark, isNull);
  });

  test('MotivationRepository stores and selects daily motivation in Hive', () async {
    final motivationRepo = MotivationRepository();
    final dateKey = '2026-10-23';

    // 1. Create today motivation
    final motivation = await motivationRepo.getOrCreateTodayMotivation(
      uid: 'current',
      dateKey: dateKey,
      optionGenerator: () async => [
        const MotivationOption(
          title: '🌱 Güçlü Kökler',
          text: 'Her gün küçük bir adım.',
          tag: '#Büyüme',
        ),
      ],
    );

    expect(motivation.date, equals(dateKey));
    expect(motivation.options.first.title, equals('🌱 Güçlü Kökler'));
    expect(motivation.isSelected, isFalse);

    // 2. Select option
    await motivationRepo.selectOption(
      uid: 'current',
      dateKey: dateKey,
      optionIndex: 0,
    );

    final selected = await motivationRepo.getTodayMotivation('current', dateKey);
    expect(selected, isNotNull);
    expect(selected!.isSelected, isTrue);
    expect(selected.selectedIndex, equals(0));
  });
}
