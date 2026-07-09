import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/practitioner.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final practitionerBoxProvider = FutureProvider<Box<Practitioner>>((ref) async {
  return Hive.openBox<Practitioner>('practitioners_box');
});

final practitionersProvider = FutureProvider<List<Practitioner>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final token = await ref.watch(authTokenProvider.future);

  if (token == null) {
    return [];
  }

  try {
    final practitioners = await apiService.getPractitioners();
    final list = (practitioners as List)
        .map((p) => Practitioner.fromJson(p as Map<String, dynamic>))
        .toList();

    // Cache in Hive
    final box = await ref.read(practitionerBoxProvider.future);
    for (var practitioner in list) {
      await box.put(practitioner.id, practitioner);
    }

    return list;
  } catch (e) {
    // Fall back to local cache
    final box = await ref.read(practitionerBoxProvider.future);
    return box.values.toList();
  }
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
      final apiService = ref.read(apiServiceProvider);

      final data = {
        'name': practitioner.name,
        'specialty': practitioner.specialty,
        'phone': practitioner.phone,
        'email': practitioner.email,
        'clinic_name': practitioner.clinicName,
        'address': practitioner.address,
      };

      await apiService.createPractitioner(data);

      // Refresh the list
      ref.invalidate(practitionersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePractitioner(Practitioner practitioner) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);

      final data = {
        'name': practitioner.name,
        'specialty': practitioner.specialty,
        'phone': practitioner.phone,
        'email': practitioner.email,
        'clinic_name': practitioner.clinicName,
        'address': practitioner.address,
      };

      await apiService.updatePractitioner(practitioner.id, data);

      // Refresh the list
      ref.invalidate(practitionersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePractitioner(String id) async {
    try {
      state = const AsyncValue.loading();
      final apiService = ref.read(apiServiceProvider);
      await apiService.deletePractitioner(id);

      // Refresh the list
      ref.invalidate(practitionersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
