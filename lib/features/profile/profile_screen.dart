import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_key.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/bloom_card.dart';
import '../../core/widgets/pill_buttons.dart';
import '../../core/widgets/progress_pill.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/habit_stats.dart';
import '../../domain/plant_stage.dart';
import '../auth/providers.dart';
import '../home/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const List<({String id, String name, String emoji, Color color})> _characters = [
    (id: 'char_1', name: 'Filiz Perisi', emoji: '🌱', color: Color(0xFF1B6B48)),
    (id: 'char_2', name: 'Güneş Bahçıvanı', emoji: '☀️', color: Color(0xFFECA038)),
    (id: 'char_3', name: 'Yağmur Bekçisi', emoji: '🌧️', color: Color(0xFF3B82F6)),
    (id: 'char_4', name: 'Toprak Bilgesi', emoji: '🌿', color: Color(0xFF10B981)),
    (id: 'char_5', name: 'Çiçek Ruhu', emoji: '🌸', color: Color(0xFFEC4899)),
    (id: 'char_6', name: 'Orman Muhafızı', emoji: '🌲', color: Color(0xFF0F4A31)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(appUserProvider);
    final habitsAsync = ref.watch(habitsProvider);

    final user = userAsync.value;
    final habits = habitsAsync.value ?? [];

    final gardenStart = user?.gardenStartDate ?? DateTime.now();
    final plantInfo = plantFor(gardenStart, DateTime.now());
    final gardenAge = DateKey.daysBetween(
          DateKey.dateOnly(gardenStart),
          DateKey.dateOnly(DateTime.now()),
        ) +
        1;

    final char = _characters.firstWhere(
      (c) => c.id == (user?.characterId ?? 'char_1'),
      orElse: () => _characters.first,
    );

    // Compute stats
    final activeHabitsCount = habits.where((h) => !h.isDeleted).length;
    final level = levelFor(totalXp(activeHabitsCount * 10));

    return Scaffold(
      appBar: BloomAppBar(
        subtitle: 'Profil & Bahçe Kimliği',
        levelTitle: 'Seviye ${level.level} ${level.title}',
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
                  GestureDetector(
                    onTap: () => _showCharacterPicker(context, user?.uid, user?.characterId),
                    child: Stack(
                      children: [
                        Container(
                          width: 96.r,
                          height: 96.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: char.color.withValues(alpha: 0.15),
                            border: Border.all(
                              color: char.color,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(char.emoji, style: TextStyle(fontSize: 44.sp)),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 14.r,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.username.isNotEmpty == true ? '@${user!.username}' : '@bahcivan',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      IconButton(
                        icon: Icon(Icons.edit_note_rounded, size: 20.r, color: AppColors.primary),
                        onPressed: () => _showUsernameDialog(context, user?.uid, user?.username),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  StatusChip(
                    text: '🌱 Seviye ${level.level} • ${level.title}',
                    tone: ChipTone.primary,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // 2. 2x2 StatTile Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 10.w,
              childAspectRatio: 1.25,
              children: [
                StatTile(
                  label: 'BAHÇE YAŞI',
                  value: '$gardenAge Gün',
                  sub: 'Toprak yeşeriyor',
                  icon: const Icon(Icons.yard_outlined, size: 16, color: AppColors.primary),
                ),
                StatTile(
                  label: 'AKTİF TOHUM',
                  value: '$activeHabitsCount Adet',
                  sub: 'Yeşeren alışkanlık',
                  icon: const Icon(Icons.eco_rounded, size: 16, color: AppColors.primary),
                ),
                StatTile(
                  label: 'AÇAN ÇİÇEK',
                  value: '${plantInfo.completedCycles} Çiçek',
                  sub: '30 günlük döngü',
                  icon: const Icon(Icons.local_florist_rounded, size: 16, color: AppColors.secondary),
                  valueColor: AppColors.secondary,
                ),
                StatTile(
                  label: 'DONDURMA JOKERİ',
                  value: '${user?.shields ?? 1} Hazır',
                  sub: 'Zinciri korur',
                  icon: const Icon(Icons.shield_rounded, size: 16, color: AppColors.tertiary),
                  valueColor: AppColors.tertiary,
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // 3. Çiçek Koleksiyonum
            SectionHeader(
              title: 'Çiçek Koleksiyonum',
              trailingText: '${plantInfo.completedCycles} Çiçek Açtı 🌸',
            ),
            SizedBox(height: 8.h),
            InkWell(
              onTap: () => context.push('/garden'),
              borderRadius: BorderRadius.circular(16.r),
              child: BloomCard(
                child: Row(
                  children: [
                    Container(
                      width: 48.r,
                      height: 48.r,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          plantInfo.completedCycles > 0 ? '🌸' : plantInfo.stage.emoji,
                          style: TextStyle(fontSize: 24.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Aylık Çiçek Döngüsü',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 18),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          ProgressPill(value: plantInfo.cycleProgress),
                          SizedBox(height: 4.h),
                          Text(
                            '${30 - plantInfo.dayInCycle} gün sonra yeni çiçek açar (%${(plantInfo.cycleProgress * 100).toInt()})',
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
              ),
            ),
            SizedBox(height: 20.h),

            // 4. Kilometre Taşı Rozetleri
            const SectionHeader(
              title: 'Kilometre Taşı Rozetleri',
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
                  isUnlocked: habits.isNotEmpty,
                  icon: '🌱',
                  isDark: isDark,
                ),
                _buildBadgeCard(
                  title: '7 Günlük Alev',
                  desc: '7 günlük zincir yak',
                  isUnlocked: false,
                  icon: '🔥',
                  isDark: isDark,
                ),
                _buildBadgeCard(
                  title: 'Kalkan Ustası',
                  desc: 'Zincir koruma kalkanı',
                  isUnlocked: (user?.shields ?? 0) > 0,
                  icon: '🛡',
                  isDark: isDark,
                ),
                _buildBadgeCard(
                  title: '30 Gün Çiçeği',
                  desc: 'İlk çiçeğini açtır',
                  isUnlocked: plantInfo.completedCycles > 0,
                  icon: '🌸',
                  isDark: isDark,
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // 5. Ayarlar
            const SectionHeader(title: 'Uygulama & Güvenlik'),
            SizedBox(height: 8.h),
            BloomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_pin_outlined, color: AppColors.primary),
                    title: const Text('Kullanıcı Adı Düzenle'),
                    subtitle: Text(
                      user?.username.isNotEmpty == true ? '@${user!.username}' : '@bahcivan',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showUsernameDialog(context, user?.uid, user?.username),
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkOutline : AppColors.outline),
                  ListTile(
                    leading: const Icon(Icons.face_retouching_natural_rounded, color: AppColors.primary),
                    title: const Text('Bahçıvan Karakteri'),
                    subtitle: Text(char.name),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showCharacterPicker(context, user?.uid, user?.characterId),
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkOutline : AppColors.outline),
                  ListTile(
                    leading: const Icon(Icons.yard_rounded, color: AppColors.primary),
                    title: const Text('Çiçek Bahçemi Ziyaret Et'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/garden'),
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
                onPressed: () => _showLogoutDialog(context),
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
                onPressed: () => _showDeleteAccountDialog(context, user?.uid),
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

  void _showCharacterPicker(BuildContext context, String? uid, String? currentId) {
    if (uid == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionHeader(title: 'Bahçıvanını Seç', icon: Text('🧑‍🌾')),
              SizedBox(height: 16.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 0.85,
                ),
                itemCount: _characters.length,
                itemBuilder: (context, index) {
                  final c = _characters[index];
                  final isSelected = c.id == currentId;
                  return InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ref.read(userRepositoryProvider).updateCharacter(uid, c.id);
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryContainer : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.outline,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(c.emoji, style: TextStyle(fontSize: 32.sp)),
                          SizedBox(height: 6.h),
                          Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppColors.primaryDark : AppColors.neutral,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  void _showUsernameDialog(BuildContext context, String? uid, String? currentUsername) {
    if (uid == null) return;
    final controller = TextEditingController(text: currentUsername ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Kullanıcı Adı Değiştir'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                prefixText: '@',
                hintText: 'yeni_kullanici',
              ),
              validator: (val) {
                final text = val?.trim() ?? '';
                if (text.length < 3 || text.length > 20) {
                  return '3 ile 20 karakter arasında olmalıdır.';
                }
                final validRegex = RegExp(r'^[a-z0-9_.]+$');
                if (!validRegex.hasMatch(text)) {
                  return 'Sadece küçük harf, rakam, _ ve . kullanılabilir.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Vazgeç'),
            ),
            PrimaryPillButton(
              text: 'Kaydet',
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  Navigator.pop(ctx);
                  await ref.read(userRepositoryProvider).claimUsername(
                        uid,
                        controller.text.trim().toLowerCase(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kullanıcı adı güncellendi ✓')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yapılsın mı?'),
        content: const Text('Oturumun kapatılacak. İstediğin zaman tekrar giriş yapabilirsin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, String? uid) {
    if (uid == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı ve Bahçeyi Sil?'),
        content: const Text(
          'Tüm alışkanlıkların, zincirlerin ve çiçeklerin kalıcı olarak silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(userRepositoryProvider).deleteUserAccount(uid);
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Kalıcı Olarak Sil'),
          ),
        ],
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
              color: isUnlocked
                  ? (isDark ? AppColors.darkNeutral : AppColors.neutral)
                  : AppColors.neutralVariant,
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
