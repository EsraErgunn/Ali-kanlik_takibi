import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/habit.dart';
import '../../domain/habit_stats.dart';
import '../../domain/plant_stage.dart';
import '../auth/providers.dart';
import 'providers.dart';
import 'widgets/habit_card.dart';
import 'widgets/motivation_cards_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedFilter = 'all'; // 'all', 'build', 'quit'

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(appUserProvider);
    final habitsAsync = ref.watch(habitsProvider);

    final appUser = userAsync.value;
    final gardenStart = appUser?.gardenStartDate ?? DateTime.now();
    final plantInfo = plantFor(gardenStart, DateTime.now());
    final level = levelFor(totalXp(0)); // Updated dynamically from logs

    return Scaffold(
      appBar: BloomAppBar(
        subtitle: 'Bahçem',
        levelTitle: 'Seviye ${level.level} ${level.title}',
        streakDays: 0,
        onAvatarTap: () => context.go('/profile'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          children: [
            // 1. Bitki Kartı
            _buildPlantCard(context, plantInfo),
            SizedBox(height: 16.h),

            // 2. Günün AI Kehaneti
            const MotivationCardsSection(),
            SizedBox(height: 20.h),

            // 3. Bugünkü Görevler ve Filtreler
            _buildTasksSection(context, habitsAsync),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantCard(
    BuildContext context,
    ({PlantStage stage, int completedCycles, int dayInCycle, double cycleProgress}) plantInfo,
  ) {
    return BloomCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF2F8F4),
          Color(0xFFFAF7F2),
        ],
      ),
      borderColor: AppColors.primary.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: StatusChip(
                  text: '${plantInfo.stage.emoji} ${plantInfo.stage.title}',
                  tone: ChipTone.primary,
                ),
              ),
              const SizedBox(width: 6),
              const StatusChip(
                text: '🛡 Kalkan: 1/2 Hazır',
                tone: ChipTone.tertiary,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Center(
            child: Column(
              children: [
                StatusChip(
                  text: '📅 ${plantInfo.dayInCycle + 1}. Gün',
                  tone: ChipTone.tertiary,
                ),
                SizedBox(height: 12.h),
                // Plant display
                Container(
                  height: 130.h,
                  width: 130.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      plantInfo.stage.emoji,
                      style: TextStyle(fontSize: 58.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '🌿 ${plantInfo.stage.title}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '30. Günde Çiçek Açar (%${(plantInfo.cycleProgress * 100).toInt()})',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutralVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ProgressPill(value: plantInfo.cycleProgress),
          SizedBox(height: 12.h),
          const InfoBox(
            text: 'Bugün tüm alışkanlıklarını tamamlarsan ilk taç yaprağı açacak! Kaçırırsan solma uyarısı devreye girer.',
            tone: ChipTone.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(BuildContext context, AsyncValue<List<Habit>> habitsAsync) {
    return habitsAsync.when(
      data: (habits) {
        final filteredHabits = habits.where((h) {
          if (_selectedFilter == 'build') return h.type != HabitType.quit;
          if (_selectedFilter == 'quit') return h.type == HabitType.quit;
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Bugünkü Görevler',
              trailingText: '${habits.length} Tohum',
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                StatusChip(
                  text: 'Tümü (${habits.length})',
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                SizedBox(width: 8.w),
                StatusChip(
                  text: 'Kazanım 🌱',
                  isSelected: _selectedFilter == 'build',
                  onTap: () => setState(() => _selectedFilter = 'build'),
                ),
                SizedBox(width: 8.w),
                StatusChip(
                  text: 'Bırakma 🚭',
                  isSelected: _selectedFilter == 'quit',
                  onTap: () => setState(() => _selectedFilter = 'quit'),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (filteredHabits.isEmpty)
              BloomCard(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: Column(
                  children: [
                    Text('🪴', style: TextStyle(fontSize: 40.sp)),
                    SizedBox(height: 8.h),
                    Text(
                      'Bahçen Henüz Boş',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Yeni bir tohum ekerek zincirini başlat.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.neutralVariant,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    PrimaryPillButton(
                      text: 'Yeni Tohum Ek 🌱',
                      onPressed: () => context.push('/new-habit'),
                    ),
                  ],
                ),
              )
            else
              ...filteredHabits.map((h) {
                final todayLog = ref.watch(todayLogProvider(h.id)).value;
                final logs = ref.watch(habitLogsProvider(h.id)).value ?? {};
                return HabitCardItem(
                  habit: h,
                  todayLog: todayLog,
                  logs: logs,
                );
              }),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => BloomCard(
        child: Center(
          child: Text('Görevler yüklenemedi: $e'),
        ),
      ),
    );
  }
}
