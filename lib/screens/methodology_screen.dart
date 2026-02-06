import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/reference.dart';
import '../models/generic_reference.dart';
import '../models/plant.dart';
import '../models/pending_reference.dart';
import '../theme.dart';

class MethodologyScreen extends StatefulWidget {
  const MethodologyScreen({super.key});

  @override
  State<MethodologyScreen> createState() => _MethodologyScreenState();
}

class _MethodologyScreenState extends State<MethodologyScreen> {
  final ApiService _api = ApiService();
  
  // Contrôleur pour la liste des références (CORRECTION DE L'ERREUR)
  final ScrollController _referencesController = ScrollController();

  // Données
  List<Reference> _allReferences = [];
  List<GenericReference> _genericReferences = [];
  List<PendingReference> _pendingReferences = [];
  List<Plant> _plants = []; 
  
  // Filtres
  String _searchQuery = '';
  String _selectedPlantFilter = 'Tous les thèmes';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    // On n'oublie pas de nettoyer le contrôleur
    _referencesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final results = await Future.wait([
        _api.getPlants(),
        _api.getAllReferences(),
        _api.getGenericReferences(),
        _api.getPendingReferences(),
      ]);

      if (mounted) {
        setState(() {
          _plants = results[0] as List<Plant>;
          _allReferences = results[1] as List<Reference>;
          _genericReferences = results[2] as List<GenericReference>;
          _pendingReferences = results[3] as List<PendingReference>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur chargement: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logique de filtrage
  Map<String, List<Reference>> get _filteredGroupedReferences {
    final search = _searchQuery.toLowerCase();
    
    final filtered = _allReferences.where((ref) {
      final matchesPlant = _selectedPlantFilter == 'Tous les thèmes' || ref.plantName == _selectedPlantFilter;
      if (!matchesPlant) return false;
      if (search.isEmpty) return true;
      return ref.fullReference.toLowerCase().contains(search);
    });

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // --- 1. INTRO & FILTRES ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Découvrez notre démarche.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.teal1)),
                        const SizedBox(height: 16),
                        const Text(
                          "Les plantes présentées ont fait l'objet de recherches cliniques complètes.\n"
                          "Elles sont validées comme des médicaments conventionnels.",
                          style: TextStyle(fontSize: 16, height: 1.5, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 30),

                        const Text("Bibliographies particulières", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.teal2)),
                        const SizedBox(height: 16),
                        
                        // Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
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
                        
                        // Recherche
                        TextField(
                          decoration: InputDecoration(
                            hintText: "Rechercher un mot-clé...",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- 2. LISTE DES RÉFÉRENCES (CORRIGÉE) ---
                SliverToBoxAdapter(
                  child: Container(
                    height: 500,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: sortedKeys.isEmpty
                      ? const Center(child: Text("Aucune référence trouvée."))
                      : Scrollbar(
                          thumbVisibility: true,
                          controller: _referencesController, // <--- ICI (Liaison Scrollbar)
                          child: ListView.builder(
                            controller: _referencesController, // <--- ET ICI (Liaison ListView)
                            padding: const EdgeInsets.all(16),
                            itemCount: sortedKeys.length,
                            itemBuilder: (context, index) {
                              final key = sortedKeys[index];
                              final refs = groupedRefs[key]!;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.teal1)),
                                    const Divider(),
                                    ...refs.map((ref) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text("• ${ref.fullReference}", style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
                                    ))
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                  ),
                ),

                // --- 3. SECTION : ÉTUDES PROMETTEUSES ---
                if (_pendingReferences.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Études prometteuses (Hors fiches)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.teal2)),
                          SizedBox(height: 8),
                          Text("Ces plantes font l'objet d'études intéressantes mais n'ont pas encore de fiche dédiée.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _pendingReferences[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            color: const Color(0xFFF0FDFA),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.teal1.withOpacity(0.1))),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                
                                title: Text(
                                  item.topic,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.teal2, fontSize: 16),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.claim,
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark, fontSize: 14),
                                  ),
                                ),
                                children: [
                                  if (item.scientificData.isNotEmpty) ...[
                                    const Divider(height: 20),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Text(
                                        item.scientificData, 
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.blueGrey.shade900,
                                          height: 1.6,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Courier', 
                                        ),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _pendingReferences.length,
                      ),
                    ),
                  ),
                ],

                // --- 4. OUVRAGES GÉNÉRAUX ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        const Text("Ouvrages généraux", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.teal2)),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppTheme.teal1.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
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
                ),
              ],
            ),
    );
  }
}