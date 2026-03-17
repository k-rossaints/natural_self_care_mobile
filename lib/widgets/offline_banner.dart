import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        // Par défaut, on considère qu'on a internet sauf preuve du contraire
        bool isOffline = false;

        if (snapshot.hasData) {
          final result = snapshot.data!;
          // Si la liste contient 'none', on est hors ligne
          if (result.contains(ConnectivityResult.none) && result.length == 1) {
            isOffline = true;
          }
        }

        if (!isOffline) return const SizedBox.shrink(); // Rien si internet OK

        return Container(
          width: double.infinity,
          color: AppTheme.danger, // Rouge
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