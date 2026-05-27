import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme.dart';

/*
  Bandeau affiché en haut de l'écran lorsque l'appareil est hors ligne.
  Utilise un StreamBuilder pour écouter en temps réel les changements
  de connectivité via le plugin connectivity_plus.
*/
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        // Par défaut on considère qu'il y a une connexion,
        // pour ne pas afficher le bandeau avant que le stream émette une valeur.
        bool isOffline = false;

        if (snapshot.hasData) {
          final result = snapshot.data!;
          // La vérification sur length == 1 évite les faux positifs :
          // sur certains appareils, none peut coexister avec d'autres résultats
          // lors d'une transition réseau.
          if (result.contains(ConnectivityResult.none) && result.length == 1) {
            isOffline = true;
          }
        }

        if (!isOffline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          color: AppTheme.danger,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 14),
              SizedBox(width: 8),
              Text(
                "Mode Hors Ligne activé",
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}