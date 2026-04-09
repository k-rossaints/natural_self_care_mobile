import 'package:flutter/material.dart';

/// Une boîte grise animée qui simule du contenu en chargement
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}

/// Skeleton d'une carte plante
class PlantCardSkeleton extends StatelessWidget {
  const PlantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          // Image placeholder
          const SkeletonBox(width: 60, height: 60, borderRadius: 10),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 16),
                const SizedBox(height: 8),
                SkeletonBox(width: MediaQuery.of(context).size.width * 0.4, height: 12),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SkeletonBox(width: 60, height: 22, borderRadius: 12),
                    const SizedBox(width: 8),
                    SkeletonBox(width: 70, height: 22, borderRadius: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Liste de skeletons de cartes plantes
class PlantListSkeleton extends StatelessWidget {
  final int count;
  const PlantListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const PlantCardSkeleton()),
    );
  }
}

/// Skeleton d'un item de liste simple (symptôme, problème...)
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 15),
                const SizedBox(height: 8),
                SkeletonBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Liste de skeletons simples
class ListSkeleton extends StatelessWidget {
  final int count;
  const ListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const ListItemSkeleton()),
    );
  }
}