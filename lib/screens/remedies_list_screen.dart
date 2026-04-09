import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plant.dart';
import '../utils/string_utils.dart';
import '../providers/plants_provider.dart';
import '../widgets/plant_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/error_view.dart';
import 'plant_detail_screen.dart';
import '../theme.dart';

const int _pageSize = 10;

class RemediesListScreen extends ConsumerStatefulWidget {
  const RemediesListScreen({super.key});

  @override
  ConsumerState<RemediesListScreen> createState() => _RemediesListScreenState();
}

class _RemediesListScreenState extends ConsumerState<RemediesListScreen> {
  List<Plant> _allFilteredPlants = [];
  List<Plant> _displayedPlants = [];
  List<String> _availableAilments = [];
  List<String> _availableHabitats = [];

  String _searchQuery = '';
  String? _selectedAilment;
  String? _selectedHabitat;

  int _currentPage = 1;
  bool _hasMore = false;

  Timer? _debounce;
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (!_hasMore) return;
    setState(() {
      _currentPage++;
      final end = min(_currentPage * _pageSize, _allFilteredPlants.length);
      _displayedPlants = _allFilteredPlants.sublist(0, end);
      _hasMore = end < _allFilteredPlants.length;
    });
  }

  void _initFromPlants(List<Plant> plants) {
    if (_initialized) return;
    _initialized = true;
    final Set<String> ailmentsSet = {};
    final Set<String> habitatsSet = {};
    for (var p in plants) {
      ailmentsSet.addAll(p.ailments);
      if (p.habitat != null) {
        final clean = p.habitat!.trim();
        if (clean.isNotEmpty) habitatsSet.add(clean);
      }
    }
    _availableAilments = ailmentsSet.toList()..sort();
    _availableHabitats = habitatsSet.toList()..sort();
    _applyFilters(plants);
  }

  void _applyFilters(List<Plant> allPlants) {
    final filtered = allPlants.where((plant) {
      if (_selectedHabitat != null && plant.habitat?.trim() != _selectedHabitat) return false;
      if (_selectedAilment != null && !plant.ailments.contains(_selectedAilment)) return false;
      if (_searchQuery.isEmpty) return true;
      return _fuzzyMatch(plant.name, _searchQuery) ||
          _fuzzyMatch(plant.scientificName ?? '', _searchQuery) ||
          (plant.habitat != null && _fuzzyMatch(plant.habitat!, _searchQuery)) ||
          plant.ailments.any((a) => _fuzzyMatch(a, _searchQuery));
    }).toList();

    _currentPage = 1;
    _allFilteredPlants = filtered;
    final end = min(_pageSize, filtered.length);
    _displayedPlants = filtered.sublist(0, end);
    _hasMore = filtered.length > _pageSize;
  }

  bool _fuzzyMatch(String source, String query) {
    if (query.isEmpty) return true;
    final s = removeDiacritics(source.toLowerCase());
    final q = removeDiacritics(query.toLowerCase());
    if (s.contains(q)) return true;
    for (var word in s.split(' ')) {
      if (_levenshtein(word, q) <= 2) return true;
    }
    return false;
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);
    for (int i = 0; i < t.length + 1; i++) v0[i] = i;
    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < t.length + 1; j++) v0[j] = v1[j];
    }
    return v1[t.length];
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: plantsAsync.when(
        loading: () => const SingleChildScrollView(
          child: Column(children: [SizedBox(height: 240), PlantListSkeleton(count: 6)]),
        ),
        error: (e, _) => ErrorView(isOffline: true, onRetry: () => ref.refresh(plantsProvider)),
        data: (plants) {
          if (!_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _initFromPlants(plants));
            });
            return const PlantListSkeleton(count: 6);
          }

          return CustomScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // EN-TÊTE
              SliverAppBar(
                expandedHeight: 80.0,
                floating: false,
                pinned: false,
                backgroundColor: bgColor,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  centerTitle: false,
                  title: Text("Explorer les remèdes", style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 24)),
                ),
              ),

              // FILTRES
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyFilterHeaderDelegate(
                  child: Container(
                    color: bgColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: isDark ? Border.all(color: const Color(0xFF3A3A3A)) : null,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.08), blurRadius: isDark ? 4 : 10, offset: const Offset(0, 2))],
                          ),
                          child: TextField(
                            focusNode: _searchFocus,
                            style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark),
                            onChanged: (val) {
                              _searchQuery = val;
                              if (_debounce?.isActive ?? false) _debounce!.cancel();
                              _debounce = Timer(const Duration(milliseconds: 300), () {
                                setState(() => _applyFilters(plants));
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Plante, symptôme, habitat...",
                              hintStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade400, fontSize: 14),
                              prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.tealDark : AppTheme.teal1),
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _buildDropdown(context, hint: "Symptôme", value: _selectedAilment, items: _availableAilments, icon: Icons.medical_services_outlined, onChanged: (val) { setState(() { _selectedAilment = val; _applyFilters(plants); }); })),
                          const SizedBox(width: 10),
                          Expanded(child: _buildDropdown(context, hint: "Zone géo", value: _selectedHabitat, items: _availableHabitats, icon: Icons.public, onChanged: (val) { setState(() { _selectedHabitat = val; _applyFilters(plants); }); })),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          "${_allFilteredPlants.length} plante${_allFilteredPlants.length > 1 ? 's' : ''} trouvée${_allFilteredPlants.length > 1 ? 's' : ''}",
                          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  maxHeight: 160,
                  minHeight: 160,
                ),
              ),

              // RÉSULTATS
              _displayedPlants.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Column(children: [
                          Icon(Icons.search_off, size: 50, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text("Aucun résultat", style: TextStyle(color: Colors.grey.shade500)),
                        ]),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _displayedPlants.length) {
                            // Indicateur de chargement pagination
                            return _hasMore
                                ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: AppTheme.teal1)))
                                : Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(child: Text("${_allFilteredPlants.length} plantes affichées", style: const TextStyle(color: Colors.grey, fontSize: 13))),
                                  );
                          }
                          return PlantCard(
                            plant: _displayedPlants[index],
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (context) => PlantDetailScreen(plant: _displayedPlants[index], heroTag: 'remedies-plant-${_displayedPlants[index].id}'),
                            )),
                          );
                        },
                        childCount: _displayedPlants.length + 1,
                      ),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, {required String hint, required String? value, required List<String> items, required IconData icon, required Function(String?) onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tealColor = isDark ? AppTheme.tealDark : AppTheme.teal1;
    final isEmpty = items.isEmpty;
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: value != null ? tealColor.withOpacity(isDark ? 0.15 : 0.1) : (isDark ? AppTheme.darkCard : (isEmpty ? Colors.grey.shade100 : Colors.white)),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: value != null ? tealColor : (isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
          hint: Row(children: [Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 8), Text(isEmpty ? "(Vide)" : hint, style: const TextStyle(fontSize: 13, color: Colors.grey))]),
          icon: value != null ? GestureDetector(onTap: () => onChanged(null), child: Icon(Icons.close, size: 18, color: tealColor)) : Icon(Icons.arrow_drop_down, color: isEmpty ? Colors.grey.shade300 : Colors.grey),
          isExpanded: true,
          style: TextStyle(color: value != null ? tealColor : (isDark ? AppTheme.darkTextPrimary : Colors.black87), fontWeight: FontWeight.w600, fontSize: 13),
          items: isEmpty ? null : items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

class _StickyFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double maxHeight;
  final double minHeight;
  _StickyFilterHeaderDelegate({required this.child, required this.maxHeight, required this.minHeight});
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => SizedBox.expand(child: child);
  @override double get maxExtent => maxHeight;
  @override double get minExtent => minHeight;
  @override bool shouldRebuild(_StickyFilterHeaderDelegate old) => maxHeight != old.maxExtent || minHeight != old.minExtent || child != old.child;
}