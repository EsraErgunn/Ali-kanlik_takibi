import 'package:bloom_habit/core/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatusChip renders text and responds to tap', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatusChip(
                text: '🌱 Filiz Aşaması',
                tone: ChipTone.primary,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('🌱 Filiz Aşaması'), findsOneWidget);

    await tester.tap(find.byType(StatusChip));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
