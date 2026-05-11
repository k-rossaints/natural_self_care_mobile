import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/plant.dart';
import '../models/symptom.dart';
import '../models/decision_step.dart';
import '../models/reference.dart';
import '../models/generic_reference.dart';
import '../models/pending_reference.dart';
import 'offline_service.dart';

// --- FONCTIONS TOP-LEVEL POUR LES ISOLATES ---
List<Plant> _parsePlants(dynamic data) => (data as List).map((json) => Plant.fromJson(json)).toList();
List<Symptom> _parseSymptoms(dynamic data) => (data as List).map((json) => Symptom.fromJson(json)).toList();
List<DecisionStep> _parseDecisionSteps(dynamic data) => (data as List).map((json) => DecisionStep.fromJson(json)).toList();
List<Reference> _parseReferences(dynamic data) => (data as List).map((json) => Reference.fromJson(json)).toList();
List<GenericReference> _parseGenericReferences(dynamic data) => (data as List).map((json) => GenericReference.fromJson(json)).toList();
List<PendingReference> _parsePendingReferences(dynamic data) => (data as List).map((json) => PendingReference.fromJson(json)).toList();

class ApiService {
  static const String baseUrl = 'https://directus-rk4w4cskcos4kwwoc84s88ss.46.224.187.154.sslip.io';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<bool> _hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Cache-first : retourne le cache immédiatement s'il existe,
  /// puis rafraîchit en arrière-plan sans bloquer l'UI.
  /// Si pas de cache, attend le réseau (premier lancement).
  Future<T> _cacheFirst<T>({
    required Future<T> Function() fromNetwork,
    required Future<T> Function() fromCache,
    required Future<void> Function(T data) saveToCache,
  }) async {
    final cached = await fromCache();

    // Si on a un cache → on l'affiche immédiatement
    if (cached is List && (cached as List).isNotEmpty) {
      // Rafraîchissement silencieux en arrière-plan
      _refreshInBackground(fromNetwork: fromNetwork, saveToCache: saveToCache);
      return cached;
    }

    // Pas de cache → premier lancement, on attend le réseau
    if (await _hasConnection()) {
      try {
        final fresh = await fromNetwork();
        await saveToCache(fresh);
        return fresh;
      } catch (e) {
        debugPrint("⚠️ Réseau indisponible au premier lancement: $e");
      }
    }

    throw Exception("Aucune donnée disponible. Vérifiez votre connexion.");
  }

  /// Rafraîchit en arrière-plan sans bloquer, ignore les erreurs réseau
  void _refreshInBackground<T>({
    required Future<T> Function() fromNetwork,
    required Future<void> Function(T data) saveToCache,
  }) {
    Future.microtask(() async {
      if (!await _hasConnection()) return;
      try {
        final fresh = await fromNetwork();
        await saveToCache(fresh);
        debugPrint("✅ Rafraîchissement arrière-plan OK");
      } catch (e) {
        debugPrint("ℹ️ Rafraîchissement arrière-plan échoué (normal hors ligne): $e");
      }
    });
  }

  // --- PLANTES ---

  Future<List<Plant>> getPlantsFromNetwork() async {
    final response = await _dio.get('/items/plants', queryParameters: {
      'fields': 'id,name,slug,scientific_name,common_names,habitat,image,plant_type,description_short,is_clinically_validated,safety_precautions,side_effects,usage_preparation,usage_duration,description_visual,procurement_picking,procurement_buying,procurement_culture,confusion_risks,scientific_references,linked_ailments.ailments_id.name',
      'sort': 'name',
      'limit': -1,
    });
    return compute(_parsePlants, response.data['data']);
  }

  Future<List<Plant>> getPlants() async {
    final offline = OfflineService();
    return _cacheFirst(
      fromNetwork: getPlantsFromNetwork,
      fromCache: offline.getLocalPlants,
      saveToCache: offline.autoSavePlants,
    );
  }

  Future<Plant> getPlantDetails(int id) async {
    try {
      final response = await _dio.get('/items/plants/$id', queryParameters: {
        'fields': 'id,name,slug,scientific_name,common_names,habitat,image,plant_type,description_short,is_clinically_validated,safety_precautions,side_effects,usage_preparation,usage_duration,description_visual,procurement_picking,procurement_buying,procurement_culture,confusion_risks,scientific_references,linked_ailments.ailments_id.name',
      });
      return Plant.fromJson(response.data['data']);
    } catch (e) {
      try {
        final local = await OfflineService().getLocalPlants();
        return local.firstWhere((p) => p.id == id);
      } catch (_) {
        throw Exception("Détail plante introuvable hors ligne");
      }
    }
  }

  // --- SYMPTÔMES & DÉCISIONS ---

  Future<List<Symptom>> getSymptomsFromNetwork() async {
    final response = await _dio.get('/items/symptoms', queryParameters: {
      'fields': 'id,name,description,additional_info,start_step',
      'sort': 'name',
      'limit': -1,
    });
    return compute(_parseSymptoms, response.data['data']);
  }

  Future<List<DecisionStep>> getDecisionStepsFromNetwork() async {
    final response = await _dio.get('/items/decision_steps', queryParameters: {
      'fields': 'id,type,content,next_step_yes,next_step_no,is_emergency,recommended_remedies.plants_id.id,recommended_remedies.plants_id.name,recommended_remedies.plants_id.slug,recommended_remedies.plants_id.image,recommended_remedies.plants_id.is_clinically_validated',
      'limit': -1,
    });
    return compute(_parseDecisionSteps, response.data['data']);
  }

  Future<List<Symptom>> getSymptoms() async {
    final offline = OfflineService();
    return _cacheFirst(
      fromNetwork: getSymptomsFromNetwork,
      fromCache: offline.getLocalSymptoms,
      saveToCache: offline.autoSaveSymptoms,
    );
  }

  Future<List<DecisionStep>> getDecisionSteps() async {
    final offline = OfflineService();
    return _cacheFirst(
      fromNetwork: getDecisionStepsFromNetwork,
      fromCache: offline.getLocalDecisionSteps,
      saveToCache: offline.autoSaveDecisionSteps,
    );
  }

  // --- RÉFÉRENCES & DÉMARCHE SCIENTIFIQUE ---

  String getImageUrl(String imageId) => '$baseUrl/assets/$imageId?width=600&quality=80&fit=cover';

  Future<List<Reference>> getReferences(int plantId) async {
    try {
      final response = await _dio.get('/items/references', queryParameters: {
        'filter[plant][_eq]': plantId,
        'fields': 'id,full_reference',
      });
      return compute(_parseReferences, response.data['data']);
    } catch (e) {
      debugPrint("⚠️ Références réseau HS, retour cache local...");
      return OfflineService().getLocalReferencesForPlant(plantId);
    }
  }

  Future<List<Reference>> getAllReferences() async {
    final offline = OfflineService();
    return _cacheFirst(
      fromNetwork: () async {
        final response = await _dio.get('/items/references', queryParameters: {
          'fields': 'id,full_reference,plant.name',
          'sort': 'plant.name',
          'limit': -1,
        });
        return compute(_parseReferences, response.data['data']);
      },
      fromCache: offline.getLocalAllReferences,
      saveToCache: (refs) async => offline.autoSaveMethodology(
        allReferences: refs,
        genericReferences: await offline.getLocalGenericReferences(),
        pendingReferences: await offline.getLocalPendingReferences(),
      ),
    );
  }

  Future<List<GenericReference>> getGenericReferences() async {
    final offline = OfflineService();
    return _cacheFirst(
      fromNetwork: () async {
        final response = await _dio.get('/items/generic_references', queryParameters: {
          'fields': 'id,name',
          'sort': 'name',
          'limit': -1,
        });
        return compute(_parseGenericReferences, response.data['data']);
      },
      fromCache: offline.getLocalGenericReferences,
      saveToCache: (refs) async => offline.autoSaveMethodology(
        allReferences: await offline.getLocalAllReferences(),
        genericReferences: refs,
        pendingReferences: await offline.getLocalPendingReferences(),
      ),
    );
  }

  Future<List<PendingReference>> getPendingReferences() async {
    final offline = OfflineService();
    return _cacheFirst(
      fromNetwork: () async {
        final response = await _dio.get('/items/pending_references', queryParameters: {
          'fields': 'id,topic,claim,scientific_data',
          'sort': 'id',
          'limit': -1,
        });
        return compute(_parsePendingReferences, response.data['data']);
      },
      fromCache: offline.getLocalPendingReferences,
      saveToCache: (refs) async => offline.autoSaveMethodology(
        allReferences: await offline.getLocalAllReferences(),
        genericReferences: await offline.getLocalGenericReferences(),
        pendingReferences: refs,
      ),
    );
  }

  // --- TÉLÉCHARGEMENT MANUEL (mode hors ligne) ---

  Future<void> downloadPlants() async {
    final offline = OfflineService();
    final plants = await getPlantsFromNetwork();
    await offline.autoSavePlants(plants);

    if (await offline.shouldSaveImages()) {
      debugPrint("📸 Téléchargement images plantes...");
      for (var plant in plants) {
        if (plant.image != null) {
          try {
            final imageUrl = getImageUrl(plant.image!);
            await CachedNetworkImageProvider(imageUrl).evict();
            await DefaultCacheManager().downloadFile(imageUrl);
          } catch (e) { debugPrint("Err img ${plant.name}: $e"); }
        }
      }
    }
  }

  Future<void> downloadDecisionPaths() async {
    final offline = OfflineService();
    final results = await Future.wait([
      getSymptomsFromNetwork(),
      getDecisionStepsFromNetwork(),
    ]);
    final symptoms = results[0] as List<Symptom>;
    final steps = results[1] as List<DecisionStep>;
    await offline.autoSaveSymptoms(symptoms);
    await offline.autoSaveDecisionSteps(steps);

    if (await offline.shouldSaveImages()) {
      debugPrint("📸 Téléchargement images parcours...");
      for (var step in steps) {
        for (var plant in step.recommendedPlants) {
          if (plant.image != null) {
            try {
              final imageUrl = getImageUrl(plant.image!);
              await CachedNetworkImageProvider(imageUrl).evict();
              await DefaultCacheManager().downloadFile(imageUrl);
            } catch (e) { debugPrint("Err img parcours: $e"); }
          }
        }
      }
    }
  }

  Future<void> downloadMethodology() async {
    final offline = OfflineService();
    final results = await Future.wait([
      getAllReferences(),
      getGenericReferences(),
      getPendingReferences(),
    ]);
    await offline.autoSaveMethodology(
      allReferences: results[0] as List<Reference>,
      genericReferences: results[1] as List<GenericReference>,
      pendingReferences: results[2] as List<PendingReference>,
    );
  }
}