import 'package:flutter/material.dart';
import '../utils/string_utils.dart';
import 'dart:math';
import '../models/plant.dart';
import '../models/symptom.dart';
import '../screens/plant_detail_screen.dart';
import '../screens/decision_session_screen.dart';
import '../theme.dart';
import '../services/api_service.dart';

/// Résultat de recherche avec contexte et priorité (même logique que HomeScreen)
class _SearchResult {
  final dynamic item; // Plant ou Symptom
  final int tier;
  final String? matchField;
  final String? matchSnippet;

  _SearchResult({required this.item, required this.tier, this.matchField, this.matchSnippet});
}

class GlobalSearchDelegate extends SearchDelegate {
  final List<Plant> plants;
  final List<Symptom> symptoms;
  final ApiService _api = ApiService();

  GlobalSearchDelegate({required this.plants, required this.symptoms});

  @override
  String get searchFieldLabel => 'Plante, symptôme, maladie...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
        titleTextStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.tealDark : AppTheme.teal1),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String? _extractSnippet(String? text, String query) {
    if (text == null || text.isEmpty) return null;
    final normalized = removeDiacritics(text.toLowerCase());
    final idx = normalized.indexOf(query);
    if (idx == -1) return null;
    const radius = 40;
    final start = (idx - radius).clamp(0, text.length);
    final end = (idx + query.length + radius).clamp(0, text.length);
    final snippet = text.substring(start, end).replaceAll('\n', ' ').trim();
    return '${start > 0 ? '...' : ''}$snippet${end < text.length ? '...' : ''}';
  }

  String? _matchField(String? fieldValue, String query) {
    if (fieldValue == null || fieldValue.isEmpty) return null;
    final normalized = removeDiacritics(fieldValue.toLowerCase());
    return normalized.contains(query) ? _extractSnippet(fieldValue, query) : null;
  }

  // ── Recherche par tiers (même logique que HomeScreen) ───────────────────

  List<_SearchResult> _performSearch(String rawQuery) {
    final q = removeDiacritics(rawQuery.toLowerCase());
    if (q.length < 2) return [];

    final List<_SearchResult> results = [];
    final Set<int> addedPlantIds = {};

    // --- SYMPTÔMES ---
    // Tier 1 : nom
    // Tier 2 : description
    // Tier 3 : additionalInfo (ex: "angine" dans "Bon à savoir" du chemin Mal de gorge)
    for (final s in symptoms) {
      final nameMatch = removeDiacritics(s.name.toLowerCase()).contains(q);
      final descMatch = removeDiacritics((s.description ?? '').toLowerCase()).contains(q);
      final infoMatch = removeDiacritics((s.additionalInfo ?? '').toLowerCase()).contains(q);

      if (nameMatch) {
        results.add(_SearchResult(item: s, tier: 1));
      } else if (descMatch) {
        results.add(_SearchResult(item: s, tier: 2, matchField: "Description",
            matchSnippet: _extractSnippet(s.description, q)));
      } else if (infoMatch) {
        results.add(_SearchResult(item: s, tier: 3, matchField: "Bon à savoir",
            matchSnippet: _extractSnippet(s.additionalInfo, q)));
      }
    }

    // --- PLANTES Tier 1 : nom ---
    for (final p in plants) {
      if (removeDiacritics(p.name.toLowerCase()).contains(q)) {
        results.add(_SearchResult(item: p, tier: 1));
        addedPlantIds.add(p.id);
      }
    }

    // --- PLANTES Tier 2 : nom scientifique, noms communs, indications, habitat ---
    for (final p in plants) {
      if (addedPlantIds.contains(p.id)) continue;
      final sci = removeDiacritics((p.scientificName ?? '').toLowerCase());
      final common = removeDiacritics((p.commonNames ?? '').toLowerCase());
      final ailmentsJoined = p.ailments.map((a) => removeDiacritics(a.toLowerCase())).join(' ');
      final habitat = removeDiacritics((p.habitat ?? '').toLowerCase());

      if (sci.contains(q)) {
        results.add(_SearchResult(item: p, tier: 2, matchField: "Nom scientifique", matchSnippet: p.scientificName));
        addedPlantIds.add(p.id);
      } else if (common.contains(q)) {
        results.add(_SearchResult(item: p, tier: 2, matchField: "Noms communs",
            matchSnippet: _extractSnippet(p.commonNames, q)));
        addedPlantIds.add(p.id);
      } else if (ailmentsJoined.contains(q)) {
        final match = p.ailments.firstWhere(
            (a) => removeDiacritics(a.toLowerCase()).contains(q), orElse: () => '');
        results.add(_SearchResult(item: p, tier: 2, matchField: "Indication", matchSnippet: match));
        addedPlantIds.add(p.id);
      } else if (habitat.contains(q)) {
        results.add(_SearchResult(item: p, tier: 2, matchField: "Habitat", matchSnippet: p.habitat));
        addedPlantIds.add(p.id);
      }
    }

    // --- PLANTES Tier 3 : contenu complet (ex: "brûlure" dans description du Miel) ---
    final contentFields = <String, String? Function(Plant)>{
      'Description': (p) => p.descriptionShort,
      'Préparation': (p) => p.usagePreparation,
      'Durée': (p) => p.usageDuration,
      'Précautions': (p) => p.safetyPrecautions,
      'Effets secondaires': (p) => p.sideEffects,
      'Description visuelle': (p) => p.descriptionVisual,
      'Cueillette': (p) => p.procurementPicking,
      'Achat': (p) => p.procurementBuying,
      'Culture': (p) => p.procurementCulture,
      'Risques de confusion': (p) => p.confusionRisks,
      'Réf. scientifiques': (p) => p.scientificReferences,
    };

    for (final p in plants) {
      if (addedPlantIds.contains(p.id)) continue;
      for (final entry in contentFields.entries) {
        final snippet = _matchField(entry.value(p), q);
        if (snippet != null) {
          results.add(_SearchResult(item: p, tier: 3, matchField: entry.key, matchSnippet: snippet));
          addedPlantIds.add(p.id);
          break;
        }
      }
    }

    // Tri : tier 1 > 2 > 3 ; à tier égal, symptômes avant plantes
    results.sort((a, b) {
      if (a.tier != b.tier) return a.tier.compareTo(b.tier);
      final aIsSymptom = a.item is Symptom ? 0 : 1;
      final bIsSymptom = b.item is Symptom ? 0 : 1;
      return aIsSymptom.compareTo(bIsSymptom);
    });

    return results;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  Widget _buildSearchResults(BuildContext context) {
    if (query.trim().length < 2) return _buildEmptyState();

    final results = _performSearch(query.trim());

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("Aucun résultat pour \"$query\"",
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tealColor = isDark ? AppTheme.tealDark : AppTheme.teal1;

    // Séparer symptômes et plantes pour les headers de section
    final symptomResults = results.where((r) => r.item is Symptom).toList();
    final plantResults = results.where((r) => r.item is Plant).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // SECTION SYMPTÔMES
        if (symptomResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8, left: 4),
            child: Text("DIAGNOSTICS & GUIDES",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
          ),
          ...symptomResults.map((sr) {
            final s = sr.item as Symptom;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: isDark ? Colors.blue.withOpacity(0.1) : const Color(0xFFF0F9FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.withOpacity(0.2))),
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: cs.surface,
                    child: Icon(Icons.alt_route, color: isDark ? Colors.blue.shade300 : Colors.blue)),
                title: Text(s.name,
                    style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
                subtitle: sr.tier == 1
                    ? Text("Lancer le diagnostic",
                        style: TextStyle(
                            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                            fontSize: 12))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sr.matchField ?? "Diagnostic",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.blue.shade300 : Colors.blue,
                                  fontWeight: FontWeight.w600)),
                          if (sr.matchSnippet != null)
                            Text(sr.matchSnippet!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                    fontStyle: FontStyle.italic)),
                        ],
                      ),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => DecisionSessionScreen(symptom: s)));
                },
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        // SECTION PLANTES
        if (plantResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8, left: 4),
            child: Text("PLANTES & REMÈDES",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
          ),
          ...plantResults.map((sr) {
            final p = sr.item as Plant;
            final heroTag = 'search-plant-${p.id}';

            Widget subtitle;
            if (sr.tier == 1) {
              subtitle = Text(p.scientificName ?? '',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: cs.onSurfaceVariant));
            } else {
              subtitle = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sr.matchField ?? '',
                      style: TextStyle(fontSize: 11, color: tealColor, fontWeight: FontWeight.w600)),
                  if (sr.matchSnippet != null)
                    Text(sr.matchSnippet!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
                ],
              );
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isDark ? 0 : 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isDark ? BorderSide(color: cs.outlineVariant) : BorderSide.none),
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
                    image: p.image != null
                        ? DecorationImage(
                            image: NetworkImage(_api.getImageUrl(p.image!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: p.image == null
                      ? const Icon(Icons.local_florist, color: Colors.grey)
                      : null,
                ),
                title: Text(p.name,
                    style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
                subtitle: subtitle,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              PlantDetailScreen(plant: p, heroTag: heroTag)));
                },
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 80, color: Color(0xFFE0F2F1)),
          const SizedBox(height: 16),
          Text(
            "Recherchez un problème ou une plante",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }
}