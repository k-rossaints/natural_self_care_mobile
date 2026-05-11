import 'package:flutter/material.dart';
import '../theme.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final bool selectable;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.style,
    this.selectable = false,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;
  final bool _overflows = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? const TextStyle(fontSize: 15, height: 1.5);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tealColor = isDark ? AppTheme.tealDark : AppTheme.teal1;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Mesure si le texte déborde vraiment avec les maxLines donnés
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final overflows = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.selectable
                ? SelectableText(
                    widget.text,
                    style: style,
                    maxLines: _expanded ? null : widget.maxLines,
                  )
                : Text(
                    widget.text,
                    style: style,
                    maxLines: _expanded ? null : widget.maxLines,
                    overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
            if (overflows) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? 'Voir moins' : 'Voir plus',
                      style: TextStyle(
                        color: tealColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: tealColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}