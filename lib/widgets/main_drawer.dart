import 'package:flutter/material.dart';
import '../theme.dart';
import '../screens/about_screen.dart';
import '../screens/methodology_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class MainDrawer extends StatelessWidget {
  final Function(int) onTabChange;

  const MainDrawer({super.key, required this.onTabChange});

  // Fonction générique pour ouvrir n'importe quel lien
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      // LaunchMode.externalApplication force l'ouverture dans le navigateur (Chrome/Safari)
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print("Erreur ouverture lien: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // EN-TÊTE
                DrawerHeader(
                  decoration: const BoxDecoration(color: AppTheme.teal1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 70, height: 70,
                        padding: const EdgeInsets.all(15),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: SvgPicture.asset(
                          'assets/favicon.svg',
                          colorFilter: const ColorFilter.mode(AppTheme.teal1, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Natural Self-Care',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                // --- NAVIGATION PRINCIPALE ---
                ListTile(
                  leading: const Icon(Icons.home_filled, color: AppTheme.teal1),
                  title: const Text('Accueil', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    onTabChange(0);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_florist, color: AppTheme.teal1),
                  title: const Text('Explorer les remèdes', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    onTabChange(1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alt_route, color: AppTheme.teal1),
                  title: const Text('Chemins de décision', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    onTabChange(2);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book, color: AppTheme.teal1),
                  title: const Text('Index des problèmes', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    onTabChange(3);
                  },
                ),

                const Divider(),

                // --- PAGES D'INFO INTERNES ---
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('À propos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.science),
                  title: const Text('Démarche scientifique'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MethodologyScreen()));
                  },
                ),

                const Divider(),

                // --- LIENS EXTERNES & LÉGAUX (MIS À JOUR) ---
                
                // Facebook
                ListTile(
                  leading: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                  title: const Text('Suivez-nous sur Facebook', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => _launchURL('https://facebook.com/naturalselfcareweb'),
                ),

                // Politique de confidentialité (Lien temporaire)
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: Colors.grey),
                  title: const Text('Politique de confidentialité', style: TextStyle(fontSize: 14)),
                  dense: true,
                  onTap: () => _launchURL('http://46.224.187.154.nip.io/confidentialite'),
                ),

                // Mentions légales (Lien temporaire)
                ListTile(
                  leading: const Icon(Icons.gavel_outlined, color: Colors.grey),
                  title: const Text('Mentions légales', style: TextStyle(fontSize: 14)),
                  dense: true,
                  onTap: () => _launchURL('http://46.224.187.154.nip.io/mentions-legales'),
                ),
              ],
            ),
          ),
          
          // PIED DE PAGE
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("v1.0.0 - ASC Genève", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}