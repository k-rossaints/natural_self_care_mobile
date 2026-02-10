import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/plant.dart';
import '../models/symptom.dart';
import '../models/decision_step.dart';
import '../models/reference.dart';
import '../models/generic_reference.dart';
import '../models/pending_reference.dart';
import 'offline_service.dart';

class ApiService {
  static const String baseUrl = 'http://directus-rk4w4cskcos4kwwoc84s88ss.46.224.187.154.sslip.io';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // --- PLANTES ---
  Future<List<Plant>> getPlantsFromNetwork() async {
    final response = await _dio.get('/items/plants', queryParameters: {
      'fields': 'id,name,slug,scientific_name,common_names,habitat,image,plant_type,description_short,is_clinically_validated,safety_precautions,side_effects,usage_preparation,usage_duration,description_visual,procurement_picking,procurement_buying,procurement_culture,confusion_risks,scientific_references,linked_ailments.ailments_id.name',
      'sort': 'name',
      'limit': -1,
    });
    return (response.data['data'] as List).map((json) => Plant.fromJson(json)).toList();
  }

  Future<List<Plant>> getPlants() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try { return await getPlantsFromNetwork(); } catch (e) { print("⚠️ API Plantes HS, passage offline..."); }
    }
    final local = await OfflineService().getLocalPlants();
    if (local.isNotEmpty) return local;
    throw Exception("Pas de connexion et pas de plantes sauvegardées.");
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
      } catch (_) { throw Exception("Détail plante introuvable hors ligne"); }
    }
  }

  // --- SYMPTÔMES & DÉCISIONS (NOUVEAU FALLBACK) ---

  // 1. Réseau forcé (pour le téléchargement)
  Future<List<Symptom>> getSymptomsFromNetwork() async {
    final response = await _dio.get('/items/symptoms', queryParameters: {
      'fields': 'id,name,description,additional_info,start_step',
      'sort': 'name',
      'limit': -1,
    });
    return (response.data['data'] as List).map((json) => Symptom.fromJson(json)).toList();
  }

  Future<List<DecisionStep>> getDecisionStepsFromNetwork() async {
    final response = await _dio.get('/items/decision_steps', queryParameters: {
      'fields': 'id,type,content,next_step_yes,next_step_no,is_emergency,recommended_remedies.plants_id.id,recommended_remedies.plants_id.name,recommended_remedies.plants_id.slug,recommended_remedies.plants_id.image,recommended_remedies.plants_id.is_clinically_validated',
      'limit': -1,
    });
    return (response.data['data'] as List).map((json) => DecisionStep.fromJson(json)).toList();
  }

  // 2. Méthode intelligente (Appelée par l'appli)
  Future<List<Symptom>> getSymptoms() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try { return await getSymptomsFromNetwork(); } catch (e) { print("⚠️ API Symptômes HS, passage offline..."); }
    }
    final local = await OfflineService().getLocalSymptoms();
    if (local.isNotEmpty) return local;
    throw Exception("Pas de connexion et pas de symptômes sauvegardés.");
  }

  Future<List<DecisionStep>> getDecisionSteps() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      try { return await getDecisionStepsFromNetwork(); } catch (e) { print("⚠️ API Steps HS, passage offline..."); }
    }
    final local = await OfflineService().getLocalDecisionSteps();
    if (local.isNotEmpty) return local;
    throw Exception("Pas de connexion et pas de parcours sauvegardés.");
  }

  // --- AUTRES (Pas de offline pour l'instant) ---
  String getImageUrl(String imageId) => '$baseUrl/assets/$imageId?width=600&quality=80&fit=cover';
  
  Future<List<Reference>> getReferences(int plantId) async {
    try {
      final response = await _dio.get('/items/references', queryParameters: {'filter[plant][_eq]': plantId, 'fields': 'id,full_reference'});
      return (response.data['data'] as List).map((json) => Reference.fromJson(json)).toList();
    } catch (e) { return []; }
  }
  
  Future<List<Reference>> getAllReferences() async {
    try {
      final response = await _dio.get('/items/references', queryParameters: {'fields': 'id,full_reference,plant.name', 'sort': 'plant.name', 'limit': -1});
      return (response.data['data'] as List).map((json) => Reference.fromJson(json)).toList();
    } catch (e) { return []; }
  }

  Future<List<GenericReference>> getGenericReferences() async {
    try {
      final response = await _dio.get('/items/generic_references', queryParameters: {'fields': 'id,name', 'sort': 'name', 'limit': -1});
      return (response.data['data'] as List).map((json) => GenericReference.fromJson(json)).toList();
    } catch (e) { return []; }
  }

  Future<List<PendingReference>> getPendingReferences() async {
    try {
      final response = await _dio.get('/items/pending_references', queryParameters: {'fields': 'id,topic,claim,scientific_data', 'sort': 'id', 'limit': -1});
      return (response.data['data'] as List).map((json) => PendingReference.fromJson(json)).toList();
    } catch (e) { return []; }
  }
}