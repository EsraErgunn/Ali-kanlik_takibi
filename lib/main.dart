import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Turkish date formatting
  Intl.defaultLocale = 'tr_TR';
  await initializeDateFormatting('tr_TR', null);

  // Initialize Notification Service
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Notification service init notice: $e');
  }

  // Initialize Firebase safely
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(
    const ProviderScope(
      child: BloomHabitApp(),
    ),
  );
}
