import 'package:flutter/material.dart';
import '../theme.dart';
import '../screens/about_screen.dart';
import '../screens/methodology_screen.dart';
import '../screens/offline_settings_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/*
  Drawer principal de l'application.
  Permet la navigation entre les onglets principaux et l'accès aux écrans
  secondaires (À propos, Démarche scientifique, Mode hors ligne).
  ConsumerWidget est utilisé pour accéder au themeModeProvider et permettre
  le basculement clair/sombre depuis le drawer.
*/
class MainDrawer extends ConsumerWidget {
  final Function(int) onTabChange;

  const MainDrawer({super.key, required this.onTabChange});

  // Ouvre un lien externe dans le navigateur par défaut de l'appareil.
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Erreur ouverture lien: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tealColor = isDark ? AppTheme.tealDark : AppTheme.teal1;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
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
                          // colorFilter applique la teinte teal1 sur le SVG blanc.
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

                // Navigation vers les onglets principaux.
                // onTabChange ferme le drawer et change l'onglet actif dans MainScaffold.
                ListTile(
                  leading: Icon(Icons.home_filled, color: tealColor),
                  title: const Text('Accueil', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    onTabChange(0);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.local_florist, color: tealColor),
                  title: const Text('Remèdes naturels', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    onTabChange(1);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.alt_route, color: tealColor),
                  title: const Text('Du symptôme au remède', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    onTabChange(2);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.menu_book, color: tealColor),
                  title: const Text('Liste des problèmes', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    onTabChange(3);
                  },
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.download_for_offline, color: Colors.orange),
                  title: const Text('Mode Hors Ligne', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const OfflineSettingsScreen()));
                  },
                ),

                // Switch de basculement thème clair/sombre.
                // L'icône et le label s'inversent selon l'état actuel.
                ListTile(
                  leading: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: tealColor),
                  title: Text(isDarkMode ? 'Mode clair' : 'Mode sombre'),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                    activeThumbColor: AppTheme.teal1,
                  ),
                ),

                const Divider(),

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

                // Liens légaux ouverts dans le navigateur externe via _launchURL.
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: Colors.grey),
                  title: const Text('Politique de confidentialité', style: TextStyle(fontSize: 14)),
                  dense: true,
                  onTap: () => _launchURL('https://www.natural-self-care.ch/confidentialite'),
                ),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined, color: Colors.grey),
                  title: const Text('Mentions légales', style: TextStyle(fontSize: 14)),
                  dense: true,
                  onTap: () => _launchURL('https://www.natural-self-care.ch/mentions-legales'),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("v1.0.0 - ASC Genève", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}