import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:monthly_goals/core/services/supabase_service.dart';
import 'package:monthly_goals/core/services/notification_service.dart';
import 'package:monthly_goals/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize local notifications
  await NotificationService.initialize();

  runApp(
    const ProviderScope(
      child: MonthlyGoalsApp(),
    ),
  );
}
