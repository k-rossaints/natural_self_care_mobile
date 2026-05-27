import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/symptom.dart';
import '../services/api_service.dart';

/*
  Provider Riverpod exposant la liste des symptômes à l'ensemble de l'application.
  Les données sont chargées une seule fois et partagées entre tous les écrans
  consommateurs, évitant des appels réseau redondants.
*/
final symptomsProvider = AsyncNotifierProvider<SymptomsNotifier, List<Symptom>>(
  SymptomsNotifier.new,
);

class SymptomsNotifier extends AsyncNotifier<List<Symptom>> {
  @override
  Future<List<Symptom>> build() async {
    return ApiService().getSymptoms();
  }

  // Remet l'état en loading avant de relancer le chargement,
  // utilisé par le bouton "Réessayer" du widget ErrorView.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ApiService().getSymptoms());
  }
}