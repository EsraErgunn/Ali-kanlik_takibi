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
    final data = doc.data() ?? {};
    return HabitLog(
      date: data['date'] as String? ?? doc.id,
      status: data['status'] as String? ?? 'done',
      count: (data['count'] as num?)?.toInt(),
      at: (data['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
