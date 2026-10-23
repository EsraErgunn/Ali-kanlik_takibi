import 'package:cloud_firestore/cloud_firestore.dart';

class HabitLog {
  const HabitLog({
    required this.date,
    required this.status,
    this.count,
    required this.at,
  });

  final String date; // yyyy-MM-dd
  final String status; // 'done' | 'relapse' | 'frozen' | 'partial'
  final int? count;
  final DateTime at;

  factory HabitLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return HabitLog.fromMap(doc.data() ?? {}, defaultDate: doc.id);
  }

  factory HabitLog.fromMap(Map<String, dynamic> data, {String? defaultDate}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return HabitLog(
      date: data['date'] as String? ?? defaultDate ?? '',
      status: data['status'] as String? ?? 'done',
      count: (data['count'] as num?)?.toInt(),
      at: parseDate(data['at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'status': status,
      'count': count,
      'at': Timestamp.fromDate(at),
    };
  }
}
