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
import '../services/offline_service.dart';
import '../theme.dart';
import '../widgets/expandable_text.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;
  final String? heroTag;

  const PlantDetailScreen({super.key, required this.plant, this.heroTag});

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
    // La plante passée en paramètre sert d'affichage immédiat pendant le chargement complet.
    _displayPlant = widget.plant;
    _loadFullDetails();
    _loadReferences();
  }

  /*
    Tente de charger les détails complets depuis le réseau.
    En cas d'échec, tombe en fallback sur le cache local via OfflineService.
    Le flag _loadingDetails affiche une barre de progression en attendant.
  */
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
      debugPrint("Info: Impossible de charger détails depuis l'API ($e)");
      try {
        final localPlants = await OfflineService().getLocalPlants();
        final fullLocalPlant = localPlants.firstWhere((p) => p.id == widget.plant.id);
        if (mounted) {
          setState(() {
            _displayPlant = fullLocalPlant;
            _loadingDetails = false;
          });
          debugPrint("✅ Détails chargés depuis la sauvegarde locale !");
        }
      } catch (notFound) {
        debugPrint("Plante non trouvée en local.");
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

  /*
    Génère une fiche PDF complète de la plante via le package pdf/printing.
    L'image est téléchargée séparément via http car CachedNetworkImage
    ne fournit pas directement les bytes nécessaires au rendu PDF.
    La mise en page reproduit les mêmes sections que l'écran Flutter.
  */
  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    final plant = _displayPlant;

    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fontItalic = await PdfGoogleFonts.openSansItalic();
    final iconFont = await PdfGoogleFonts.materialIcons();

    pw.MemoryImage? pdfImage;
    if (plant.image != null) {
      try {
        final url = _api.getImageUrl(plant.image!);
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          pdfImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint("Erreur image PDF: $e");
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
            // En-tête : nom, nom scientifique, badges et description courte.
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

            if (plant.safetyPrecautions != null || plant.sideEffects != null)
              _pdfUnbreakableCard("Précautions & Sécurité", const pw.IconData(0xe002), PdfColors.red700, PdfColors.red50, [
                if (plant.safetyPrecautions != null) _pdfContentBlock("Précautions", plant.safetyPrecautions!),
                if (plant.sideEffects != null) _pdfContentBlock("Effets secondaires", plant.sideEffects!),
              ]),

            if (plant.usagePreparation != null || plant.usageDuration != null)
              _pdfUnbreakableCard("Mode d'emploi", const pw.IconData(0xef48), PdfColors.teal700, PdfColors.teal50, [
                if (plant.usagePreparation != null) _pdfContentBlock("Préparation & Dosage", plant.usagePreparation!),
                if (plant.usageDuration != null) _pdfContentBlock("Durée", plant.usageDuration!),
              ]),

            if (plant.descriptionVisual != null || plant.confusionRisks != null)
              _pdfUnbreakableCard("Identification", const pw.IconData(0xe8f4), PdfColors.blue700, PdfColors.blue50, [
                if (plant.plantType != null) _pdfContentBlock("Type", plant.plantType!),
                if (plant.descriptionVisual != null) _pdfContentBlock("Description visuelle", plant.descriptionVisual!),
                if (plant.procurementPicking != null) _pdfDetailRow(const pw.IconData(0xe406), "Cueillette :", plant.procurementPicking!),
                if (plant.procurementBuying != null) _pdfDetailRow(const pw.IconData(0xe8cc), "Achat :", plant.procurementBuying!),
                if (plant.procurementCulture != null) _pdfDetailRow(const pw.IconData(0xe3d3), "Culture :", plant.procurementCulture!),
                if (plant.confusionRisks != null)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 10),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(color: PdfColors.orange50, borderRadius: pw.BorderRadius.circular(4), border: pw.Border.all(color: PdfColors.orange200)),
                    child: _pdfContentBlock("Ne pas confondre avec", plant.confusionRisks!, isWarning: true),
                  ),
              ]),

            if (plant.scientificReferences != null && plant.scientificReferences!.isNotEmpty)
              _pdfUnbreakableCard("Informations scientifiques", const pw.IconData(0xea4d), PdfColors.grey800, PdfColors.grey100, [
                _pdfContentBlock("", plant.scientificReferences!),
              ]),

            if (_references.isNotEmpty)
              _pdfUnbreakableCard(
                "Sources & Références", const pw.IconData(0xe865), PdfColors.grey800, PdfColors.white,
                _references.map((ref) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("• ", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                      pw.Expanded(child: pw.Text(ref.fullReference, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))),
                    ],
                  ),
                )).toList(),
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

  /*
    Carte PDF non découpable (pw.Wrap) pour éviter qu'une section soit
    coupée entre deux pages. Chaque section a un en-tête coloré et un
    contenu avec padding uniforme.
  */
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
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children),
              ),
            ],
          ),
        ),
      ],
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
        ],
      ),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plant = _displayPlant;
    final imageUrl = plant.image != null ? _api.getImageUrl(plant.image!) : null;
    final hasProcurement = (plant.procurementPicking != null && plant.procurementPicking!.isNotEmpty) ||
        (plant.procurementBuying != null && plant.procurementBuying!.isNotEmpty) ||
        (plant.procurementCulture != null && plant.procurementCulture!.isNotEmpty);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar avec image en hero animation pour une transition fluide depuis les listes.
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
                tag: widget.heroTag ?? 'plant-detail-${plant.id}',
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        color: Colors.black26,
                        colorBlendMode: BlendMode.darken,
                        imageBuilder: (context, imageProvider) => Semantics(
                          label: 'Photo de ${plant.name}',
                          image: true,
                          child: Image(image: imageProvider, fit: BoxFit.cover, color: Colors.black26, colorBlendMode: BlendMode.darken),
                        ),
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
                  // Barre de progression affichée pendant le chargement des détails complets.
                  if (_loadingDetails)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: LinearProgressIndicator(color: isDark ? AppTheme.tealDark : AppTheme.teal1, backgroundColor: isDark ? Colors.grey.shade800 : const Color(0xFFE0F2F1)),
                    ),

                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (plant.isClinicallyValidated)
                      _buildBadge("Validé scientifiquement", isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50, isDark ? Colors.orange.shade300 : Colors.orange.shade900, icon: Icons.star),
                    if (plant.habitat != null && plant.habitat!.isNotEmpty)
                      _buildBadge(plant.habitat!, isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade100, isDark ? Colors.grey.shade400 : Colors.grey.shade800),
                  ]),
                  const SizedBox(height: 12),

                  Text(plant.scientificName ?? '', style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 18, fontFamily: 'Serif')),

                  // Noms communs affichés sous forme de tags individuels.
                  if (plant.commonNames != null && plant.commonNames!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(spacing: 6, runSpacing: 4, children: plant.commonNames!.split(',').map((name) =>
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(name.trim(), style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade700, fontSize: 12)),
                          )
                        ).toList()),
                    ),
                  const SizedBox(height: 24),

                  Text(plant.descriptionShort ?? "Description en cours de chargement...", style: TextStyle(fontSize: 16, height: 1.6, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 16),

                  if (plant.ailments.isNotEmpty)
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Indiqué pour :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 6, children: plant.ailments.map((a) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: (isDark ? AppTheme.tealDark : AppTheme.teal1).withOpacity(isDark ? 0.12 : 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(a, style: TextStyle(color: isDark ? AppTheme.tealDark : AppTheme.teal1, fontWeight: FontWeight.bold, fontSize: 13)),
                        )
                      ).toList()),
                    ]),
                  const SizedBox(height: 32),

                  // Sections dépliables (_PlantSection) affichées conditionnellement
                  // selon la disponibilité des données dans le modèle.
                  if ((plant.safetyPrecautions != null && plant.safetyPrecautions!.isNotEmpty) || (plant.sideEffects != null && plant.sideEffects!.isNotEmpty))
                    _PlantSection(
                      title: "Précautions & Sécurité",
                      icon: Icons.warning_amber_rounded,
                      accentColor: AppTheme.danger,
                      bgColor: const Color(0xFFFEF2F2),
                      initiallyExpanded: true,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (plant.safetyPrecautions != null && plant.safetyPrecautions!.isNotEmpty)
                          ExpandableText(
                            text: plant.safetyPrecautions!,
                            maxLines: 4,
                            selectable: true,
                            style: TextStyle(color: isDark ? Colors.red.shade200 : const Color(0xFF7F1D1D), fontWeight: FontWeight.w500, height: 1.5),
                          ),
                        if (plant.sideEffects != null && plant.sideEffects!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [const Icon(Icons.info_outline, size: 16, color: AppTheme.danger), const SizedBox(width: 6), Flexible(child: Text("Effets secondaires possibles", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger)))]),
                              const SizedBox(height: 6),
                              ExpandableText(text: plant.sideEffects!, maxLines: 3, selectable: true, style: const TextStyle(fontSize: 14, height: 1.5)),
                            ]),
                          )
                        ]
                      ]),
                    ),

                  if ((plant.usagePreparation != null && plant.usagePreparation!.isNotEmpty) || (plant.usageDuration != null && plant.usageDuration!.isNotEmpty))
                    _PlantSection(
                      title: "Mode d'emploi",
                      icon: Icons.medical_services_outlined,
                      accentColor: AppTheme.teal2,
                      bgColor: const Color(0xFFECFDF5),
                      initiallyExpanded: true,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (plant.usagePreparation != null && plant.usagePreparation!.isNotEmpty) ...[
                          Text("PRÉPARATION & DOSAGE", style: TextStyle(color: isDark ? AppTheme.tealDark : AppTheme.teal2, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          ExpandableText(text: plant.usagePreparation!, maxLines: 4, selectable: true, style: TextStyle(height: 1.5, color: Theme.of(context).colorScheme.onSurface)),
                        ],
                        if (plant.usageDuration != null && plant.usageDuration!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text("DURÉE", style: TextStyle(color: isDark ? AppTheme.tealDark : AppTheme.teal2, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          SelectableText(plant.usageDuration!, style: TextStyle(height: 1.5, color: Theme.of(context).colorScheme.onSurface)),
                        ]
                      ]),
                    ),

                  if (plant.descriptionVisual != null || hasProcurement || (plant.confusionRisks != null && plant.confusionRisks!.isNotEmpty))
                    _PlantSection(
                      title: "Identification",
                      icon: Icons.visibility_outlined,
                      accentColor: Colors.blue,
                      bgColor: const Color(0xFFEFF6FF),
                      initiallyExpanded: false,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (plant.plantType != null && plant.plantType!.isNotEmpty)
                          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text("Type : ${plant.plantType}", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))),
                        if (plant.descriptionVisual != null && plant.descriptionVisual!.isNotEmpty)
                          ExpandableText(text: plant.descriptionVisual!, maxLines: 4, selectable: true, style: TextStyle(height: 1.5, color: Theme.of(context).colorScheme.onSurface)),
                        if (hasProcurement) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.blue.withOpacity(0.1) : const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                            decoration: BoxDecoration(
                              color: isDark ? Colors.orange.withOpacity(0.1) : const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade400), const SizedBox(width: 6), Flexible(child: Text("Ne pas confondre avec :", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.orange.shade300 : Colors.orange.shade800)))]),
                              const SizedBox(height: 6),
                              ExpandableText(text: plant.confusionRisks!, maxLines: 3, selectable: true, style: TextStyle(fontSize: 14, color: isDark ? Colors.orange.shade200 : Colors.orange.shade900, height: 1.5)),
                            ]),
                          )
                        ]
                      ]),
                    ),

                  if (plant.scientificReferences != null && plant.scientificReferences!.isNotEmpty)
                    _PlantSection(
                      title: "Informations scientifiques",
                      icon: Icons.science,
                      accentColor: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
                      bgColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      initiallyExpanded: false,
                      child: ExpandableText(
                        text: plant.scientificReferences!,
                        maxLines: 4,
                        selectable: true,
                        style: TextStyle(height: 1.5, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),

                  if (!_loadingRefs && _references.isNotEmpty)
                    _PlantSection(
                      title: "Sources & Références",
                      icon: Icons.menu_book,
                      accentColor: isDark ? Colors.grey.shade400 : Colors.grey,
                      bgColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                      initiallyExpanded: false,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ..._references.map((ref) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            Expanded(child: SelectableText(ref.fullReference, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4))),
                          ]),
                        ))
                      ]),
                    ),

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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: textCol.withOpacity(0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: textCol), const SizedBox(width: 4)],
          Flexible(child: Text(text, style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 12))),
        ]),
      ),
    );
  }

  Widget _supplyRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: isDark ? Colors.blue.shade300 : Colors.blue), const SizedBox(width: 8),
        Text("$label : ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
        Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
      ]),
    );
  }
}

/*
  Widget réutilisable pour chaque section de la fiche plante.
  Utilise un ExpansionTile pour permettre à l'utilisateur de replier
  les sections moins prioritaires. initiallyExpanded est passé en paramètre
  pour que les sections critiques (précautions, mode d'emploi) soient
  ouvertes par défaut.
*/
class _PlantSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final bool initiallyExpanded;
  final Widget child;

  const _PlantSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.04), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Theme(
        // dividerColor transparent pour supprimer la ligne de séparation
        // par défaut de l'ExpansionTile, qui entre en conflit avec le border du Container.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: bgColor.withOpacity(isDark ? 0.12 : 0.5),
          collapsedBackgroundColor: surfaceColor,
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          title: Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
          children: [child],
        ),
      ),
    );
  }
}