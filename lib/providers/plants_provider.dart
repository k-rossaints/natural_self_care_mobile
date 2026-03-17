import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plant.dart';
import '../services/api_service.dart';

final plantsProvider = AsyncNotifierProvider<PlantsNotifier, List<Plant>>(
  PlantsNotifier.new,
);

class PlantsNotifier extends AsyncNotifier<List<Plant>> {
  @override
  Future<List<Plant>> build() async {
    return ApiService().getPlants();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ApiService().getPlants());
  }
}