import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/plant.dart';
import '../models/reference.dart';
import '../services/api_service.dart';
import '../theme.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final ApiService _api = ApiService();
  
  late Plant _displayPlant;
  List<Reference> _references = [];
  bool _loadingRefs = true;
  bool _loadingDetails = true;

  @override
  void initState() {
    super.initState();
    _displayPlant = widget.plant;
    _loadFullDetails();
    _loadReferences();
  }

  Future<void> _loadFullDetails() async {
    try {
      final fullPlant = await _api.getPlantDetails(widget.plant.id);
      if (mounted) {
        setState(() {
          _displayPlant = fullPlant;
          _loadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  Future<void> _loadReferences() async {
    final refs = await _api.getReferences(widget.plant.id);
    if (mounted) {
      setState(() {
        _references = refs;
        _loadingRefs = false;
      });
    }
  }

  void _sharePlant() {
    Share.share('Découvrez les bienfaits de ${_displayPlant.name} sur Natural Self-Care : https://www.natural-self-care.ch/plantes/${_displayPlant.slug ?? ""}');
  }

  @override
  Widget build(BuildContext context) {
    final plant = _displayPlant;
    final imageUrl = plant.image != null ? _api.getImageUrl(plant.image!) : null;

    final hasProcurement = (plant.procurementPicking != null && plant.procurementPicking!.isNotEmpty) ||
        (plant.procurementBuying != null && plant.procurementBuying!.isNotEmpty) ||
        (plant.procurementCulture != null && plant.procurementCulture!.isNotEmpty);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.teal1,
            actions: [
              IconButton(icon: const Icon(Icons.share), onPressed: _sharePlant),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(plant.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black45, blurRadius: 10)])),
              background: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl, fit: BoxFit.cover,
                      color: Colors.black26, colorBlendMode: BlendMode.darken,
                    )
                  : Container(color: AppTheme.teal1),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadingDetails)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20.0),
                      child: LinearProgressIndicator(color: AppTheme.teal1, backgroundColor: Color(0xFFE0F2F1)),
                    ),

                  // BADGES
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (plant.isClinicallyValidated)
                      _buildBadge("Validé scientifiquement", Colors.orange.shade50, Colors.orange.shade900, icon: Icons.star),
                    if (plant.habitat != null && plant.habitat!.isNotEmpty)
                      _buildBadge(plant.habitat!, Colors.grey.shade100, Colors.grey.shade800),
                  ]),
                  const SizedBox(height: 12),

                  Text(plant.scientificName ?? '', style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textGrey, fontSize: 18, fontFamily: 'Serif')),
                  
                  if (plant.commonNames != null && plant.commonNames!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(spacing: 6, children: plant.commonNames!.split(',').map((name) => 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                            child: Text(name.trim(), style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                          )
                        ).toList()),
                    ),
                  const SizedBox(height: 24),

                  Text(plant.descriptionShort ?? "Description en cours de chargement...", style: const TextStyle(fontSize: 16, height: 1.6, color: AppTheme.textDark)),
                  const SizedBox(height: 16),
                  
                  if (plant.ailments.isNotEmpty)
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Indiqué pour :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 6, children: plant.ailments.map((a) => 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.teal1.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(a, style: const TextStyle(color: AppTheme.teal1, fontWeight: FontWeight.bold, fontSize: 13)),
                        )
                      ).toList()),
                    ]),
                  const SizedBox(height: 32),

                  // --- CARTE SÉCURITÉ ---
                  if ((plant.safetyPrecautions != null && plant.safetyPrecautions!.isNotEmpty) || (plant.sideEffects != null && plant.sideEffects!.isNotEmpty))
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: _cardDecoration(const Color(0xFFFEF2F2), AppTheme.danger),
                    child: Column(children: [
                      _cardHeader("Précautions & Sécurité", Icons.warning_amber_rounded, const Color(0xFFFEF2F2), AppTheme.danger),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (plant.safetyPrecautions != null && plant.safetyPrecautions!.isNotEmpty)
                             Text(plant.safetyPrecautions!, style: const TextStyle(color: Color(0xFF7F1D1D), fontWeight: FontWeight.w500)),
                          
                          if (plant.sideEffects != null && plant.sideEffects!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Row(children: [Icon(Icons.info_outline, size: 16, color: AppTheme.danger), SizedBox(width: 6), Text("Effets secondaires possibles", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger))]),
                                const SizedBox(height: 6),
                                Text(plant.sideEffects!, style: const TextStyle(fontSize: 14))
                              ]),
                            )
                          ]
                        ]),
                      ),
                    ]),
                  ),

                  // --- CARTE USAGE ---
                  if ((plant.usagePreparation != null && plant.usagePreparation!.isNotEmpty) || (plant.usageDuration != null && plant.usageDuration!.isNotEmpty))
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: _cardDecoration(const Color(0xFFECFDF5), AppTheme.teal2),
                    child: Column(children: [
                      _cardHeader("Mode d'emploi", Icons.medical_services_outlined, const Color(0xFFECFDF5), AppTheme.teal2),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (plant.usagePreparation != null && plant.usagePreparation!.isNotEmpty) ...[
                            const Text("PRÉPARATION & DOSAGE", style: TextStyle(color: AppTheme.teal2, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(plant.usagePreparation!, style: const TextStyle(height: 1.5)),
                          ],
                          if (plant.usageDuration != null && plant.usageDuration!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text("DURÉE", style: TextStyle(color: AppTheme.teal2, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(plant.usageDuration!, style: const TextStyle(height: 1.5)),
                          ]
                        ]),
                      ),
                    ]),
                  ),

                  // --- CARTE IDENTIFICATION ---
                  if (plant.descriptionVisual != null || hasProcurement || (plant.confusionRisks != null && plant.confusionRisks!.isNotEmpty))
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: _cardDecoration(const Color(0xFFEFF6FF), Colors.blue),
                    child: Column(children: [
                      _cardHeader("Identification", Icons.visibility_outlined, const Color(0xFFEFF6FF), Colors.blue),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (plant.plantType != null && plant.plantType!.isNotEmpty)
                            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text("Type : ${plant.plantType}", style: const TextStyle(fontWeight: FontWeight.bold))),
                          
                          if (plant.descriptionVisual != null && plant.descriptionVisual!.isNotEmpty)
                            Text(plant.descriptionVisual!, style: const TextStyle(height: 1.5)),
                          
                          if (hasProcurement) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8)),
                              child: Column(children: [
                                if (plant.procurementPicking != null && plant.procurementPicking!.isNotEmpty) _supplyRow(Icons.park, "Cueillette", plant.procurementPicking!),
                                if (plant.procurementBuying != null && plant.procurementBuying!.isNotEmpty) _supplyRow(Icons.shopping_bag, "Achat", plant.procurementBuying!),
                                if (plant.procurementCulture != null && plant.procurementCulture!.isNotEmpty) _supplyRow(Icons.yard, "Culture", plant.procurementCulture!),
                              ]),
                            )
                          ],

                          if (plant.confusionRisks != null && plant.confusionRisks!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade800), const SizedBox(width: 6), Text("Ne pas confondre avec :", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800))]),
                                const SizedBox(height: 6),
                                Text(plant.confusionRisks!, style: TextStyle(fontSize: 14, color: Colors.orange.shade900))
                              ]),
                            )
                          ]
                        ]),
                      ),
                    ]),
                  ),

                  // --- CARTE SCIENCE (NOUVEAU) ---
                  if (plant.scientificReferences != null && plant.scientificReferences!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      // J'utilise une couleur gris/neutre pour le scientifique
                      decoration: _cardDecoration(Colors.grey.shade50, Colors.grey),
                      child: Column(
                        children: [
                          _cardHeader("Informations scientifiques", Icons.science, Colors.grey.shade100, Colors.grey.shade800),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              plant.scientificReferences!,
                              style: const TextStyle(height: 1.5, fontSize: 14, color: AppTheme.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // RÉFÉRENCES (Bibliographie)
                  if (!_loadingRefs && _references.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [Icon(Icons.menu_book, color: Colors.grey), SizedBox(width: 10), Text("Sources & Références", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark))]),
                        const SizedBox(height: 16),
                        ..._references.map((ref) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            Expanded(child: Text(ref.fullReference, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4))),
                          ]),
                        ))
                      ]),
                    ),
                  ],

                  const SizedBox(height: 40),
                  const Center(child: Text("Fiche réalisée par l'ASC Genève.\nNatural Self-Care ne remplace pas un avis médical.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textCol, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: textCol.withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: textCol), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }

  BoxDecoration _cardDecoration(Color bg, Color border) {
    return BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: border.withOpacity(0.3)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]);
  }

  Widget _cardHeader(String title, IconData icon, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
      child: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))]),
    );
  }

  Widget _supplyRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: Colors.blue), const SizedBox(width: 8),
        Text("$label : ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ]),
    );
  }
}