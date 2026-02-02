import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/plant.dart';
import '../services/api_service.dart';
import '../theme.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const PlantCard({super.key, required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    final imageUrl = plant.image != null ? api.getImageUrl(plant.image!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. IMAGE DE COUVERTURE
              Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: Icon(Icons.image, color: Colors.black12)),
                            errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.black12)),
                          )
                        : const Center(child: Icon(Icons.local_florist, size: 40, color: Colors.black12)),
                  ),
                  
                  if (plant.isClinicallyValidated)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text(
                              "Validé",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // 2. CONTENU TEXTE
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.scientificName ?? '',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textGrey,
                        fontSize: 13,
                        fontFamily: 'Serif'
                      ),
                    ),
                    
                    // --- NOUVEAU : Affichage de l'Habitat ---
                    if (plant.habitat != null && plant.habitat!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.public, size: 14, color: AppTheme.teal2),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                plant.habitat!,
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // ----------------------------------------

                    const SizedBox(height: 12),
                    
                    if (plant.ailments.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: plant.ailments.take(3).map((a) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.teal1.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            a,
                            style: const TextStyle(fontSize: 11, color: AppTheme.teal1, fontWeight: FontWeight.w600),
                          ),
                        )).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}