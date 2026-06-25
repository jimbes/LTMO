import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_flutter/theme/app_theme.dart';
import 'package:pma_flutter/models/user.dart';
import 'package:pma_flutter/models/couple.dart';
import 'package:pma_flutter/models/medication.dart';
import 'package:pma_flutter/models/medication_schedule.dart';
import 'package:pma_flutter/models/medication_taken_log.dart';
import 'package:pma_flutter/models/appointment.dart';
import 'package:pma_flutter/models/journey_stage.dart';
import 'package:pma_flutter/models/practitioner.dart';
import 'package:pma_flutter/models/notification_preference.dart';
import 'package:pma_flutter/navigation/router.dart';
import 'package:pma_flutter/data/mock_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Open Hive boxes
  await Hive.openBox<User>('users_box');
  await Hive.openBox<Couple>('couples_box');
  await Hive.openBox<Medication>('medications_box');
  await Hive.openBox<MedicationSchedule>('schedules_box');
  await Hive.openBox<MedicationTakenLog>('logs_box');
  await Hive.openBox<Appointment>('appointments_box');
  await Hive.openBox<JourneyStage>('stages_box');
  await Hive.openBox<Practitioner>('practitioners_box');
  await Hive.openBox<NotificationPreference>('notif_prefs_box');

  // Seed mock data
  await seedMockData();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'LTMO',
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
    );
  }
}
