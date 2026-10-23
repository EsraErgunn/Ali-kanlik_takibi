import 'package:cloud_firestore/cloud_firestore.dart';

enum HabitType { build, quit, count }

class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.type,
    this.targetLabel,
    this.dailyTarget,
    this.unit,
    this.unitAmountLabel,
    this.unitsPerDay,
    this.unitPrice,
    this.category = 'other',
    required this.icon,
    required this.color,
    required this.startDate,
    this.lastRelapseAt,
    this.reminderTime,
    this.reminderDays = const [1, 2, 3, 4, 5, 6, 7],
    this.isDeleted = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final HabitType type;
  final String? targetLabel;
  final int? dailyTarget;
  final String? unit;
  final String? unitAmountLabel;
  final int? unitsPerDay;
  final double? unitPrice;
  final String category; // "smoking" | "alcohol" | "other"
  final String icon;
  final int color; // ARGB
  final DateTime startDate;
  final DateTime? lastRelapseAt;
  final String? reminderTime; // "HH:mm"
  final List<int> reminderDays; // 1=Mon ... 7=Sun
  final bool isDeleted;
  final DateTime createdAt;

  factory Habit.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Habit.fromMap(doc.id, doc.data() ?? {});
  }

  factory Habit.fromMap(String id, Map<String, dynamic> data) {
    final typeStr = data['type'] as String? ?? 'build';
    final habitType = HabitType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => HabitType.build,
    );

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Habit(
      id: id,
      title: data['title'] as String? ?? '',
      type: habitType,
      targetLabel: data['targetLabel'] as String?,
      dailyTarget: (data['dailyTarget'] as num?)?.toInt(),
      unit: data['unit'] as String?,
      unitAmountLabel: data['unitAmountLabel'] as String?,
      unitsPerDay: (data['unitsPerDay'] as num?)?.toInt(),
      unitPrice: (data['unitPrice'] as num?)?.toDouble(),
      category: data['category'] as String? ?? 'other',
      icon: data['icon'] as String? ?? '🌱',
      color: (data['color'] as num?)?.toInt() ?? 0xFF1B6B48,
      startDate: parseDate(data['startDate']),
      lastRelapseAt: parseNullableDate(data['lastRelapseAt']),
      reminderTime: data['reminderTime'] as String?,
      reminderDays: (data['reminderDays'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      isDeleted: data['isDeleted'] as bool? ?? false,
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type.name,
      'targetLabel': targetLabel,
      'dailyTarget': dailyTarget,
      'unit': unit,
      'unitAmountLabel': unitAmountLabel,
      'unitsPerDay': unitsPerDay,
      'unitPrice': unitPrice,
      'category': category,
      'icon': icon,
      'color': color,
      'startDate': Timestamp.fromDate(startDate),
      'lastRelapseAt': lastRelapseAt != null ? Timestamp.fromDate(lastRelapseAt!) : null,
      'reminderTime': reminderTime,
      'reminderDays': reminderDays,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Habit copyWith({
    String? id,
    String? title,
    HabitType? type,
    String? targetLabel,
    int? dailyTarget,
    String? unit,
    String? unitAmountLabel,
    int? unitsPerDay,
    double? unitPrice,
    String? category,
    String? icon,
    int? color,
    DateTime? startDate,
    DateTime? lastRelapseAt,
    String? reminderTime,
    List<int>? reminderDays,
    bool? isDeleted,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      targetLabel: targetLabel ?? this.targetLabel,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      unit: unit ?? this.unit,
      unitAmountLabel: unitAmountLabel ?? this.unitAmountLabel,
      unitsPerDay: unitsPerDay ?? this.unitsPerDay,
      unitPrice: unitPrice ?? this.unitPrice,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      startDate: startDate ?? this.startDate,
      lastRelapseAt: lastRelapseAt ?? this.lastRelapseAt,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderDays: reminderDays ?? this.reminderDays,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
    );
  }
}
