import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/reference.dart';
import '../models/generic_reference.dart';
import '../models/plant.dart';
import '../theme.dart';

class MethodologyScreen extends StatefulWidget {
  const MethodologyScreen({super.key});

  @override
  State<MethodologyScreen> createState() => _MethodologyScreenState();
}

class _MethodologyScreenState extends State<MethodologyScreen> {
  final ApiService _api = ApiService();
  
  // Données
  List<Reference> _allReferences = [];
  List<GenericReference> _genericReferences = [];
  List<Plant> _plants = []; // Pour le filtre
  
  // Filtres
  String _searchQuery = '';
  String _selectedPlantFilter = 'Tous les thèmes';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final plants = await _api.getPlants();
      final refs = await _api.getAllReferences();
      final genRefs = await _api.getGenericReferences();

      if (mounted) {
        setState(() {
          _plants = plants;
          _allReferences = refs;
          _genericReferences = genRefs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logique de filtrage (similaire à VueJS)
  Map<String, List<Reference>> get _filteredGroupedReferences {
    // 1. Filtrer par texte et par plante
    final filtered = _allReferences.where((ref) {
      final matchesSearch = _searchQuery.isEmpty || 
          ref.fullReference.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final plantName = ref.plantName ?? "Sans plante";
      final matchesPlant = _selectedPlantFilter == 'Tous les thèmes' || 
          plantName == _selectedPlantFilter;

      return matchesSearch && matchesPlant;
    }).toList();

    // 2. Grouper par nom de plante
    final Map<String, List<Reference>> grouped = {};
    for (var ref in filtered) {
      final key = ref.plantName ?? "Sans plante";
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(ref);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedRefs = _filteredGroupedReferences;
    final sortedKeys = groupedRefs.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text("Démarche scientifique")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- INTRO ---
                  const Text("Découvrez notre démarche.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.teal1)),
                  const SizedBox(height: 16),
                  const Text(
                    "Les plantes présentées ont fait l'objet de recherches cliniques complètes.\n"
                    "Elles sont validées comme des médicaments conventionnels et sont capables de rivaliser, preuves à l’appui, avec des traitements de synthèse.",
                    style: TextStyle(fontSize: 16, height: 1.5, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 30),

                  // --- FILTRES ---
                  const Text("Bibliographies particulières", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.teal2)),
                  const SizedBox(height: 16),
                  
                  // Filtre Plante (Dropdown)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedPlantFilter,
                        icon: const Icon(Icons.filter_list, color: AppTheme.teal1),
                        items: [
                          const DropdownMenuItem(value: 'Tous les thèmes', child: Text('Tous les thèmes')),
                          ..._plants.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))),
                        ],
                        onChanged: (val) => setState(() => _selectedPlantFilter = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Filtre Recherche
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Rechercher un mot-clé...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),

                  const SizedBox(height: 24),

                  // --- RÉSULTATS (Liste groupée) ---
                  if (sortedKeys.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text("Aucune référence trouvée.")),
                    )
                  else
                    ...sortedKeys.map((key) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.teal1)),
                              const Divider(),
                              ...groupedRefs[key]!.map((ref) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text("• ${ref.fullReference}", style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
                              ))
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 40),

                  // --- OUVRAGES GÉNÉRAUX ---
                  const Text("Ouvrages généraux", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.teal2)),
                  const SizedBox(height: 8),
                  const Text("Ces ouvrages constituent une base méthodologique générale.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.teal1.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _genericReferences.isEmpty 
                        ? [const Text("Aucun ouvrage chargé.")]
                        : _genericReferences.map((g) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.book, size: 16, color: AppTheme.teal1),
                                const SizedBox(width: 10),
                                Expanded(child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w500, height: 1.4))),
                              ],
                            ),
                          )).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}