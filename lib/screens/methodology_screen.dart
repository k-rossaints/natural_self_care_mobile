import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/reference.dart';
import '../models/generic_reference.dart';
import '../models/plant.dart';
import '../models/pending_reference.dart';
import '../theme.dart';
import '../widgets/expandable_text.dart';
import '../widgets/error_view.dart';

class MethodologyScreen extends StatefulWidget {
  const MethodologyScreen({super.key});

  @override
  State<MethodologyScreen> createState() => _MethodologyScreenState();
}

class _MethodologyScreenState extends State<MethodologyScreen> {
  final ApiService _api = ApiService();
  final ScrollController _referencesController = ScrollController();

  List<Reference> _allReferences = [];
  List<GenericReference> _genericReferences = [];
  List<PendingReference> _pendingReferences = [];
  List<Plant> _plants = [];

  String _searchQuery = '';
  String _selectedPlantFilter = 'Tous les themes';

  bool _loadingFilters = true;
  bool _loadingRefs = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _referencesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _loadingFilters = true; _loadingRefs = true; _hasError = false; });

    _api.getPlants().then((plants) {
      if (mounted) setState(() => _plants = plants);
    }).catchError((e) => debugPrint(e.toString()));

    _api.getGenericReferences().then((gens) {
      if (mounted) setState(() => _genericReferences = gens);
    }).catchError((e) => debugPrint(e.toString()));

    _api.getPendingReferences().then((pending) {
      if (mounted) {
        setState(() {
          _pendingReferences = pending;
          _loadingFilters = false;
        });
      }
    }).catchError((e) {
      if (mounted) setState(() { _loadingFilters = false; _hasError = true; });
    });

    _api.getAllReferences().then((refs) {
      if (mounted) {
        setState(() {
          _allReferences = refs;
          _loadingRefs = false;
        });
      }
    }).catchError((e) {
      if (mounted) setState(() { _loadingRefs = false; _hasError = true; });
    });
  }

  Map<String, List<Reference>> get _filteredGroupedReferences {
    final search = _searchQuery.toLowerCase();
    final filtered = _allReferences.where((ref) {
      final matchesPlant = _selectedPlantFilter == 'Tous les themes' ||
          ref.plantName == _selectedPlantFilter;
      if (!matchesPlant) return false;
      if (search.isEmpty) return true;
      return ref.fullReference.toLowerCase().contains(search);
    });
    final Map<String, List<Reference>> grouped = {};
    for (var ref in filtered) {
      final key = ref.plantName ?? 'Sans plante';
      grouped.putIfAbsent(key, () => []).add(ref);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedRefs = _filteredGroupedReferences;
    final sortedKeys = groupedRefs.keys.toList()..sort();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Démarche scientifique')),
      body: _hasError && _allReferences.isEmpty && _pendingReferences.isEmpty && _genericReferences.isEmpty
          ? ErrorView(isOffline: true, onRetry: _loadData)
          : CustomScrollView(
        slivers: [
          // INTRO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Decouvrez notre démarche.',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? AppTheme.tealDark : AppTheme.teal1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Les plantes présentées dans les fiches ont fait l'objet de recherches cliniques complètes et rigoureuses.",
                    style: TextStyle(fontSize: 16, height: 1.5, color: cs.onSurface),
                  ),
                  const SizedBox(height: 30),
                  Text('Bibliographies particulières',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppTheme.tealDark : AppTheme.teal2)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant)),
                    child: _loadingFilters && _plants.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedPlantFilter,
                              dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
                              icon: Icon(Icons.filter_list, color: isDark ? AppTheme.tealDark : AppTheme.teal1),
                              style: TextStyle(color: cs.onSurface, fontSize: 14),
                              items: [
                                DropdownMenuItem(value: 'Tous les themes', child: Text('Tous les themes', style: TextStyle(color: cs.onSurface))),
                                ..._plants.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name, style: TextStyle(color: cs.onSurface)))),
                              ],
                              onChanged: (val) => setState(() => _selectedPlantFilter = val!),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un mot-clé...',
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkCard : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: TextStyle(color: cs.onSurface),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ],
              ),
            ),
          ),

          // REFERENCES EN ACCORDEONS
          if (_loadingRefs)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Chargement des references...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                ),
              ),
            )
          else if (sortedKeys.isEmpty)
            SliverToBoxAdapter(
              child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('Aucune reference trouvee.', style: TextStyle(color: cs.onSurfaceVariant)))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ReferenceAccordion(
                    plantName: sortedKeys[index],
                    references: groupedRefs[sortedKeys[index]]!,
                  ),
                  childCount: sortedKeys.length,
                ),
              ),
            ),

          // ETUDES PROMETTEUSES
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Etudes prometteuses (Hors fiches)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppTheme.tealDark : AppTheme.teal2)),
                const SizedBox(height: 8),
                Text("Ces plantes font l'objet d'etudes interessantes mais n'ont pas encore de fiche dediee.",
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ]),
            ),
          ),

          if (_loadingFilters && _pendingReferences.isEmpty)
            const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _pendingReferences[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: isDark ? AppTheme.teal1.withOpacity(0.08) : const Color(0xFFF0FDFA),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: (isDark ? AppTheme.tealDark : AppTheme.teal1).withOpacity(0.2))),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          title: Text(item.topic,
                              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppTheme.tealDark : AppTheme.teal2, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: ExpandableText(
                              text: item.claim,
                              maxLines: 2,
                              style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface, fontSize: 14),
                            ),
                          ),
                          children: [
                            if (item.scientificData.isNotEmpty) ...[
                              const Divider(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? cs.surfaceContainerHighest : Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: cs.outlineVariant),
                                ),
                                child: SelectableText(
                                  item.scientificData,
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: cs.onSurface,
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Courier'),
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

          // OUVRAGES GENERAUX
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 30),
                Text('Ouvrages generaux',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppTheme.tealDark : AppTheme.teal2)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: (isDark ? AppTheme.tealDark : AppTheme.teal1).withOpacity(isDark ? 0.08 : 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: isDark ? Border.all(color: cs.outlineVariant) : null),
                  child: _loadingFilters && _genericReferences.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _genericReferences.isEmpty
                              ? [Text('Aucun ouvrage charge.', style: TextStyle(color: cs.onSurfaceVariant))]
                              : _genericReferences
                                  .map((g) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Icon(Icons.book, size: 16, color: isDark ? AppTheme.tealDark : AppTheme.teal1),
                                          const SizedBox(width: 10),
                                          Expanded(
                                              child: SelectableText(g.name,
                                                  style: TextStyle(fontWeight: FontWeight.w500, height: 1.4, color: cs.onSurface))),
                                        ]),
                                      ))
                                  .toList(),
                        ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceAccordion extends StatelessWidget {
  final String plantName;
  final List<Reference> references;

  const _ReferenceAccordion({required this.plantName, required this.references});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(plantName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppTheme.tealDark : AppTheme.teal1)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: (isDark ? AppTheme.tealDark : AppTheme.teal1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Text('${references.length} ref.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppTheme.tealDark : AppTheme.teal1)),
          ),
          children: references
              .map((ref) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('- ', style: TextStyle(color: cs.onSurfaceVariant)),
                      Expanded(
                        child: SelectableText(ref.fullReference,
                            style: TextStyle(fontSize: 13, height: 1.4, color: cs.onSurface)),
                      ),
                    ]),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
