import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/elapsed_ticker.dart';
import '../../core/widgets/info_box.dart';
import '../../core/widgets/pill_buttons.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/habit.dart';
import '../../data/models/support_message.dart';
import '../../services/relapse_support_service.dart';
import '../auth/providers.dart';
import '../home/providers.dart';

Future<void> showRelapseSupportSheet({
  required BuildContext context,
  required Habit habit,
  required int streakBeforeRelapse,
  SupportMessage? cachedMessage,
}) async {
  HapticFeedback.lightImpact();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => RelapseSupportSheet(
      habit: habit,
      streakBeforeRelapse: streakBeforeRelapse,
      cachedMessage: cachedMessage,
    ),
  );
}

class RelapseSupportSheet extends ConsumerStatefulWidget {
  const RelapseSupportSheet({
    super.key,
    required this.habit,
    required this.streakBeforeRelapse,
    this.cachedMessage,
  });

  final Habit habit;
  final int streakBeforeRelapse;
  final SupportMessage? cachedMessage;

  @override
  ConsumerState<RelapseSupportSheet> createState() => _RelapseSupportSheetState();
}

class _RelapseSupportSheetState extends ConsumerState<RelapseSupportSheet> {
  SupportMessage? _message;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.cachedMessage != null) {
      _message = widget.cachedMessage;
      _isLoading = false;
    } else {
      _fetchMessage();
    }
  }

  Future<void> _fetchMessage() async {
    final uid = ref.read(uidProvider) ?? 'local_user';
    final logs = ref.read(habitLogsProvider(widget.habit.id)).value ?? {};
    final todayLog = ref.read(todayLogProvider(widget.habit.id)).value;

    try {
      final msg = await ref.read(relapseSupportServiceProvider).getSupportMessage(
            uid: uid,
            habit: widget.habit,
            logs: logs,
            todayLog: todayLog,
            now: DateTime.now(),
          );
      if (mounted) {
        setState(() {
          _message = msg;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Grabber handle
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkOutline : AppColors.outline).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

            // Top Header: 🌱 + "Bu bir son değil"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🌱', style: TextStyle(fontSize: 22.sp)),
                SizedBox(width: 8.w),
                Text(
                  'Bu bir son değil',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // StatusChip: "{önceki temiz gün} gün temiz kaldın" (Domain sayısından)
            Center(
              child: StatusChip(
                text: '${widget.streakBeforeRelapse} gün temiz kaldın',
                tone: ChipTone.secondary,
              ),
            ),
            SizedBox(height: 16.h),

            // Body: Loading vs Message content
            if (_isLoading) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 28.h),
                child: Column(
                  children: [
                    SizedBox(
                      width: 28.r,
                      height: 28.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Yolculuğun için destek hazırlanıyor...',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_message != null) ...[
              // message: bodyMedium, centered
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  _message!.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                    height: 1.45,
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // InfoBox(primary): "Şimdi dene: {nextStep}"
              InfoBox(
                text: 'Şimdi dene: ${_message!.nextStep}',
                tone: ChipTone.primary,
              ),

              // Fixed line for alcohol
              if (widget.habit.category == 'alcohol') ...[
                SizedBox(height: 10.h),
                Text(
                  'Bırakırken zorlanıyorsan bir sağlık profesyoneline danışmak iyi gelir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                  ),
                ),
              ],
              SizedBox(height: 16.h),

              // Altta yeni sayaç: "Yeni sayacın başladı" + ElapsedTicker (0'dan)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Yeni sayacın başladı:',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    ElapsedTicker(
                      since: widget.habit.lastRelapseAt ?? DateTime.now(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),

              // PrimaryPillButton: "Devam ediyorum"
              PrimaryPillButton(
                text: 'Devam ediyorum',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}
