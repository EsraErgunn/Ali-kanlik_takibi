import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BloomAppBar(
        subtitle: 'Profil & Bahçe Kimliği',
        levelTitle: 'Seviye 1 Tohum',
        streakDays: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          children: [
            // 1. Avatar & Başlık
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96.r,
                    height: 96.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryContainer,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text('🧑‍🌾', style: TextStyle(fontSize: 48.sp)),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '@bahcivan',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.verified_rounded,
                        size: 18.r,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  const StatusChip(
                    text: '🌱 Seviye 1 • Tohum',
                    tone: ChipTone.primary,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // 2. 2x2 StatTile
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 10.w,
              childAspectRatio: 1.25,
              children: const [
                StatTile(
                  label: 'BAHÇE YAŞI',
                  value: '1 Gün',
                  sub: 'Toprak yeşeriyor',
                  icon: Icon(Icons.yard_outlined, size: 16, color: AppColors.primary),
                ),
                StatTile(
                  label: 'GENEL BAŞARI',
                  value: '%0',
                  sub: 'Yeni başlangıç',
                  icon: Icon(Icons.trending_up, size: 16, color: AppColors.primary),
                ),
                StatTile(
                  label: 'EN UZUN ZİNCİR',
                  value: '0 Gün',
                  sub: 'Ateş bekliyor',
                  icon: Icon(Icons.local_fire_department, size: 16, color: AppColors.secondary),
                  valueColor: AppColors.secondary,
                ),
                StatTile(
                  label: 'DONDURMA JOKERİ',
                  value: '1 Hazır',
                  sub: 'Zinciri korur',
                  icon: Icon(Icons.shield_rounded, size: 16, color: AppColors.tertiary),
                  valueColor: AppColors.tertiary,
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // 3. Çiçek Koleksiyonum
            const SectionHeader(
              title: 'Çiçek Koleksiyonum',
              trailingText: '0/4 Nadir',
            ),
            SizedBox(height: 8.h),
            BloomCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('🌸', style: TextStyle(fontSize: 24.sp)),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aralık Çiçeği • Büyüyor 🌱',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            const ProgressPill(value: 0.05),
                            SizedBox(height: 4.h),
                            Text(
                              'Tamamlanmaya 29 gün kaldı · %3',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // 4. Kilometre Taşı Rozetleri
            const SectionHeader(
              title: 'Kilometre Taşı Rozetleri',
              trailingText: '1/5 Açıldı',
            ),
            SizedBox(height: 8.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 10.w,
              childAspectRatio: 1.3,
              children: [
                _buildBadgeCard(
                  title: 'İlk Tohum',
                  desc: 'İlk alışkanlık ekle',
                  isUnlocked: true,
                  icon: '🌱',
                  isDark: isDark,
                ),
                _buildBadgeCard(
                  title: '7 Günlük Alev',
                  desc: '7 gün ardışık zincir',
                  isUnlocked: false,
                  icon: '🔥',
                  isDark: isDark,
                ),
                _buildBadgeCard(
                  title: 'Kalkan Ustası',
                  desc: 'İlk koruma jokeri',
                  isUnlocked: false,
                  icon: '🛡',
                  isDark: isDark,
                ),
                _buildBadgeCard(
                  title: '21 Gün Döngüsü',
                  desc: '21 günlük irade',
                  isUnlocked: false,
                  icon: '⚡',
                  isDark: isDark,
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // 5. Ayarlar Listesi
            const SectionHeader(title: 'Uygulama & Güvenlik'),
            SizedBox(height: 8.h),
            BloomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_pin_outlined, color: AppColors.primary),
                    title: const Text('Kullanıcı Adı Değiştir'),
                    subtitle: const Text('@bahcivan (Benzersiz kimlik)'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkOutline : AppColors.outline),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                    title: const Text('Bildirim Tercihleri'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkOutline : AppColors.outline),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                    title: const Text('Karanlık Mod'),
                    value: isDark,
                    onChanged: (val) {
                      // TODO(theme): Theme mode toggle
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // 6. Çıkış / Silme Butonları
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.logout_rounded, color: AppColors.neutralVariant),
                label: const Text(
                  'Çıkış Yap',
                  style: TextStyle(color: AppColors.neutralVariant, fontWeight: FontWeight.w600),
                ),
                onPressed: () => context.go('/login'),
              ),
            ),
            SizedBox(height: 8.h),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.delete_forever_outlined, color: AppColors.secondary),
                label: const Text(
                  'Hesabı ve Tüm Bahçe Verilerini Sil',
                  style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  // TODO(auth): Delete account confirmation
                },
              ),
            ),
            Center(
              child: Text(
                'Bu işlem geri alınamaz. Google Play gereksinimlerine uygundur.',
                style: TextStyle(fontSize: 10.sp, color: AppColors.neutralVariant),
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard({
    required String title,
    required String desc,
    required bool isUnlocked,
    required String icon,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isDark ? AppColors.darkSurface : AppColors.surface)
            : (isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isUnlocked
              ? AppColors.primary.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkOutline : AppColors.outline),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: TextStyle(fontSize: 22.sp)),
              StatusChip(
                text: isUnlocked ? 'Kazanıldı' : 'Kilitli',
                tone: isUnlocked ? ChipTone.primary : ChipTone.neutral,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: isUnlocked ? (isDark ? AppColors.darkNeutral : AppColors.neutral) : AppColors.neutralVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            desc,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.neutralVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
