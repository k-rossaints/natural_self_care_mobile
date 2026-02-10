import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // <--- NOUVEL IMPORT
import '../models/plant.dart';
import '../models/decision_step.dart';
import '../models/symptom.dart';
import 'api_service.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // Clés
  static const String KEY_PLANTS = 'offline_plants';
  static const String KEY_SYMPTOMS = 'offline_symptoms';
  static const String KEY_STEPS = 'offline_steps';
  static const String KEY_SAVE_IMAGES = 'offline_settings_images';
  static const String KEY_LAST_SYNC = 'offline_last_sync';

  // --- 1. Gestion des Réglages ---

  Future<void> setSaveImages(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KEY_SAVE_IMAGES, value);
  }

  Future<bool> shouldSaveImages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_SAVE_IMAGES) ?? false; 
  }

  Future<void> _updateSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    // Format simple : JJ/MM/AAAA HH:MM
    String formattedDate = "${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2,'0')}";
    await prefs.setString(KEY_LAST_SYNC, formattedDate);
  }

  Future<String?> getLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_LAST_SYNC);
  }

  // --- 2. Sauvegarde (Le gros morceau) ---

  Future<void> downloadPlants() async {
    final api = ApiService(); 
    
    // 1. On récupère les données fraîches depuis le réseau
    // (Assure-toi que getPlantsFromNetwork existe dans api_service, sinon utilise getPlants)
    final plants = await api.getPlantsFromNetwork(); 
    
    // 2. On sauvegarde le texte (JSON)
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(plants.map((p) => p.toJson()).toList());
    await prefs.setString(KEY_PLANTS, jsonString);
    await _updateSyncDate();

    // 3. GESTION DES IMAGES (C'est ici que ça se joue)
    if (await shouldSaveImages()) {
      print("📸 Option Images ACTIVE : Téléchargement en cours...");
      for (var plant in plants) {
        if (plant.image != null) {
          try {
            final url = api.getImageUrl(plant.image!);
            // On force le téléchargement du fichier dans le cache du téléphone
            await DefaultCacheManager().downloadFile(url);
          } catch (e) {
            print("Erreur téléchargement image ${plant.name}: $e");
          }
        }
      }
    } else {
      print("⏩ Option Images DÉSACTIVÉE : On ne télécharge rien.");
    }
  }

  Future<void> downloadDecisionPaths() async {
    final api = ApiService();
    final symptoms = await api.getSymptoms(); // Assure-toi que ces méthodes existent dans ApiService
    final steps = await api.getDecisionSteps();

    final prefs = await SharedPreferences.getInstance();
    // On suppose que tu as ajouté toJson() dans Symptom et DecisionStep aussi
    // Si ce n'est pas le cas, commente ces deux lignes pour l'instant
    // await prefs.setString(KEY_SYMPTOMS, jsonEncode(symptoms.map((s) => s.toJson()).toList()));
    // await prefs.setString(KEY_STEPS, jsonEncode(steps.map((s) => s.toJson()).toList()));
  }

  // --- 3. Lecture ---
  
  Future<List<Plant>> getLocalPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(KEY_PLANTS);
    if (data == null) return [];
    final List<dynamic> decodedData = jsonDecode(data);
    return decodedData.map((json) => Plant.fromJson(json)).toList();
  }

  // --- 4. Nettoyage ---

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_PLANTS);
    await prefs.remove(KEY_SYMPTOMS);
    await prefs.remove(KEY_STEPS);
    await prefs.remove(KEY_LAST_SYNC);
    
    // On vide aussi le cache des images pour libérer la place
    await DefaultCacheManager().emptyCache();
    print("🗑️ Données locales et cache images supprimés.");
  }
}