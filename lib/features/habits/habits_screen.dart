import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/habit.dart';
import '../../domain/habit_stats.dart';
import '../auth/providers.dart';
import '../home/providers.dart';
import '../home/widgets/habit_card.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  int _selectedFilter = 0; // 0: Tümü, 1: Kazanım, 2: Bırakma, 3: Arşivlenenler

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final archivedAsync = ref.watch(archivedHabitsProvider);
    final overallStats = ref.watch(overallStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final habits = habitsAsync.value ?? [];
    final archivedHabits = archivedAsync.value ?? [];

    final buildHabits = habits.where((h) => h.type != HabitType.quit).toList();
    final quitHabits = habits.where((h) => h.type == HabitType.quit).toList();

    final level = levelFor(totalXp(overallStats.totalCompletedDays * 10));

    return Scaffold(
      appBar: BloomAppBar(
        subtitle: 'Tüm Alışkanlıklar',
        levelTitle: 'Seviye ${level.level} ${level.title}',
        streakDays: overallStats.longestStreak,
        onAvatarTap: () => context.go('/profile'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          children: [
            // Top action & count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SectionHeader(
                  title: _selectedFilter == 3 ? 'Arşivlenen Tohumlar' : 'Bahçe Ritüelleri',
                  trailingText: _selectedFilter == 3
                      ? '${archivedHabits.length} Arşiv'
                      : '${habits.length} Aktif',
                ),
                StatusChip(
                  text: '+ Yeni Tohum',
                  tone: ChipTone.primary,
                  onTap: () => context.push('/new-habit'),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(0, 'Tümü (${habits.length})'),
                  SizedBox(width: 8.w),
                  _buildFilterChip(1, 'Kazanım 🌱 (${buildHabits.length})'),
                  SizedBox(width: 8.w),
                  _buildFilterChip(2, 'Bırakma 🚭 (${quitHabits.length})'),
                  SizedBox(width: 8.w),
                  _buildFilterChip(3, 'Arşiv 🗄 (${archivedHabits.length})'),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Content according to filter
            if (_selectedFilter == 3)
              _buildArchivedSection(context, archivedAsync, isDark)
            else
              habitsAsync.when(
                data: (allActiveHabits) {
                  final filteredList = switch (_selectedFilter) {
                    1 => buildHabits,
                    2 => quitHabits,
                    _ => allActiveHabits,
                  };

                  if (filteredList.isEmpty) {
                    return _buildEmptyState(
                      icon: _selectedFilter == 2 ? '🚭' : '🌱',
                      title: _selectedFilter == 2
                          ? 'Bırakılacak Kötü Alışkanlık Yok'
                          : (_selectedFilter == 1
                              ? 'Kazanılacak Pozitif Alışkanlık Yok'
                              : 'Henüz Takip Edilen Alışkanlık Yok'),
                      sub: 'Geliştirmek veya bırakmak istediğin tohumları bahçene ekle.',
                    );
                  }

                  return Column(
                    children: filteredList.map((h) {
                      final todayLog = ref.watch(todayLogProvider(h.id)).value;
                      final logs = ref.watch(habitLogsProvider(h.id)).value ?? {};
                      return HabitCardItem(
                        habit: h,
                        todayLog: todayLog,
                        logs: logs,
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(child: Text('Hata: $e')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.neutral,
          ),
        ),
      ),
    );
  }

  Widget _buildArchivedSection(
    BuildContext context,
    AsyncValue<List<Habit>> archivedAsync,
    bool isDark,
  ) {
    return archivedAsync.when(
      data: (archived) {
        if (archived.isEmpty) {
          return _buildEmptyState(
            icon: '🗄️',
            title: 'Arşivlenmiş Tohum Yok',
            sub: 'Arşivlediğin veya sildiğin alışkanlıkların burada saklanır ve istediğinde geri yükleyebilirsin.',
          );
        }

        return Column(
          children: archived.map((habit) {
            final dateStr = DateFormat('d MMM yyyy', 'tr_TR').format(habit.createdAt);
            final habitColor = Color(habit.color);

            return BloomCard(
              margin: EdgeInsets.only(bottom: 12.h),
              color: isDark ? AppColors.darkSurfaceMuted : const Color(0xFFFBF8F5),
              borderColor: isDark ? AppColors.darkOutline : AppColors.outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44.r,
                        height: 44.r,
                        decoration: BoxDecoration(
                          color: habitColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(habit.icon, style: TextStyle(fontSize: 22.sp)),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    habit.title,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                const StatusChip(
                                  text: 'Arşivde',
                                  tone: ChipTone.neutral,
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Oluşturulma: $dateStr • ${habit.type == HabitType.quit ? "Bırakma Rotası" : "Kazanım"}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.neutralVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinePillButton(
                        text: 'Bahçeye Geri Yükle ↺',
                        tone: AppColors.primary,
                        onPressed: () async {
                          final uid = ref.read(uidProvider);
                          if (uid != null) {
                            await ref.read(habitRepositoryProvider).restoreHabit(uid, habit.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"${habit.title}" bahçene geri yüklendi! 🌱'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(child: Text('Hata: $e')),
    );
  }

  Widget _buildEmptyState({
    required String icon,
    required String title,
    required String sub,
  }) {
    return BloomCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
      child: Column(
        children: [
          Text(icon, style: TextStyle(fontSize: 44.sp)),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.neutral,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.neutralVariant,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          PrimaryPillButton(
            text: 'Yeni Tohum Ek 🌱',
            onPressed: () => context.push('/new-habit'),
          ),
        ],
      ),
    );
  }
}
