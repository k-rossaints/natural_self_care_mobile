import 'package:flutter/material.dart';
import '../theme.dart';
import '../screens/about_screen.dart';
import '../screens/methodology_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart'; // <--- NOUVEL IMPORT

class MainDrawer extends StatelessWidget {
  final Function(int) onTabChange;

  const MainDrawer({super.key, required this.onTabChange});

  // Fonction pour ouvrir le lien
  Future<void> _launchFacebook() async {
    final Uri url = Uri.parse('https://facebook.com/naturalselfcareweb');
    // Mode externalApplication pour ouvrir l'appli Facebook si installée, sinon le navigateur
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Impossible d\'ouvrir $url');
      }
    } catch (e) {
      print("Erreur ouverture lien: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column( // On utilise Column pour pousser la version tout en bas
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
                
                // NAVIGATION PRINCIPALE
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

                // PAGES D'INFO
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

                // BOUTON FACEBOOK (NOUVEAU)
                ListTile(
                  leading: const Icon(Icons.facebook, color: Color(0xFF1877F2)), // Bleu officiel FB
                  title: const Text('Suivez-nous sur Facebook', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: _launchFacebook,
                ),
              ],
            ),
          ),
          
          // PIED DE PAGE (Version)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("v1.0.0 - ASC Genève", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}