import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_key.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/daily_motivation.dart';
import '../../auth/providers.dart';
import '../providers.dart';

class MotivationCardsSection extends ConsumerWidget {
  const MotivationCardsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motivationAsync = ref.watch(todayMotivationProvider);
    final uid = ref.watch(uidProvider);
    final todayKey = DateKey.today();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Günün AI Kehaneti',
          icon: const Text('✨'),
          trailing: motivationAsync.when(
            data: (data) {
              final isSelected = data?.isSelected ?? false;
              return StatusChip(
                text: isSelected ? '✓ Seçildi' : '1 Seçim Hakkı',
                tone: isSelected ? ChipTone.primary : ChipTone.tertiary,
              );
            },
            loading: () => const StatusChip(text: 'Yükleniyor...', tone: ChipTone.neutral),
            error: (err, stack) => const StatusChip(text: 'Hazır', tone: ChipTone.neutral),
          ),
        ),
        SizedBox(height: 10.h),
        motivationAsync.when(
          data: (data) {
            final motivation = data ??
                DailyMotivation(
                  date: todayKey,
                  options: ref.watch(aiServiceProvider).getFallbackOptions(dayKey: todayKey),
                  selectedIndex: null,
                );

            return _MotivationCardsGrid(
              motivation: motivation,
              onSelect: (index) async {
                if (uid == null || motivation.isSelected) return;
                HapticFeedback.lightImpact();
                await ref.read(motivationRepositoryProvider).selectOption(
                      uid: uid,
                      dateKey: todayKey,
                      optionIndex: index,
                    );
              },
            );
          },
          loading: () => SizedBox(
            height: 140.h,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, stack) {
            final fallback = DailyMotivation(
              date: todayKey,
              options: ref.watch(aiServiceProvider).getFallbackOptions(dayKey: todayKey),
              selectedIndex: null,
            );
            return _MotivationCardsGrid(
              motivation: fallback,
              onSelect: (_) {},
            );
          },
        ),
      ],
    );
  }
}

class _MotivationCardsGrid extends StatelessWidget {
  const _MotivationCardsGrid({
    required this.motivation,
    required this.onSelect,
  });

  final DailyMotivation motivation;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = motivation.selectedIndex;
    final isSelected = selectedIndex != null;
    final options = motivation.options;

    return Column(
      children: [
        SizedBox(
          height: 145.h,
          child: Row(
            children: List.generate(3, (index) {
              final isThisSelected = selectedIndex == index;
              final isLocked = isSelected && !isThisSelected;
              final option = options.length > index
                  ? options[index]
                  : MotivationOption(
                      title: '🌱 Kart ${index + 1}',
                      text: 'Sabırla yeşeren tohumlar ormana dönüşür.',
                      tag: '#Sabır',
                    );

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: _FlipCardItem(
                    index: index,
                    option: option,
                    isFlipped: isThisSelected,
                    isLocked: isLocked,
                    onTap: (!isSelected) ? () => onSelect(index) : null,
                  ),
                ),
              );
            }),
          ),
        ),
        if (isSelected && selectedIndex >= 0 && selectedIndex < options.length) ...[
          SizedBox(height: 10.h),
          _SelectedCardDetail(option: options[selectedIndex]),
        ],
      ],
    );
  }
}

class _FlipCardItem extends StatelessWidget {
  const _FlipCardItem({
    required this.index,
    required this.option,
    required this.isFlipped,
    required this.isLocked,
    this.onTap,
  });

  final int index;
  final MotivationOption option;
  final bool isFlipped;
  final bool isLocked;
  final VoidCallback? onTap;

  static const List<String> _cardSymbols = ['🌱', '☀️', '🌧️'];
  static const List<String> _cardLabels = ['Kök', 'Işık', 'Yağmur'];

  @override
  Widget build(BuildContext context) {
    final symbol = _cardSymbols[index % _cardSymbols.length];
    final label = _cardLabels[index % _cardLabels.length];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isFlipped ? math.pi : 0.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutBack,
      builder: (context, val, child) {
        final isBack = val > math.pi / 2;

        return ExcludeSemantics(
          excluding: isLocked,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(val),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildBackFace(context),
                  )
                : _buildFrontFace(context, symbol, label),
          ),
        );
      },
    );
  }

  Widget _buildFrontFace(BuildContext context, String symbol, String label) {
    return Opacity(
      opacity: isLocked ? 0.35 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: BloomCard(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
            color: isLocked ? AppColors.surfaceMuted : const Color(0xFFFBF8F3),
            borderColor: isLocked
                ? AppColors.neutralVariant.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#0${index + 1}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutralVariant,
                      ),
                    ),
                    if (isLocked)
                      Icon(Icons.lock_outline, size: 14.sp, color: AppColors.neutralVariant)
                    else
                      Text('✨', style: TextStyle(fontSize: 10.sp)),
                  ],
                ),
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLocked
                        ? AppColors.neutralVariant.withValues(alpha: 0.1)
                        : AppColors.primaryContainer.withValues(alpha: 0.6),
                    border: Border.all(
                      color: isLocked
                          ? Colors.transparent
                          : AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isLocked ? '🔒' : symbol,
                      style: TextStyle(fontSize: 20.sp),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isLocked ? AppColors.neutralVariant : AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isLocked ? 'Kilitli' : 'Dokun Aç',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.neutralVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackFace(BuildContext context) {
    return BloomCard(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      color: AppColors.primaryContainer.withValues(alpha: 0.4),
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  option.title,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.check_circle, size: 12.sp, color: AppColors.primary),
            ],
          ),
          Text(
            '“${option.text}”',
            style: TextStyle(
              fontSize: 10.sp,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral,
              height: 1.25,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            option.tag,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SelectedCardDetail extends StatelessWidget {
  const _SelectedCardDetail({required this.option});

  final MotivationOption option;

  @override
  Widget build(BuildContext context) {
    return BloomCard(
      color: AppColors.primaryContainer.withValues(alpha: 0.35),
      borderColor: AppColors.primary.withValues(alpha: 0.4),
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EyebrowLabel(option.title.toUpperCase(), color: AppColors.primary),
              StatusChip(
                text: option.tag,
                tone: ChipTone.primary,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '“${option.text}”',
            style: TextStyle(
              fontSize: 13.sp,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
