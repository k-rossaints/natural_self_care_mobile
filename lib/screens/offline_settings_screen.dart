import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/offline_service.dart';
import '../services/api_service.dart';

class OfflineSettingsScreen extends StatefulWidget {
  const OfflineSettingsScreen({super.key});

  @override
  State<OfflineSettingsScreen> createState() => _OfflineSettingsScreenState();
}

class _OfflineSettingsScreenState extends State<OfflineSettingsScreen> {
  final OfflineService _offlineService = OfflineService();
  final ApiService _api = ApiService();

  bool _saveImages = false;
  bool _isDownloading = false;
  String _statusMessage = "";

  String? _datePlants;
  String? _datePaths;
  String? _dateMethodology;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Charge l'option de sauvegarde des images et les dates de dernière synchronisation.
  Future<void> _loadSettings() async {
    final saveImg = await _offlineService.shouldSaveImages();
    final dates = await _offlineService.getSyncDates();
    if (mounted) {
      setState(() {
        _saveImages = saveImg;
        _datePlants = dates['plants'];
        _datePaths = dates['paths'];
        _dateMethodology = dates['methodology'];
      });
    }
  }

  /*
    Lance le téléchargement des catégories sélectionnées de manière séquentielle.
    Le message de statut est mis à jour entre chaque étape pour informer l'utilisateur.
    Les dates de synchronisation sont rafraîchies après un téléchargement réussi.
  */
  Future<void> _startDownload({
    bool downloadPlants = false,
    bool downloadPaths = false,
    bool downloadMethodology = false,
  }) async {
    setState(() {
      _isDownloading = true;
      _statusMessage = "Connexion au serveur...";
    });

    try {
      if (downloadPlants) {
        setState(() => _statusMessage = "Téléchargement des plantes...");
        await _api.downloadPlants();
      }
      if (downloadPaths) {
        setState(() => _statusMessage = "Téléchargement des parcours...");
        await _api.downloadDecisionPaths();
      }
      if (downloadMethodology) {
        setState(() => _statusMessage = "Téléchargement des références...");
        await _api.downloadMethodology();
      }

      final dates = await _offlineService.getSyncDates();
      if (mounted) {
        setState(() {
          _datePlants = dates['plants'];
          _datePaths = dates['paths'];
          _dateMethodology = dates['methodology'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Téléchargement terminé avec succès !"),
            backgroundColor: AppTheme.teal1,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = "";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mode Hors Ligne")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Téléchargez le contenu pour l'utiliser sans internet.\nLes données sont aussi sauvegardées automatiquement à chaque visite.",
            style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 30),

          Text("OPTIONS", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.tealDark : AppTheme.teal1)),
          SwitchListTile(
            title: const Text("Sauvegarder les images"),
            subtitle: const Text("Consomme plus d'espace de stockage"),
            value: _saveImages,
            activeThumbColor: AppTheme.teal1,
            onChanged: (val) {
              setState(() => _saveImages = val);
              _offlineService.setSaveImages(val);
            },
          ),

          const Divider(height: 40),

          Text("CONTENU À TÉLÉCHARGER", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.tealDark : AppTheme.teal1)),
          const SizedBox(height: 10),

          // Chaque bouton correspond à une catégorie de données téléchargeable indépendamment.
          _buildDownloadButton(
            title: "Base de données Plantes",
            icon: Icons.local_florist,
            lastSync: _datePlants,
            onTap: () => _startDownload(downloadPlants: true),
          ),
          const SizedBox(height: 10),

          _buildDownloadButton(
            title: "Chemins de décision",
            icon: Icons.alt_route,
            lastSync: _datePaths,
            onTap: () => _startDownload(downloadPaths: true),
          ),
          const SizedBox(height: 10),

          _buildDownloadButton(
            title: "Démarche scientifique",
            icon: Icons.science,
            lastSync: _dateMethodology,
            onTap: () => _startDownload(downloadMethodology: true),
          ),

          const SizedBox(height: 20),

          // Barre de progression et message de statut affichés uniquement pendant un téléchargement.
          if (_isDownloading) ...[
            LinearProgressIndicator(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.tealDark : AppTheme.teal1),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _statusMessage,
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.tealDark : AppTheme.teal1, fontWeight: FontWeight.bold),
              ),
            ),
          ],

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download_for_offline),
              label: const Text("Tout télécharger"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal1,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              // Désactivé pendant un téléchargement en cours pour éviter les appels simultanés.
              onPressed: _isDownloading
                  ? null
                  : () => _startDownload(
                        downloadPlants: true,
                        downloadPaths: true,
                        downloadMethodology: true,
                      ),
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
            label: const Text("Supprimer les données locales", style: TextStyle(color: AppTheme.danger)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.danger)),
            onPressed: () async {
              await _offlineService.clearAllData();
              setState(() {
                _datePlants = null;
                _datePaths = null;
                _dateMethodology = null;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Données supprimées")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /*
    Carte représentant une catégorie de données téléchargeable.
    L'icône et la couleur du sous-titre indiquent si la donnée a déjà été
    synchronisée, avec la date de dernière synchronisation si disponible.
  */
  Widget _buildDownloadButton({
    required String title,
    required IconData icon,
    required String? lastSync,
    required VoidCallback onTap,
  }) {
    final isSynced = lastSync != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: isDark ? AppTheme.darkCard : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: isDark ? AppTheme.tealDark : AppTheme.teal1),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Icon(
              isSynced ? Icons.check_circle : Icons.info_outline,
              size: 12,
              color: isSynced ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              isSynced ? "Synchro : $lastSync" : "Non téléchargé",
              style: TextStyle(fontSize: 12, color: isSynced ? Colors.green : Colors.grey),
            ),
          ],
        ),
        // Bouton de téléchargement masqué pendant un téléchargement en cours.
        trailing: _isDownloading
            ? null
            : IconButton(
                icon: Icon(Icons.download_rounded, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.tealDark : AppTheme.teal1),
                onPressed: onTap,
              ),
      ),
    );
  }
}