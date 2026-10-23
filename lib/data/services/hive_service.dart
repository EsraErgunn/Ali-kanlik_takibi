import 'dart:io';
import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  Box? _profileBox;
  Box? _habitsBox;
  Box? _logsBox;
  Box? _motivationBox;
  Box? _settingsBox;

  Box get profileBox => _profileBox!;
  Box get habitsBox => _habitsBox!;
  Box get logsBox => _logsBox!;
  Box get motivationBox => _motivationBox!;
  Box get settingsBox => _settingsBox!;

  bool get isInitialized =>
      _profileBox != null &&
      _profileBox!.isOpen &&
      _habitsBox != null &&
      _habitsBox!.isOpen &&
      _logsBox != null &&
      _logsBox!.isOpen &&
      _motivationBox != null &&
      _motivationBox!.isOpen &&
      _settingsBox != null &&
      _settingsBox!.isOpen;

  Future<void> init({String? subDir}) async {
    if (isInitialized) return;
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      final path = subDir ?? Directory.systemTemp.createTempSync('bloom_hive_').path;
      Hive.init(path);
    } else {
      try {
        await Hive.initFlutter(subDir);
      } catch (_) {
        final path = subDir ?? Directory.systemTemp.createTempSync('bloom_hive_').path;
        Hive.init(path);
      }
    }

    _profileBox = await Hive.openBox('profile');
    _habitsBox = await Hive.openBox('habits');
    _logsBox = await Hive.openBox('logs');
    _motivationBox = await Hive.openBox('motivation');
    _settingsBox = await Hive.openBox('settings');
  }

  bool get hasProfile {
    if (!isInitialized) return false;
    final inSettings = settingsBox.get('has_profile') as bool? ?? false;
    if (inSettings) return true;
    final profile = profileBox.get('current');
    if (profile is Map && (profile['username'] as String? ?? '').trim().isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<void> clearAll() async {
    if (!isInitialized) return;
    await profileBox.clear();
    await habitsBox.clear();
    await logsBox.clear();
    await motivationBox.clear();
    await settingsBox.clear();
  }
}
