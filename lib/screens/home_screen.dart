import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/string_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/plant.dart';
import '../models/symptom.dart';
import '../providers/plants_provider.dart';
import '../providers/symptoms_provider.dart';
import 'plant_detail_screen.dart';
import 'decision_session_screen.dart';

/// Résultat de recherche avec contexte et priorité
class _SearchResult {
  final dynamic item; // Plant ou Symptom
  final int tier; // 1=nom, 2=métadonnées, 3=contenu complet
  final String? matchField; // Ex: "Préparation", "Effets secondaires"
  final String? matchSnippet; // Ex: "...une cuillère à café de..."

  _SearchResult({required this.item, required this.tier, this.matchField, this.matchSnippet});
}

class HomeScreen extends ConsumerStatefulWidget {
  final Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ApiService _api = ApiService();

  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _launchPartnerUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Erreur ouverture lien partenaire: $e");
    }
  }

  void _onSearchChanged(String query, List<Plant> plants, List<Symptom> symptoms) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().length >= 2) _performSearch(query, plants, symptoms);
    });
  }

  /// Extrait un snippet de ~60 caractères autour de la première occurrence du mot
  String? _extractSnippet(String? text, String query) {
    if (text == null || text.isEmpty) return null;
    final normalized = removeDiacritics(text.toLowerCase());
    final idx = normalized.indexOf(query);
    if (idx == -1) return null;

    const radius = 30;
    final start = (idx - radius).clamp(0, text.length);
    final end = (idx + query.length + radius).clamp(0, text.length);
    final snippet = text.substring(start, end).replaceAll('\n', ' ').trim();
    return '${start > 0 ? '...' : ''}$snippet${end < text.length ? '...' : ''}';
  }

  /// Cherche dans un champ texte ; retourne le snippet si trouvé
  String? _matchField(String? fieldValue, String query) {
    if (fieldValue == null || fieldValue.isEmpty) return null;
    final normalized = removeDiacritics(fieldValue.toLowerCase());
    return normalized.contains(query) ? _extractSnippet(fieldValue, query) : null;
  }

  void _performSearch(String query, List<Plant> plants, List<Symptom> symptoms) {
    final q = removeDiacritics(query.toLowerCase());
    final List<_SearchResult> results = [];
    final Set<int> addedPlantIds = {};

    // --- SYMPTÔMES (chemins de décision) ---
    for (final s in symptoms) {
      final nameMatch = removeDiacritics(s.name.toLowerCase()).contains(q);
      final descMatch = removeDiacritics((s.description ?? '').toLowerCase()).contains(q);
      final infoMatch = removeDiacritics((s.additionalInfo ?? '').toLowerCase()).contains(q);
      if (nameMatch) {
        results.add(_SearchResult(item: s, tier: 1));
      } else if (descMatch) {
        results.add(_SearchResult(item: s, tier: 2, matchField: "Description", matchSnippet: _extractSnippet(s.description, q)));
      } else if (infoMatch) {
        results.add(_SearchResult(item: s, tier: 3, matchField: "Bon à savoir", matchSnippet: _extractSnippet(s.additionalInfo, q)));
      }
    }

    // --- PLANTES : recherche par tiers de priorité ---
    // Tier 1 : nom exact
    for (final p in plants) {
      final name = removeDiacritics(p.name.toLowerCase());
      if (name.contains(q)) {
        results.add(_SearchResult(item: p, tier: 1));
        addedPlantIds.add(p.id);
      }
    }

    // Tier 2 : nom scientifique, noms communs, symptômes/indications
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
        results.add(_SearchResult(item: p, tier: 2, matchField: "Noms communs", matchSnippet: _extractSnippet(p.commonNames, q)));
        addedPlantIds.add(p.id);
      } else if (ailmentsJoined.contains(q)) {
        final match = p.ailments.firstWhere((a) => removeDiacritics(a.toLowerCase()).contains(q), orElse: () => '');
        results.add(_SearchResult(item: p, tier: 2, matchField: "Indication", matchSnippet: match));
        addedPlantIds.add(p.id);
      } else if (habitat.contains(q)) {
        results.add(_SearchResult(item: p, tier: 2, matchField: "Habitat", matchSnippet: p.habitat));
        addedPlantIds.add(p.id);
      }
    }

    // Tier 3 : contenu complet (descriptions, préparation, effets secondaires, etc.)
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
          break; // un seul résultat par plante
        }
      }
    }

    // Tri : tier 1 d'abord, puis 2, puis 3. À tier égal, symptômes avant plantes.
    results.sort((a, b) {
      if (a.tier != b.tier) return a.tier.compareTo(b.tier);
      final aIsSymptom = a.item is Symptom ? 0 : 1;
      final bIsSymptom = b.item is Symptom ? 0 : 1;
      return aIsSymptom.compareTo(bIsSymptom);
    });

    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }
  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);
    final symptomsAsync = ref.watch(symptomsProvider);

    // On récupère les données des providers (listes vides si pas encore chargé)
    final plants = plantsAsync.asData?.value ?? [];
    final symptoms = symptomsAsync.asData?.value ?? [];

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          _searchFocus.unfocus();
          setState(() => _isSearching = false);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER VERT COMPLET
              Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.teal1, AppTheme.teal2],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Se soigner avec des\nremèdes naturels",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Une base de connaissances fiable sur les plantes médicinales validées par des études cliniques.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9), height: 1.4),
                    ),

                    const SizedBox(height: 30),

                    // BARRE DE RECHERCHE
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        onChanged: (val) => _onSearchChanged(val, plants, symptoms),
                        decoration: InputDecoration(
                          hintText: "Rechercher une plante, un mal...",
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search, color: AppTheme.teal1),
                          suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () { _searchController.clear(); _onSearchChanged('', plants, symptoms); FocusScope.of(context).unfocus(); })
                            : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // RÉSULTATS DE RECHERCHE
              if (_isSearching && _searchController.text.length >= 2)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _searchResults.isEmpty
                      ? Padding(padding: const EdgeInsets.all(20), child: Text("Aucun résultat trouvé.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                          itemBuilder: (context, index) => _buildResultItem(_searchResults[index]),
                        ),
                  ),
                ),

              const SizedBox(height: 20),

              // BOUTONS D'ACTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildNavCard(
                      icon: Icons.local_florist_outlined,
                      title: "Explorer les remèdes",
                      subtitle: "Rechercher par plante, usage et preuves.",
                      color: AppTheme.teal1,
                      onTap: () => widget.onTabChange(1),
                    ),
                    const SizedBox(height: 16),
                    _buildNavCard(
                      icon: Icons.alt_route_outlined,
                      title: "Chemins de décision",
                      subtitle: "Trouver une solution selon vos symptômes.",
                      color: AppTheme.teal1,
                      onTap: () => widget.onTabChange(2),
                    ),
                    const SizedBox(height: 16),
                    _buildNavCard(
                      icon: Icons.menu_book_outlined,
                      title: "Index des problèmes",
                      subtitle: "Liste de A à Z des pathologies traitées.",
                      color: AppTheme.teal1,
                      onTap: () => widget.onTabChange(3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // PARTENAIRES (Mise à jour avec URLs)
              Center(child: Text("NOS PARTENAIRES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.5))),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 15, runSpacing: 15, alignment: WrapAlignment.center,
                  children: [
                    _buildPartnerLogo('assets/partner1.jpg', 'https://www.ox.ac.uk/'),
                    _buildPartnerLogo('assets/partner2.jpg', 'https://www.ugb.sn/'),
                    _buildPartnerLogo('assets/partner3.jpg', 'https://www.nybg.org/'),
                    _buildPartnerLogo('assets/partner4.jpg', 'https://uog.edu.et/'),
                    _buildPartnerLogo('assets/partner5.jpg', 'https://www.unige.ch/'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(_SearchResult sr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tealColor = isDark ? AppTheme.tealDark : AppTheme.teal1;
    final cs = Theme.of(context).colorScheme;

    if (sr.item is Plant) {
      final plant = sr.item as Plant;
      final heroTag = 'home-plant-${plant.id}';

      // Sous-titre adaptatif : montre le champ correspondant pour le tier 2-3
      Widget subtitle;
      if (sr.tier == 1) {
        subtitle = Text("Plante", style: TextStyle(fontSize: 12, color: tealColor));
      } else {
        subtitle = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sr.matchField ?? "Plante", style: TextStyle(fontSize: 11, color: tealColor, fontWeight: FontWeight.w600)),
            if (sr.matchSnippet != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  sr.matchSnippet!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        );
      }

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Hero(
          tag: heroTag,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: plant.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_api.getImageUrl(plant.image!), fit: BoxFit.cover),
                  )
                : const Icon(Icons.local_florist, size: 20, color: Colors.grey),
          ),
        ),
        title: Text(plant.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cs.onSurface)),
        subtitle: subtitle,
        trailing: Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
        onTap: () {
          _searchFocus.unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: plant, heroTag: heroTag)),
          );
        },
      );
    } else if (sr.item is Symptom) {
      final symptom = sr.item as Symptom;

      Widget subtitle;
      if (sr.tier == 1) {
        subtitle = Text("Diagnostic interactif", style: TextStyle(fontSize: 12, color: isDark ? Colors.blue.shade300 : Colors.blue));
      } else {
        subtitle = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sr.matchField ?? "Diagnostic", style: TextStyle(fontSize: 11, color: isDark ? Colors.blue.shade300 : Colors.blue, fontWeight: FontWeight.w600)),
            if (sr.matchSnippet != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  sr.matchSnippet!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        );
      }

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Icon(Icons.alt_route, size: 20, color: isDark ? Colors.blue.shade300 : Colors.blue),
        title: Text(symptom.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cs.onSurface)),
        subtitle: subtitle,
        trailing: Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
        onTap: () {
          _searchFocus.unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DecisionSessionScreen(symptom: symptom)),
          );
        },
      );
    }
    return const SizedBox();
  }

  Widget _buildNavCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final displayColor = isDark ? (color == AppTheme.teal1 ? AppTheme.tealDark : cs.onSurface) : color;
    return Card(elevation: isDark ? 0 : 4, shadowColor: color.withOpacity(0.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: isDark ? BorderSide(color: cs.outlineVariant) : BorderSide.none), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: displayColor.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, color: displayColor, size: 28)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: displayColor)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))])), Icon(Icons.chevron_right, color: cs.onSurfaceVariant)]))));
  }

  // MODIFICATION ICI : On accepte l'URL et on utilise InkWell pour le clic
  Widget _buildPartnerLogo(String assetPath, String url) {
    return InkWell(
      onTap: () => _launchPartnerUrl(url),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        width: 100,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10)
        ), 
        child: Image.asset(assetPath, fit: BoxFit.contain)
      ),
    );
  }
}