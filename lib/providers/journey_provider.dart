import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/journey_stage.dart';

final stageBoxProvider = FutureProvider<Box<JourneyStage>>((ref) async {
  return Hive.openBox<JourneyStage>('stages_box');
});

final stagesProvider = StreamProvider<List<JourneyStage>>((ref) async* {
  final box = await ref.watch(stageBoxProvider.future);
  yield box.values.toList();
  yield* box.watch().map((_) => box.values.toList());
});

final currentPhaseProvider = StreamProvider<JourneyStage?>((ref) async* {
  final box = await ref.watch(stageBoxProvider.future);
  yield _getCurrentPhase(box.values.toList());
  yield* box.watch().map((_) => _getCurrentPhase(box.values.toList()));
});

JourneyStage? _getCurrentPhase(List<JourneyStage> stages) {
  for (final stage in stages) {
    if (stage.status == 'in_progress') {
      return stage;
    }
  }
  return stages.isNotEmpty ? stages.first : null;
}

final journeyProvider =
    StateNotifierProvider<JourneyNotifier, AsyncValue<void>>((ref) {
  return JourneyNotifier(ref);
});

class JourneyNotifier extends StateNotifier<AsyncValue<void>> {
  JourneyNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> addStage(JourneyStage stage) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(stageBoxProvider.future);
      await box.put(stage.id, stage);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStage(JourneyStage stage) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(stageBoxProvider.future);
      await box.put(stage.id, stage);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteStage(String id) async {
    try {
      state = const AsyncValue.loading();
      final box = await ref.read(stageBoxProvider.future);
      await box.delete(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
