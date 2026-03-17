import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/plant.dart';
import '../models/decision_step.dart';
import '../models/symptom.dart';
import '../models/reference.dart';
import '../models/generic_reference.dart';
import '../models/pending_reference.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // Clés de stockage
  static const String KEY_PLANTS = 'offline_plants';
  static const String KEY_SYMPTOMS = 'offline_symptoms';
  static const String KEY_STEPS = 'offline_steps';
  static const String KEY_ALL_REFERENCES = 'offline_all_references';
  static const String KEY_GENERIC_REFERENCES = 'offline_generic_references';
  static const String KEY_PENDING_REFERENCES = 'offline_pending_references';
  static const String KEY_SAVE_IMAGES = 'offline_settings_images';
  static const String KEY_DATE_PLANTS = 'offline_date_plants';
  static const String KEY_DATE_PATHS = 'offline_date_paths';
  static const String KEY_DATE_METHODOLOGY = 'offline_date_methodology';

  // --- 1. Réglages ---

  Future<void> setSaveImages(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KEY_SAVE_IMAGES, value);
  }

  Future<bool> shouldSaveImages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_SAVE_IMAGES) ?? false;
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  Future<Map<String, String?>> getSyncDates() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'plants': prefs.getString(KEY_DATE_PLANTS),
      'paths': prefs.getString(KEY_DATE_PATHS),
      'methodology': prefs.getString(KEY_DATE_METHODOLOGY),
    };
  }

  // --- 2. Sauvegarde automatique (appelée après chaque chargement réseau) ---

  Future<void> autoSavePlants(List<Plant> plants) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(KEY_PLANTS, jsonEncode(plants.map((p) => p.toJson()).toList()));
      await prefs.setString(KEY_DATE_PLANTS, _getCurrentDate());
      debugPrint("✅ Plantes sauvegardées automatiquement (${plants.length})");
    } catch (e) {
      debugPrint("⚠️ Erreur sauvegarde auto plantes: $e");
    }
  }

  Future<void> autoSaveSymptoms(List<Symptom> symptoms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(KEY_SYMPTOMS, jsonEncode(symptoms.map((s) => s.toJson()).toList()));
      debugPrint("✅ Symptômes sauvegardés automatiquement (${symptoms.length})");
    } catch (e) {
      debugPrint("⚠️ Erreur sauvegarde auto symptômes: $e");
    }
  }

  Future<void> autoSaveDecisionSteps(List<DecisionStep> steps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(KEY_STEPS, jsonEncode(steps.map((s) => s.toJson()).toList()));
      await prefs.setString(KEY_DATE_PATHS, _getCurrentDate());
      debugPrint("✅ Chemins sauvegardés automatiquement (${steps.length})");
    } catch (e) {
      debugPrint("⚠️ Erreur sauvegarde auto chemins: $e");
    }
  }

  Future<void> autoSaveMethodology({
    required List<Reference> allReferences,
    required List<GenericReference> genericReferences,
    required List<PendingReference> pendingReferences,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(KEY_ALL_REFERENCES, jsonEncode(allReferences.map((r) => r.toJson()).toList()));
      await prefs.setString(KEY_GENERIC_REFERENCES, jsonEncode(genericReferences.map((g) => g.toJson()).toList()));
      await prefs.setString(KEY_PENDING_REFERENCES, jsonEncode(pendingReferences.map((p) => p.toJson()).toList()));
      await prefs.setString(KEY_DATE_METHODOLOGY, _getCurrentDate());
      debugPrint("✅ Démarche scientifique sauvegardée automatiquement");
    } catch (e) {
      debugPrint("⚠️ Erreur sauvegarde auto methodology: $e");
    }
  }

  // --- 3. Lecture locale ---

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

  Future<List<Reference>> getLocalAllReferences() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(KEY_ALL_REFERENCES);
    if (data == null) return [];
    return (jsonDecode(data) as List).map((json) => Reference.fromJson(json)).toList();
  }

  /// Retourne les références d'une plante spécifique depuis le cache local
  Future<List<Reference>> getLocalReferencesForPlant(int plantId) async {
    final all = await getLocalAllReferences();
    // Les références par plante sont stockées sans plantName dans KEY_ALL_REFERENCES
    // On les récupère depuis le cache plantes pour faire le lien
    final plants = await getLocalPlants();
    final plant = plants.where((p) => p.id == plantId).firstOrNull;
    if (plant == null) return [];
    return all.where((r) => r.plantName == plant.name).toList();
  }

  Future<List<GenericReference>> getLocalGenericReferences() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(KEY_GENERIC_REFERENCES);
    if (data == null) return [];
    return (jsonDecode(data) as List).map((json) => GenericReference.fromJson(json)).toList();
  }

  Future<List<PendingReference>> getLocalPendingReferences() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(KEY_PENDING_REFERENCES);
    if (data == null) return [];
    return (jsonDecode(data) as List).map((json) => PendingReference.fromJson(json)).toList();
  }

  // --- 5. Nettoyage ---

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_PLANTS);
    await prefs.remove(KEY_SYMPTOMS);
    await prefs.remove(KEY_STEPS);
    await prefs.remove(KEY_ALL_REFERENCES);
    await prefs.remove(KEY_GENERIC_REFERENCES);
    await prefs.remove(KEY_PENDING_REFERENCES);
    await prefs.remove(KEY_DATE_PLANTS);
    await prefs.remove(KEY_DATE_PATHS);
    await prefs.remove(KEY_DATE_METHODOLOGY);
    await DefaultCacheManager().emptyCache();
    debugPrint("🗑️ Données locales et cache images supprimés.");
  }
}