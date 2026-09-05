import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/couple.dart';
import '../models/medication.dart';
import '../models/medication_schedule.dart';
import '../models/appointment.dart';
import '../models/journey_stage.dart';
import '../models/practitioner.dart';

Future<void> seedMockData() async {
  final usersBox = Hive.box<User>('users_box');
  final couplesBox = Hive.box<Couple>('couples_box');
  final medicationsBox = Hive.box<Medication>('medications_box');
  final schedulesBox = Hive.box<MedicationSchedule>('schedules_box');
  final appointmentsBox = Hive.box<Appointment>('appointments_box');
  final stagesBox = Hive.box<JourneyStage>('stages_box');
  final practitionersBox = Hive.box<Practitioner>('practitioners_box');

  // Only seed if boxes are empty
  if (usersBox.isEmpty) {
    final now = DateTime.now();

    // Create couple
    final couple = Couple(
      id: '1',
      user1Id: 'user1',
      user2Id: 'user2',
      createdAt: now,
      updatedAt: now,
    );
    await couplesBox.put(couple.id, couple);

    // Create users
    final user1 = User(
      id: 'user1',
      name: 'Léa',
      email: 'lea@example.com',
      coupleId: '1',
      language: 'fr',
      createdAt: now,
      updatedAt: now,
    );
    final user2 = User(
      id: 'user2',
      name: 'Tom',
      email: 'tom@example.com',
      coupleId: '1',
      language: 'fr',
      createdAt: now,
      updatedAt: now,
    );
    await usersBox.put(user1.id, user1);
    await usersBox.put(user2.id, user2);

    // Create medications
    final med1 = Medication(
      id: 'med1',
      coupleId: '1',
      name: 'Gonal-F',
      dosage: '75',
      unit: 'UI',
      form: 'injection',
      forPartner: 'user1',
      active: true,
      createdAt: now,
      updatedAt: now,
    );
    final med2 = Medication(
      id: 'med2',
      coupleId: '1',
      name: 'Progestérone',
      dosage: '200',
      unit: 'mg',
      form: 'comprimé',
      forPartner: 'user1',
      active: true,
      createdAt: now,
      updatedAt: now,
    );
    await medicationsBox.put(med1.id, med1);
    await medicationsBox.put(med2.id, med2);

    // Create schedules
    final schedule1 = MedicationSchedule(
      id: 'sched1',
      medicationId: 'med1',
      coupleId: '1',
      startDate: now,
      frequency: 'daily',
      reminderTimes: ['09:00', '21:00'],
      reminderOffsets: const [15],
      notifyUser1: true,
      notifyUser2: false,
      createdAt: now,
      updatedAt: now,
    );
    await schedulesBox.put(schedule1.id, schedule1);

    // Create appointments
    final appt1 = Appointment(
      id: 'appt1',
      coupleId: '1',
      title: 'Échographie de suivi',
      appointmentDate: now.add(const Duration(days: 2)),
      appointmentTime: DateTime(now.year, now.month, now.day + 2, 10, 30),
      types: const ['echo'],
      doctorName: 'Dr. Martin',
      location: 'Clinique de la Fertilité',
      notifyUser1: true,
      notifyUser2: true,
      completed: false,
      reminderOffsets: const [60],
      createdAt: now,
      updatedAt: now,
    );
    final appt2 = Appointment(
      id: 'appt2',
      coupleId: '1',
      title: 'Prise de sang',
      appointmentDate: now.add(const Duration(days: 5)),
      types: const ['blood_test'],
      notifyUser1: true,
      notifyUser2: false,
      completed: false,
      reminderOffsets: const [60],
      createdAt: now,
      updatedAt: now,
    );
    await appointmentsBox.put(appt1.id, appt1);
    await appointmentsBox.put(appt2.id, appt2);

    // Create journey stages
    final stage1 = JourneyStage(
      id: 'stage1',
      coupleId: '1',
      type: 'stimulation',
      startDate: now.subtract(const Duration(days: 5)),
      status: 'in_progress',
      reminderEnabled: true,
      notes: 'Stimulation ovarienne en cours',
      createdAt: now,
      updatedAt: now,
    );
    final stage2 = JourneyStage(
      id: 'stage2',
      coupleId: '1',
      type: 'declenchement',
      startDate: now.add(const Duration(days: 5)),
      status: 'upcoming',
      reminderEnabled: true,
      createdAt: now,
      updatedAt: now,
    );
    await stagesBox.put(stage1.id, stage1);
    await stagesBox.put(stage2.id, stage2);

    // Create practitioners
    final pract1 = Practitioner(
      id: 'pract1',
      coupleId: '1',
      name: 'Dr. Martin',
      specialty: 'Gynécologue - Fertilité',
      phone: '+33 1 23 45 67 89',
      email: 'martin@clinique-fertility.fr',
      clinicName: 'Clinique de la Fertilité',
      address: '123 Avenue des Champs, 75008 Paris',
      createdAt: now,
      updatedAt: now,
    );
    await practitionersBox.put(pract1.id, pract1);
  }
}
