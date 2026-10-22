import 'package:bloom_habit/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: BloomHabitApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BloomHabit'), findsWidgets);
    expect(find.text('Bahçem'), findsWidgets);
  });
}
