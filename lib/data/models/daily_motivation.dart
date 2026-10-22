import 'package:cloud_firestore/cloud_firestore.dart';

class MotivationOption {
  const MotivationOption({
    required this.title,
    required this.text,
    required this.tag,
  });

  final String title;
  final String text;
  final String tag;

  factory MotivationOption.fromMap(Map<String, dynamic> map) {
    return MotivationOption(
      title: map['title'] as String? ?? '🌱 Günün Bilgeliği',
      text: map['text'] as String? ?? 'Her tohum sabırla büyür.',
      tag: map['tag'] as String? ?? '#Büyüme',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'text': text,
      'tag': tag,
    };
  }
}

class DailyMotivation {
  const DailyMotivation({
    required this.date,
    required this.options,
    this.selectedIndex,
    this.selectedAt,
  });

  final String date; // yyyy-MM-dd
  final List<MotivationOption> options; // Exactly 3 options
  final int? selectedIndex;
  final DateTime? selectedAt;

  bool get isSelected => selectedIndex != null;

  factory DailyMotivation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawOptions = data['options'] as List<dynamic>? ?? [];

    final parsedOptions = rawOptions.map((item) {
      if (item is Map<String, dynamic>) {
        return MotivationOption.fromMap(item);
      } else if (item is String) {
        return MotivationOption(
          title: '🌱 Günün Tohumu',
          text: item,
          tag: '#BotanikEnerji',
        );
      }
      return const MotivationOption(
        title: '🌱 Derin Kökler',
        text: 'Sabırla yeşeren her alışkanlık sağlam bir orman kurar.',
        tag: '#Direnç',
      );
    }).toList();

    return DailyMotivation(
      date: data['date'] as String? ?? doc.id,
      options: parsedOptions,
      selectedIndex: (data['selectedIndex'] as num?)?.toInt(),
      selectedAt: (data['selectedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'options': options.map((o) => o.toMap()).toList(),
      'selectedIndex': selectedIndex,
      'selectedAt': selectedAt != null ? Timestamp.fromDate(selectedAt!) : null,
    };
  }
}
