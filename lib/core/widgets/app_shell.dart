import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers.dart';
import '../../features/home/providers.dart';
import '../theme/app_colors.dart';
import 'confetti_overlay.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShields();
    });
  }

  Future<void> _checkShields() async {
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    try {
      final savedCount = await ref.read(userRepositoryProvider).checkAndApplyShields(
            uid: uid,
            today: DateTime.now(),
            habitRepo: ref.read(habitRepositoryProvider),
          );
      if (savedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🛡 $savedCount alışkanlığının zinciri kalkanınla otomatik korundu!'),
            backgroundColor: AppColors.tertiary,
          ),
        );
      }
    } catch (_) {}
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == 2) {
      // Center '+' FAB opens full page New Habit
      context.push('/new-habit');
      return;
    }
    // Adjust index because index 2 is FAB
    final targetBranch = index > 2 ? index - 1 : index;
    widget.navigationShell.goBranch(
      targetBranch,
      initialLocation: targetBranch == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = widget.navigationShell.currentIndex;
    // Map branch index back to 5-slot navigation index
    final selectedNavIndex = currentIndex >= 2 ? currentIndex + 1 : currentIndex;

    return Scaffold(
      body: ConfettiOverlay(
        child: widget.navigationShell,
      ),
      bottomNavigationBar: Container(

        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkOutline : AppColors.outline,
              width: 0.8,
            ),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  isSelected: selectedNavIndex == 0,
                  icon: Icons.yard_outlined,
                  selectedIcon: Icons.yard_rounded,
                  label: 'Bahçem',
                  isDark: isDark,
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  isSelected: selectedNavIndex == 1,
                  icon: Icons.check_circle_outline_rounded,
                  selectedIcon: Icons.check_circle_rounded,
                  label: 'Alışkanlıklar',
                  isDark: isDark,
                ),
                _buildCenterFab(context, isDark),
                _buildNavItem(
                  context,
                  index: 3,
                  isSelected: selectedNavIndex == 3,
                  icon: Icons.insights_outlined,
                  selectedIcon: Icons.insights_rounded,
                  label: 'Analiz',
                  isDark: isDark,
                ),
                _buildNavItem(
                  context,
                  index: 4,
                  isSelected: selectedNavIndex == 4,
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: 'Profil',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required bool isSelected,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isDark,
  }) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index, context),
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 24.r,
              color: isSelected ? activeColor : inactiveColor,
            ),
            SizedBox(height: 3.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFab(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _onItemTapped(2, context),
      child: Container(
        width: 52.r,
        height: 52.r,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          size: 30.r,
          color: isDark ? AppColors.darkBackground : Colors.white,
        ),
      ),
    );
  }
}
