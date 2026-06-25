import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/practitioner.dart';

final practitionerBoxProvider = FutureProvider<Box<Practitioner>>((ref) async {
  return Hive.openBox<Practitioner>('practitioners_box');
});

final practitionersProvider = StreamProvider<List<Practitioner>>((ref) async* {
  final box = await ref.watch(practitionerBoxProvider.future);
  yield box.values.toList();
  yield* box.watch().map((_) => box.values.toList());
});

final practitionerProvider =
    StateNotifierProvider<PractitionerNotifier, AsyncValue<void>>((ref) {
  return PractitionerNotifier(ref);
});

class PractitionerNotifier extends StateNotifier<AsyncValue<void>> {
  PractitionerNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> addPractitioner(Practitioner practitioner) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(practitionerBoxProvider.future);
      await box.put(practitioner.id, practitioner);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePractitioner(Practitioner practitioner) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(practitionerBoxProvider.future);
      await box.put(practitioner.id, practitioner);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePractitioner(String id) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(practitionerBoxProvider.future);
      await box.delete(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
