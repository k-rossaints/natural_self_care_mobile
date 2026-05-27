import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plant.dart';
import '../services/api_service.dart';

/*
  Provider Riverpod exposant la liste des plantes à l'ensemble de l'application.
  AsyncNotifierProvider gère automatiquement les états loading/data/error,
  ce qui évite de gérer manuellement ces états dans chaque widget consommateur.
*/
final plantsProvider = AsyncNotifierProvider<PlantsNotifier, List<Plant>>(
  PlantsNotifier.new,
);

class PlantsNotifier extends AsyncNotifier<List<Plant>> {
  @override
  Future<List<Plant>> build() async {
    return ApiService().getPlants();
  }

  // Remet l'état en loading avant de relancer le chargement,
  // utilisé par le bouton "Réessayer" du widget ErrorView.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ApiService().getPlants());
  }
}