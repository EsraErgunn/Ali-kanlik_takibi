import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  int _selectedCharacterIndex = 0;

  final List<Map<String, String>> _characters = [
    {'id': 'char_1', 'emoji': '🧑‍🌾', 'name': 'Neşeli Bahçıvan', 'trait': 'Toprak Ustası'},
    {'id': 'char_2', 'emoji': '👩‍🌾', 'name': 'Bilge Çiftçi', 'trait': 'Sabır & İrade'},
    {'id': 'char_3', 'emoji': '🧙‍♂️', 'name': 'Orman Büyücüsü', 'trait': 'Doğa Enerjisi'},
    {'id': 'char_4', 'emoji': '🧝‍♀️', 'name': 'Su Perisi', 'trait': 'Süreklilik'},
    {'id': 'char_5', 'emoji': '🦊', 'name': 'Kızıl Tilki', 'trait': 'Çevik Alışkanlık'},
    {'id': 'char_6', 'emoji': '🦉', 'name': 'Gece Baykuşu', 'trait': 'Odak & Disiplin'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    const StatusChip(
                      text: '🌱 KARAKTERİNİ BELİRLE',
                      tone: ChipTone.primary,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Bahçıvanını Seç',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Bahçeni büyütecek ruhunu ve avatarını belirle.',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.neutralVariant),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // 2-column grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _characters.length,
                  itemBuilder: (context, index) {
                    final char = _characters[index];
                    final isSel = index == _selectedCharacterIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCharacterIndex = index),
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: isSel
                              ? (isDark ? const Color(0xFF133B27) : AppColors.primaryContainer.withValues(alpha: 0.5))
                              : (isDark ? AppColors.darkSurfaceMuted : AppColors.surface),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isSel ? AppColors.primary : (isDark ? AppColors.darkOutline : AppColors.outline),
                            width: isSel ? 2 : 1,
                          ),
                          boxShadow: isSel ? AppColors.cardShadow : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(char['emoji']!, style: TextStyle(fontSize: 42.sp)),
                            SizedBox(height: 6.h),
                            Text(
                              char['name']!,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              char['trait']!,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              PrimaryPillButton(
                text: 'Devam Et 🌱',
                onPressed: () {
                  context.push('/onboarding/username');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
