import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint("Erreur lien: $e");
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'contact@asc-geneve.ch',
    );
    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      debugPrint("Erreur mail: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("À propos")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. SECTION ORIGINE & LIVRE ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FDF9), // Fond vert très doux
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    "Qui nous sommes",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.teal1),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Cette plateforme est issue d'une enquête du Dr Bertrand Graz, médecin et du Dr Jacques Falquet, biochimiste.\n\n"
                    "Ces deux chercheurs ont entrepris de présenter des remèdes naturels dont l'efficacité a été démontrée de manière scientifiquement rigoureuse.\n\n"
                    "Cette enquête fait l’objet d’un ouvrage publié aux éditions Favre : « Les 33 plantes validées scientifiquement ».",
                    style: TextStyle(fontSize: 16, height: 1.6, color: AppTheme.textDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Image du livre (Cliquable)
                  GestureDetector(
                    onTap: () => _launchURL("https://www.editionsfavre.com/livres/33-plantes-validees-scientifiquement-les/"),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/book.jpg', width: 150),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton.icon(
                    onPressed: () => _launchURL("https://www.editionsfavre.com/livres/33-plantes-validees-scientifiquement-les/"),
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text("Voir l'ouvrage"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.teal1,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- 2. TEXTE EVOLUTION (Harmonisé) ---
            const Text(
              "Par la suite, les informations présentées ont été complétées à mesure que de nouvelles études apportaient des informations utiles.\n\n"
              "Les traitements retenus sont facilement disponibles et correspondent à des pathologies courantes.",
              style: TextStyle(fontSize: 16, height: 1.6, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            const Text(
              "Les mises à jour sont actuellement assurées par l'Association Santé Communautaire – Genève.",
              style: TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.bold, color: AppTheme.teal1),
            ),

            const SizedBox(height: 40),

            // --- 3. LIENS & PARTENAIRES ---
            const Text("Liens utiles", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPartnerLink(
              'assets/sspm-logo.jpg', 
              "Société Suisse de Phytothérapie Médicale",
              "https://smgp-sspm.ch/die_smgp"
            ),
            const SizedBox(height: 12),
            _buildPartnerLink(
              'assets/sfe-logo.jpg', 
              "Société Française d'Ethnopharmacologie",
              "https://www.ethnopharmacologia.org"
            ),

            const SizedBox(height: 40),

            // --- 4. CONTACT ASC ---
            const Text("Contact", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.05),
              child: InkWell(
                onTap: () => _launchURL("https://www.asc-geneve.org"),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 80, height: 80,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset('assets/logo_ASC.jpg', fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("ASC Genève", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text("Ch. des Montaneyres 4\n1443 CHAMPVENT", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _launchEmail,
                              child: Row(
                                children: [
                                  const Icon(Icons.mail_outline, color: AppTheme.teal1, size: 18),
                                  const SizedBox(width: 6),
                                  const Text("contact@asc-geneve.ch", style: TextStyle(color: AppTheme.teal1, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerLink(String imagePath, String title, String url) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _launchURL(url),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Image.asset(imagePath, width: 50, height: 50, fit: BoxFit.contain),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
              const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}