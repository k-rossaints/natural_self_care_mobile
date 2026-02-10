import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../models/plant.dart';
import '../models/reference.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart'; // N'oublie pas cet import pour le mode hors ligne
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
  bool _loadingDetails = true;
  bool _loadingRefs = true; 

  @override
  void initState() {
    super.initState();
    _displayPlant = widget.plant;
    _loadFullDetails();
    _loadReferences();
  }

  Future<void> _loadFullDetails() async {
    try {
      // 1. Tentative de chargement via Internet
      final fullPlant = await _api.getPlantDetails(widget.plant.id);
      if (mounted) {
        setState(() {
          _displayPlant = fullPlant;
          _loadingDetails = false;
        });
      }
    } catch (e) {
      print("Info: Impossible de charger détails depuis l'API ($e)");
      
      // 2. FALLBACK HORS LIGNE : On cherche dans la base locale
      try {
        final localPlants = await OfflineService().getLocalPlants();
        // On cherche la plante correspondante par son ID dans la liste complète
        final fullLocalPlant = localPlants.firstWhere((p) => p.id == widget.plant.id);
        
        if (mounted) {
          setState(() {
            _displayPlant = fullLocalPlant; // On met à jour avec les infos locales complètes
            _loadingDetails = false;
          });
          print("✅ Détails chargés depuis la sauvegarde locale !");
        }
      } catch (notFound) {
        // La plante n'est pas dans la sauvegarde
        print("Plante non trouvée en local.");
        if (mounted) setState(() => _loadingDetails = false);
      }
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

  // ==========================================
  // GÉNÉRATION DU PDF (VERSION FINALE STABLE)
  // ==========================================
  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final plant = _displayPlant;

    // 1. Polices
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fontItalic = await PdfGoogleFonts.openSansItalic();
    final iconFont = await PdfGoogleFonts.materialIcons();

    // 2. Image
    pw.MemoryImage? pdfImage;
    if (plant.image != null) {
      try {
        final url = _api.getImageUrl(plant.image!);
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          pdfImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print("Erreur image PDF: $e");
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
          icons: iconFont,
        ),
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        
        build: (pw.Context context) {
          return [
            // --- EN-TÊTE ---
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              margin: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Natural Self-Care - Fiche descriptive", style: const pw.TextStyle(color: PdfColors.teal, fontSize: 9)),
                        pw.SizedBox(height: 8),
                        pw.Text(plant.name, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.Text(plant.scientificName ?? '', style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                        pw.SizedBox(height: 12),
                        pw.Wrap(spacing: 5, runSpacing: 5, children: [
                          if (plant.isClinicallyValidated) _pdfBadge("Validé scientifiquement", PdfColors.orange800, PdfColors.orange100, const pw.IconData(0xe838)),
                          if (plant.habitat != null) _pdfBadge(plant.habitat!, PdfColors.grey800, PdfColors.grey200, null),
                          if (plant.plantType != null) _pdfBadge(plant.plantType!, PdfColors.blue800, PdfColors.blue100, null),
                        ]),
                        pw.SizedBox(height: 12),
                        if (plant.descriptionShort != null)
                          pw.Text(plant.descriptionShort!, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.4, color: PdfColors.grey800)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 25),
                  if (pdfImage != null)
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        height: 140, 
                        decoration: pw.BoxDecoration(
                          borderRadius: pw.BorderRadius.circular(8),
                          image: pw.DecorationImage(image: pdfImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // --- CONTENU (BLOCKS) ---
            
            if (plant.safetyPrecautions != null || plant.sideEffects != null)
              _pdfUnbreakableCard(
                "Précautions & Sécurité",
                const pw.IconData(0xe002), 
                PdfColors.red700,
                PdfColors.red50,
                [
                  if (plant.safetyPrecautions != null) _pdfContentBlock("Précautions", plant.safetyPrecautions!),
                  if (plant.sideEffects != null) _pdfContentBlock("Effets secondaires", plant.sideEffects!),
                ]
              ),

            if (plant.usagePreparation != null || plant.usageDuration != null)
              _pdfUnbreakableCard(
                "Mode d'emploi",
                const pw.IconData(0xef48), 
                PdfColors.teal700,
                PdfColors.teal50,
                [
                  if (plant.usagePreparation != null) _pdfContentBlock("Préparation & Dosage", plant.usagePreparation!),
                  if (plant.usageDuration != null) _pdfContentBlock("Durée", plant.usageDuration!),
                ]
              ),

            if (plant.descriptionVisual != null || plant.confusionRisks != null)
              _pdfUnbreakableCard(
                "Identification",
                const pw.IconData(0xe8f4), 
                PdfColors.blue700,
                PdfColors.blue50,
                [
                  if (plant.plantType != null) _pdfContentBlock("Type", plant.plantType!),
                  if (plant.descriptionVisual != null) _pdfContentBlock("Description visuelle", plant.descriptionVisual!),
                  
                  // --- ICONES STANDARDS (Safe) ---
                  if (plant.procurementPicking != null) 
                    _pdfDetailRow(const pw.IconData(0xe406), "Cueillette :", plant.procurementPicking!), // Icons.nature
                  
                  if (plant.procurementBuying != null) 
                    _pdfDetailRow(const pw.IconData(0xe8cc), "Achat :", plant.procurementBuying!), // Icons.shopping_cart
                  
                  if (plant.procurementCulture != null) 
                    _pdfDetailRow(const pw.IconData(0xe3d3), "Culture :", plant.procurementCulture!), // Icons.filter_vintage (Fleur/Plante - très compatible)

                  if (plant.confusionRisks != null) 
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 10),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(color: PdfColors.orange50, borderRadius: pw.BorderRadius.circular(4), border: pw.Border.all(color: PdfColors.orange200)),
                      child: _pdfContentBlock("Ne pas confondre avec", plant.confusionRisks!, isWarning: true)
                    ),
                ]
              ),

            if (plant.scientificReferences != null && plant.scientificReferences!.isNotEmpty)
              _pdfUnbreakableCard(
                "Informations scientifiques",
                const pw.IconData(0xea4d), 
                PdfColors.grey800,
                PdfColors.grey100,
                [
                  _pdfContentBlock("", plant.scientificReferences!),
                ]
              ),

            if (_references.isNotEmpty)
              _pdfUnbreakableCard(
                "Sources & Références", 
                const pw.IconData(0xe865), 
                PdfColors.grey800, 
                PdfColors.white,
                _references.map((ref) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("• ", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                      pw.Expanded(child: pw.Text(ref.fullReference, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))),
                    ]
                  )
                )).toList()
              ),

            pw.SizedBox(height: 20),
            pw.Divider(thickness: 0.5, color: PdfColors.grey300),
            pw.Center(
              child: pw.Text(
                "Généré par l'application Natural Self-Care - ASC Genève",
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${plant.name}_Fiche.pdf',
    );
  }

  // --- WIDGETS PDF HELPERS ---
  pw.Widget _pdfUnbreakableCard(String title, pw.IconData icon, PdfColor accentColor, PdfColor bgColor, List<pw.Widget> children) {
    return pw.Wrap(
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: accentColor, width: 1),
            borderRadius: pw.BorderRadius.circular(8),
            color: PdfColors.white,
          ),
          child: pw.Column(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: bgColor,
                  borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(7), topRight: pw.Radius.circular(7)),
                ),
                child: pw.Row(
                  children: [
                    pw.Icon(icon, color: accentColor, size: 14),
                    pw.SizedBox(width: 8),
                    pw.Text(title, style: pw.TextStyle(color: accentColor, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ]
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ]
          )
        )
      ]
    );
  }

  pw.Widget _pdfBadge(String text, PdfColor textColor, PdfColor bgColor, pw.IconData? icon) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(color: bgColor, borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (icon != null) ...[pw.Icon(icon, color: textColor, size: 9), pw.SizedBox(width: 3)],
          pw.Text(text, style: pw.TextStyle(color: textColor, fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ]
      )
    );
  }

  pw.Widget _pdfContentBlock(String label, String content, {bool isWarning = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            pw.Text(label.toUpperCase(), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: isWarning ? PdfColors.red : PdfColors.black)),
          if (label.isNotEmpty) pw.SizedBox(height: 2),
          pw.Text(content, style: pw.TextStyle(fontSize: 10, lineSpacing: 1.4, color: isWarning ? PdfColors.red900 : PdfColors.grey900)),
        ],
      ),
    );
  }

  pw.Widget _pdfDetailRow(pw.IconData icon, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Icon(icon, size: 10, color: PdfColors.blue700),
          pw.SizedBox(width: 6),
          pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 4),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 9))),
        ]
      )
    );
  }

  // ==========================================
  // BUILD FLUTTER UI (ECRAN)
  // ==========================================
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
              IconButton(
                icon: const Icon(Icons.print),
                tooltip: "Télécharger en PDF",
                onPressed: () => _generatePdf(context),
              ),
              IconButton(icon: const Icon(Icons.share), onPressed: _sharePlant),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(plant.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black45, blurRadius: 10)])),
              background: Hero(
                // Le tag doit être IDENTIQUE à celui du HomeScreen
                tag: 'plant-${plant.id}', 
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl, 
                        fit: BoxFit.cover,
                        color: Colors.black26, 
                        colorBlendMode: BlendMode.darken,
                        // Placeholder pour éviter un flash blanc pendant le chargement
                        placeholder: (context, url) => Container(color: AppTheme.teal1),
                        errorWidget: (context, url, error) => Container(color: AppTheme.teal1, child: const Icon(Icons.error)),
                      )
                    : Container(color: AppTheme.teal1),
              ),
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

                  if (plant.scientificReferences != null && plant.scientificReferences!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
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