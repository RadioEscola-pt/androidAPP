import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme.dart';

/// A branded card designed to be captured as a shareable image.
class ShareResultCard extends StatelessWidget {
  const ShareResultCard({
    super.key,
    required this.repaintKey,
    required this.score,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.total,
    required this.categoryLabel,
    required this.accentColor,
  });

  final GlobalKey repaintKey;
  final double score;
  final int correct;
  final int wrong;
  final int unanswered;
  final int total;
  final String categoryLabel;
  final Color accentColor;

  /// Captures this widget as a PNG image.
  static Future<Uint8List?> capture(GlobalKey key) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final passed = score > 0;
    final scoreColor = passed ? successColor : errorColor;

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radiusM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brand header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cell_tower_rounded, size: 22, color: brandColor),
                const SizedBox(width: 8),
                Text(
                  'Rádio Escola',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: brandColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Exame · $categoryLabel',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Score circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scoreColor.withAlpha(25),
                border: Border.all(color: scoreColor.withAlpha(100), width: 3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'pontos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(
                    value: '$correct', label: 'Certas', color: successColor),
                _StatColumn(
                    value: '$wrong', label: 'Erradas', color: errorColor),
                _StatColumn(
                  value: '$unanswered',
                  label: 'Sem resp.',
                  color: Colors.grey.shade500,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(radiusS),
              ),
              child: Text(
                '$correct/$total corretas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
