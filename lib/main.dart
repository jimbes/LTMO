import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ltmo/theme/ltmo_colors.dart';
import 'package:ltmo/services/push_notification_service.dart';
import 'package:ltmo/models/user.dart';
import 'package:ltmo/models/couple.dart';
import 'package:ltmo/models/medication.dart';
import 'package:ltmo/models/medication_schedule.dart';
import 'package:ltmo/models/medication_taken_log.dart';
import 'package:ltmo/models/appointment.dart';
import 'package:ltmo/models/journey_stage.dart';
import 'package:ltmo/models/practitioner.dart';
import 'package:ltmo/models/notification_preference.dart';
import 'package:ltmo/navigation/router.dart';
import 'package:ltmo/data/mock_data.dart';
import 'package:ltmo/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize French locale for date formatting
  await initializeDateFormatting('fr_FR', null);

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(CoupleAdapter());
  Hive.registerAdapter(MedicationAdapter());
  Hive.registerAdapter(MedicationScheduleAdapter());
  Hive.registerAdapter(MedicationTakenLogAdapter());
  Hive.registerAdapter(AppointmentAdapter());
  Hive.registerAdapter(JourneyStageAdapter());
  Hive.registerAdapter(PractitionerAdapter());
  Hive.registerAdapter(NotificationPreferenceAdapter());

  // Open Hive boxes. If a box's on-disk data doesn't match the current
  // model shape (e.g. after adding a required field), fall back to a fresh
  // empty box instead of crashing the app on launch.
  await _openBoxSafely<User>('users_box');
  await _openBoxSafely<Couple>('couples_box');
  await _openBoxSafely<Medication>('medications_box');
  await _openBoxSafely<MedicationSchedule>('schedules_box');
  await _openBoxSafely<MedicationTakenLog>('logs_box');
  await _openBoxSafely<Appointment>('appointments_box');
  await _openBoxSafely<JourneyStage>('stages_box');
  await _openBoxSafely<Practitioner>('practitioners_box');
  await _openBoxSafely<NotificationPreference>('notif_prefs_box');

  // Don't seed mock data - users get real data from API after login
  // await seedMockData();

  await LocalNotificationService.instance.init();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  wireAuthProviderNavigation();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _openBoxSafely<T>(String name) async {
  try {
    await Hive.openBox<T>(name);
    return;
  } catch (_) {
    // Fall through to recovery below: on-disk data likely doesn't match
    // the current model shape (e.g. a field was added/changed).
  }

  try {
    await Hive.deleteBoxFromDisk(name);
  } catch (_) {
    // Ignore: file may already be partially removed by the failed open.
  }

  try {
    await Hive.openBox<T>(name);
  } catch (_) {
    // Give up gracefully; the app continues without this box rather than
    // crashing on launch.
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'LTMO',
      theme: LtmoColors.lightTheme,
      routerConfig: goRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
        Locale('de', 'DE'),
        Locale('es', 'ES'),
      ],
      // No explicit `locale:` set - Flutter resolves the device's locale
      // against supportedLocales automatically, falling back to French.
    );
  }
}
