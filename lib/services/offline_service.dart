import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart'; // NOUVEL IMPORT POUR LE CACHE
import '../models/plant.dart';
import '../models/decision_step.dart';
import '../models/symptom.dart';
import 'api_service.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // Clés de stockage
  static const String KEY_PLANTS = 'offline_plants';
  static const String KEY_SYMPTOMS = 'offline_symptoms';
  static const String KEY_STEPS = 'offline_steps';
  static const String KEY_SAVE_IMAGES = 'offline_settings_images';

  // NOUVEAU : Clés pour les dates séparées
  static const String KEY_DATE_PLANTS = 'offline_date_plants';
  static const String KEY_DATE_PATHS = 'offline_date_paths';

  // --- 1. Gestion des Réglages ---

  Future<void> setSaveImages(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KEY_SAVE_IMAGES, value);
  }

  Future<bool> shouldSaveImages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_SAVE_IMAGES) ?? false;
  }

  // Helper pour avoir la date actuelle formatée
  String _getCurrentDate() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2,'0')}";
  }

  // Récupérer les dates pour l'affichage
  Future<Map<String, String?>> getSyncDates() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'plants': prefs.getString(KEY_DATE_PLANTS),
      'paths': prefs.getString(KEY_DATE_PATHS),
    };
  }

  // --- 2. Sauvegarde ---

  Future<void> downloadPlants() async {
    final api = ApiService();
    final plants = await api.getPlantsFromNetwork();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_PLANTS, jsonEncode(plants.map((p) => p.toJson()).toList()));

    // On met à jour SEULEMENT la date des plantes
    await prefs.setString(KEY_DATE_PLANTS, _getCurrentDate());

    if (await shouldSaveImages()) {
      print("📸 Téléchargement images plantes...");
      for (var plant in plants) {
        if (plant.image != null) {
          try {
            // CORRECTION DU CACHE ICI
            final imageUrl = api.getImageUrl(plant.image!);
            await CachedNetworkImageProvider(imageUrl).evict();
            await DefaultCacheManager().downloadFile(imageUrl);
          } catch (e) { print("Err img ${plant.name}: $e"); }
        }
      }
    }
  }

  Future<void> downloadDecisionPaths() async {
    final api = ApiService();
    final symptoms = await api.getSymptomsFromNetwork();
    final steps = await api.getDecisionStepsFromNetwork();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_SYMPTOMS, jsonEncode(symptoms.map((s) => s.toJson()).toList()));
    await prefs.setString(KEY_STEPS, jsonEncode(steps.map((s) => s.toJson()).toList()));

    // On met à jour SEULEMENT la date des chemins
    await prefs.setString(KEY_DATE_PATHS, _getCurrentDate());

    if (await shouldSaveImages()) {
      print("📸 Téléchargement images parcours...");
      for (var step in steps) {
        for (var plant in step.recommendedPlants) {
          if (plant.image != null) {
            try {
              // CORRECTION DU CACHE ICI
              final imageUrl = api.getImageUrl(plant.image!);
              await CachedNetworkImageProvider(imageUrl).evict();
              await DefaultCacheManager().downloadFile(imageUrl);
            } catch (e) { print("Err img parcours: $e"); }
          }
        }
      }
    }
  }

  // --- 3. Lecture ---
  
  Future<List<Plant>> getLocalPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(KEY_PLANTS);
    if (data == null) return [];
    return (jsonDecode(data) as List).map((json) => Plant.fromJson(json)).toList();
  }

  Future<List<Symptom>> getLocalSymptoms() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(KEY_SYMPTOMS);
    if (data == null) return [];
    return (jsonDecode(data) as List).map((json) => Symptom.fromJson(json)).toList();
  }

  Future<List<DecisionStep>> getLocalDecisionSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(KEY_STEPS);
    if (data == null) return [];
    return (jsonDecode(data) as List).map((json) => DecisionStep.fromJson(json)).toList();
  }

  // --- 4. Nettoyage ---

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_PLANTS);
    await prefs.remove(KEY_SYMPTOMS);
    await prefs.remove(KEY_STEPS);
    
    await prefs.remove(KEY_DATE_PLANTS);
    await prefs.remove(KEY_DATE_PATHS);
    
    await DefaultCacheManager().emptyCache();
    print("🗑️ Données locales et cache images supprimés.");
  }
}