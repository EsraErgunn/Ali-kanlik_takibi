import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bloom_app_bar.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/habit.dart';
import '../../services/notification_service.dart';
import '../auth/providers.dart';
import 'providers.dart';

class NewHabitScreen extends ConsumerStatefulWidget {
  const NewHabitScreen({super.key});

  @override
  ConsumerState<NewHabitScreen> createState() => _NewHabitScreenState();
}

class _NewHabitScreenState extends ConsumerState<NewHabitScreen> {
  String _habitType = 'build'; // 'build' or 'quit' or 'count'
  final _titleController = TextEditingController();
  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  final Set<int> _reminderDays = {1, 2, 3, 4, 5, 6, 7};
  bool _isSaving = false;

  // For quit habit
  final _unitsPerDayController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController(text: '100');

  // For count habit
  int _dailyTarget = 5;
  String _unit = 'Bardak';

  final List<Color> _colors = [
    AppColors.primary,
    const Color(0xFF2E7D32),
    AppColors.secondary,
    AppColors.tertiary,
    const Color(0xFF6A1B9A),
    const Color(0xFF1565C0),
  ];

  final List<String> _icons = ['🌱', '📚', '🏃‍♂️', '💧', '🚭', '🧘'];

  String _category = 'other';

  final List<Map<String, dynamic>> _templates = [
    {'title': 'Kitap Okuma (20 sf)', 'type': 'build', 'category': 'other', 'icon': '📚', 'target': '20 Sayfa'},
    {'title': 'Sigarayı Bırak', 'type': 'quit', 'category': 'smoking', 'icon': '🚭', 'unit': 'Paket', 'price': 100.0},
    {'title': 'Su İç (5 Bardak)', 'type': 'count', 'category': 'other', 'icon': '💧', 'dailyTarget': 5, 'unit': 'Bardak'},
    {'title': 'Spor & Egzersiz', 'type': 'build', 'category': 'other', 'icon': '🏃‍♂️'},
    {'title': 'Zayıflama & Diyet', 'type': 'build', 'category': 'other', 'icon': '🥗'},
    {'title': 'Alkolü Bırak', 'type': 'quit', 'category': 'alcohol', 'icon': '🍷', 'unit': 'Kadeh', 'price': 150.0},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _unitsPerDayController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _titleController.text = template['title'] as String;
      final typeStr = template['type'] as String;
      _habitType = typeStr;
      _category = template['category'] as String? ?? 'other';
      final iconIdx = _icons.indexOf(template['icon'] as String);
      if (iconIdx != -1) _selectedIconIndex = iconIdx;
      if (typeStr == 'quit') {
        _unitPriceController.text = (template['price'] ?? 100.0).toString();
      } else if (typeStr == 'count') {
        _dailyTarget = (template['dailyTarget'] as num?)?.toInt() ?? 5;
        _unit = template['unit'] as String? ?? 'Bardak';
      }
    });
  }

  Future<void> _saveHabit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tohumuna bir isim ver 🌱')),
      );
      return;
    }

    final uid = ref.read(uidProvider);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce giriş yap.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final habitType = _habitType == 'quit'
          ? HabitType.quit
          : (_habitType == 'count' ? HabitType.count : HabitType.build);

      final habit = Habit(
        id: '',
        title: title,
        type: habitType,
        targetLabel: _habitType == 'build' ? 'Hedef: Günlük Tamamlama' : null,
        dailyTarget: _habitType == 'count' ? _dailyTarget : null,
        unit: _habitType == 'count' ? _unit : null,
        unitsPerDay: _habitType == 'quit' ? int.tryParse(_unitsPerDayController.text) ?? 1 : null,
        unitPrice: _habitType == 'quit' ? double.tryParse(_unitPriceController.text) ?? 0.0 : null,
        category: _category,
        icon: _icons[_selectedIconIndex],
        color: _colors[_selectedColorIndex].toARGB32(),
        startDate: DateTime.now(),
        lastRelapseAt: _habitType == 'quit' ? DateTime.now() : null,
        reminderTime:
            '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
        reminderDays: _reminderDays.toList()..sort(),
        createdAt: DateTime.now(),
      );

      await NotificationService.instance.requestPermissions();
      final newId = await ref.read(habitRepositoryProvider).addHabit(uid, habit);
      await NotificationService.instance.scheduleHabit(habit.copyWith(id: newId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tohum bahçene dikildi! 🌱')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tohum eklenirken hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const BloomAppBar(
        showBack: true,
        titleText: 'Yeni Alışkanlık',
        subtitle: 'Tohum Ek',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          children: [
            Center(
              child: Column(
                children: [
                  const StatusChip(
                    text: '🌱 BOTANİK RİTÜEL OLUŞTURUCU',
                    tone: ChipTone.primary,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Yeni Alışkanlık Tohumu Ek 🌱',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Geliştirmek veya bırakmak istediğin bir döngüyü başlat.',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.neutralVariant),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Segmented switch (Build vs Quit)
            Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _habitType = 'build'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: _habitType == 'build' ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Center(
                          child: Text(
                            '🌱 Alışkanlık Kazan',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: _habitType == 'build' ? Colors.white : AppColors.neutralVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _habitType = 'quit'),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: _habitType == 'quit' ? AppColors.secondary : Colors.transparent,
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Center(
                          child: Text(
                            '🛡 Kötü Alışkanlığı Bırak',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: _habitType == 'quit' ? Colors.white : AppColors.neutralVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            InfoBox(
              text: _habitType == 'build'
                  ? 'Pozitif Büyüme & Rutin Zinciri: Her gün tamamlandığında tohumun beslenir.'
                  : 'Özgürlük Yolu & Temiz Gün Sayacı: Her temiz gün tasarruf ve sağlık kazandırır.',
              tone: _habitType == 'build' ? ChipTone.primary : ChipTone.secondary,
            ),
            SizedBox(height: 16.h),

            // Templates horizontal list
            const SectionHeader(
              title: 'Popüler Tohum Şablonları',
              trailingText: 'Tek Dokunuşla Seç',
            ),
            SizedBox(height: 8.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _templates.map((tpl) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: StatusChip(
                      text: '${tpl['icon']} ${tpl['title']}',
                      tone: tpl['type'] == 'quit' ? ChipTone.secondary : ChipTone.primary,
                      onTap: () => _applyTemplate(tpl),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 16.h),

            // Form Card
            BloomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tohum Adı *',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Örn: Günlük 20 Sayfa Kitap Oku',
                      suffixIcon: Padding(
                        padding: EdgeInsets.all(10.r),
                        child: Text(
                          _icons[_selectedIconIndex],
                          style: TextStyle(fontSize: 20.sp),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Icon Grid
                  Text(
                    'Tohum Simgesi',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_icons.length, (idx) {
                      final isSel = idx == _selectedIconIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIconIndex = idx),
                        child: Container(
                          width: 44.r,
                          height: 44.r,
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primaryContainer : (isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceMuted),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSel ? AppColors.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(_icons[idx], style: TextStyle(fontSize: 22.sp)),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 14.h),

                  // Colors Row
                  Text(
                    'Aura / Saksı Rengi',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_colors.length, (idx) {
                      final isSel = idx == _selectedColorIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorIndex = idx),
                        child: Container(
                          width: 36.r,
                          height: 36.r,
                          decoration: BoxDecoration(
                            color: _colors[idx],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: _colors[idx].withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSel
                              ? const Center(
                                  child: Icon(Icons.check, size: 20, color: Colors.white),
                                )
                              : null,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 14.h),

                  // Quit specific fields
                  if (_habitType == 'quit') ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Günlük Adet/Paket',
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 6.h),
                              TextField(
                                controller: _unitsPerDayController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(hintText: '1'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Birim Fiyat (₺)',
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 6.h),
                              TextField(
                                controller: _unitPriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(hintText: '100.0'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                  ],

                  // Reminder Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '⏰ Sulama & Hatırlatma Saati',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text(
                          _reminderTime.format(context),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _reminderTime,
                          );
                          if (picked != null) setState(() => _reminderTime = picked);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // Repeat Days
                  Text(
                    'Tekrar Günleri',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDayToggle(1, 'Pzt'),
                      _buildDayToggle(2, 'Sal'),
                      _buildDayToggle(3, 'Çar'),
                      _buildDayToggle(4, 'Per'),
                      _buildDayToggle(5, 'Cum'),
                      _buildDayToggle(6, 'Cmt'),
                      _buildDayToggle(7, 'Paz'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Preview card
            BloomCard(
              color: AppColors.primaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Text(_icons[_selectedIconIndex], style: TextStyle(fontSize: 28.sp)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleController.text.isEmpty ? 'Yeni Tohum' : _titleController.text,
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Seviye 1: Filiz Aşaması (0/7 Günlük Tohum)',
                          style: TextStyle(fontSize: 11.sp, color: AppColors.neutralVariant),
                        ),
                      ],
                    ),
                  ),
                  const StatusChip(
                    text: '+10 XP',
                    tone: ChipTone.tertiary,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Submit Button
            PrimaryPillButton(
              text: '🪴 Tohumu Bahçeme Dik',
              isLoading: _isSaving,
              onPressed: _saveHabit,
            ),
            SizedBox(height: 8.h),
            Center(
              child: Text(
                'Tohum bahçene eklenecek ve her gün takip edilecek.',
                style: TextStyle(fontSize: 11.sp, color: AppColors.neutralVariant),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDayToggle(int dayNumber, String dayName) {
    final isSel = _reminderDays.contains(dayNumber);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSel) {
            if (_reminderDays.length > 1) _reminderDays.remove(dayNumber);
          } else {
            _reminderDays.add(dayNumber);
          }
        });
      },
      child: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Text(
            dayName,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: isSel ? Colors.white : AppColors.neutralVariant,
            ),
          ),
        ),
      ),
    );
  }
}
