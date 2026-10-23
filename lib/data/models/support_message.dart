import 'dart:convert';

class SupportMessage {
  const SupportMessage({
    required this.message,
    required this.nextStep,
  });

  final String message;
  final String nextStep;

  Map<String, dynamic> toMap() => {
        'message': message,
        'nextStep': nextStep,
      };

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      message: (map['message'] as String? ?? '').trim(),
      nextStep: (map['nextStep'] as String? ?? '').trim(),
    );
  }

  static bool isValidMap(Map<String, dynamic>? data) {
    if (data == null) return false;
    final msg = data['message'];
    final step = data['nextStep'];
    if (msg is! String || step is! String) return false;
    final trimmedMsg = msg.trim();
    final trimmedStep = step.trim();
    if (trimmedMsg.isEmpty || trimmedMsg.length > 160) return false;
    if (trimmedStep.isEmpty || trimmedStep.length > 100) return false;
    return true;
  }

  static SupportMessage? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is Map<String, dynamic> && isValidMap(decoded)) {
        return SupportMessage.fromMap(decoded);
      }
      if (decoded is Map && isValidMap(Map<String, dynamic>.from(decoded))) {
        return SupportMessage.fromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }
}
