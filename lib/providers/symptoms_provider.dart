import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/symptom.dart';
import '../services/api_service.dart';

/// Provider qui charge les symptômes une seule fois et les partage entre tous les écrans
final symptomsProvider = AsyncNotifierProvider<SymptomsNotifier, List<Symptom>>(
  SymptomsNotifier.new,
);

class SymptomsNotifier extends AsyncNotifier<List<Symptom>> {
  @override
  Future<List<Symptom>> build() async {
    return ApiService().getSymptoms();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ApiService().getSymptoms());
  }
}