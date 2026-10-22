import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedFilter = 'all'; // 'all', 'build', 'quit'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BloomAppBar(
        subtitle: 'Bahçem',
        levelTitle: 'Seviye 1 Tohum',
        streakDays: 0,
        onAvatarTap: () => context.go('/profile'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          children: [
            // 1. Bitki Kartı
            _buildPlantCard(context),
            SizedBox(height: 16.h),

            // 2. Günün AI Kehaneti
            _buildMotivationSection(context),
            SizedBox(height: 20.h),

            // 3. Bugünkü Görevler ve Filtreler
            _buildTasksSection(context),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantCard(BuildContext context) {
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
            children: const [
              Flexible(
                child: StatusChip(
                  text: '🌱 İlk Tohum · Seviye 1',
                  tone: ChipTone.primary,
                ),
              ),
              SizedBox(width: 6),
              StatusChip(
                text: '🛡 Kalkan: 1/2 Hazır',
                tone: ChipTone.tertiary,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Center(
            child: Column(
              children: [
                const StatusChip(
                  text: '📅 1. Gün',
                  tone: ChipTone.tertiary,
                ),
                SizedBox(height: 12.h),
                // Placeholder plant container
                Container(
                  height: 140.h,
                  width: 140.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      '🌱',
                      style: TextStyle(fontSize: 64.sp),
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
                  '🌿 Filiz Aşaması',
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
                '30. Günde Çiçek Açar (%3)',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutralVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          const ProgressPill(value: 0.03),
          SizedBox(height: 12.h),
          const InfoBox(
            text: 'Bugün tüm alışkanlıklarını tamamlarsan ilk taç yaprağı açacak! Kaçırırsan solma uyarısı devreye girer.',
            tone: ChipTone.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Günün AI Kehaneti',
          icon: Text('✨'),
          trailing: StatusChip(
            text: '1/1 Hak',
            tone: ChipTone.neutral,
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 130.h,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: BloomCard(
                  color: AppColors.primaryContainer.withValues(alpha: 0.35),
                  padding: EdgeInsets.all(12.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const EyebrowLabel('🌱 DERİN KÖKLER KARTI', color: AppColors.primary),
                      Text(
                        '“En güçlü fırtınalara sessizce toprağa tutunan tohumlar dayanır.”',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#NefesVeDirenç',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Icon(
                            Icons.bookmark_added_rounded,
                            size: 16.r,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: const LockedCard(
                  title: 'Yarın Açılır',
                  subtitle: 'Güneş Işığı Kartı',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Center(
          child: Text(
            'Günde sadece 1 kehanet seçme hakkın var. Seçtiğin kart bugünkü enerjini belirler.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.neutralVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Bugünkü Görevler',
          trailingText: '0 Tamamlandı',
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            StatusChip(
              text: 'Tümü',
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

        // Empty state placeholder for initial run
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
        ),
      ],
    );
  }
}
