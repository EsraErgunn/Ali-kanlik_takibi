import 'package:bloom_habit/data/models/habit.dart';
import 'package:bloom_habit/data/models/support_message.dart';
import 'package:bloom_habit/data/sources/support_message_source.dart';
import 'package:bloom_habit/features/relapse/relapse_support_sheet.dart';
import 'package:bloom_habit/services/relapse_support_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSourceForWidgetTest implements SupportMessageSource {
  FakeSourceForWidgetTest({required this.message});
  final SupportMessage message;

  @override
  Future<SupportMessage?> generateMessage({
    required String habitTitle,
    required int cleanDaysBeforeRelapse,
    required int totalCleanDays,
    required int relapsesThisMonth,
    required String timeOfDay,
  }) async {
    return message;
  }
}

void main() {
  Widget createTestWidget({
    required Habit habit,
    required int streakBeforeRelapse,
    required SupportMessage message,
  }) {
    return ProviderScope(
      overrides: [
        supportMessageSourceProvider.overrideWithValue(
          FakeSourceForWidgetTest(message: message),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: RelapseSupportSheet(
              habit: habit,
              streakBeforeRelapse: streakBeforeRelapse,
            ),
          ),
        ),
      ),
    );
  }

  group('RelapseSupportSheet Widget Tests', () {
    testWidgets('shows message, nextStep, and streak chip for non-alcohol habit', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final habit = Habit(
        id: 'habit_smoking',
        title: 'Sigarayı Bırak',
        type: HabitType.quit,
        category: 'smoking',
        icon: '🚭',
        color: 0xFFF07152,
        startDate: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 10, 1),
      );

      const testMessage = SupportMessage(
        message: 'Düştüğün yer yeniden başlayacağın yerdir. Yolculuğun devam ediyor.',
        nextStep: 'Hemen bir bardak soğuk su iç ve 5 derin nefes al.',
      );

      await tester.pumpWidget(
        createTestWidget(
          habit: habit,
          streakBeforeRelapse: 8,
          message: testMessage,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Header and domain streak
      expect(find.text('Bu bir son değil'), findsOneWidget);
      expect(find.text('8 gün temiz kaldın'), findsOneWidget);

      // AI message and next step
      expect(find.text(testMessage.message), findsOneWidget);
      expect(find.text('Şimdi dene: ${testMessage.nextStep}'), findsOneWidget);

      // Since category is smoking, alcohol advice line should NOT be visible
      expect(
        find.text('Bırakırken zorlanıyorsan bir sağlık profesyoneline danışmak iyi gelir.'),
        findsNothing,
      );

      // Button
      expect(find.text('Devam ediyorum'), findsOneWidget);
    });

    testWidgets('shows fixed advice line when category is alcohol', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final habit = Habit(
        id: 'habit_alcohol',
        title: 'Alkolü Bırak',
        type: HabitType.quit,
        category: 'alcohol',
        icon: '🍷',
        color: 0xFFF07152,
        startDate: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 10, 1),
      );

      const testMessage = SupportMessage(
        message: 'Bugüne kadar kazandığın her an seninle. Kendine nazik davran.',
        nextStep: 'Yürüyüşe çık ve sevdiğin bir müziği dinle.',
      );

      await tester.pumpWidget(
        createTestWidget(
          habit: habit,
          streakBeforeRelapse: 14,
          message: testMessage,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('14 gün temiz kaldın'), findsOneWidget);
      expect(find.text(testMessage.message), findsOneWidget);

      // When category == alcohol, fixed line MUST be visible
      expect(
        find.text('Bırakırken zorlanıyorsan bir sağlık profesyoneline danışmak iyi gelir.'),
        findsOneWidget,
      );
    });
  });
}
