import 'package:flutter/material.dart';

import '../models/progress.dart';
import '../services/spaced_repetition.dart';
import '../theme.dart';

/// The four SM-2 rating buttons, each labelled with when it would bring the
/// question back.
///
/// SM-2 schedules from how well the learner felt they recalled the answer, not
/// from whether they clicked the right option — a lucky guess and solid
/// knowledge look identical to the grader but should not be scheduled alike.
/// Showing the resulting interval on each button is what keeps that self-rating
/// honest rather than arbitrary: "Bom · 8 dias" is a concrete choice.
class ReviewRatingBar extends StatelessWidget {
  final SpacedRepetitionStats? current;

  /// Called with the rating and the interval the button displayed, so a caller
  /// reporting "repeat in N days" cannot disagree with what was tapped.
  final void Function(ReviewQuality quality, int interval) onRated;

  const ReviewRatingBar({
    super.key,
    required this.current,
    required this.onRated,
  });

  static const _colors = {
    ReviewQuality.again: errorColor,
    ReviewQuality.hard: warningColor,
    ReviewQuality.good: categoryCat2Color,
    ReviewQuality.easy: successColor,
  };

  /// "1 dia", "8 dias", "1 ano" — the cap reads better as a year than as 365.
  static String formatInterval(int days) {
    if (days >= Sm2Config.maxInterval) return '1 ano';
    if (days >= 30) {
      final months = (days / 30).round();
      return months == 1 ? '1 mês' : '$months meses';
    }
    return days == 1 ? '1 dia' : '$days dias';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previews = intervalPreviews(current);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology_outlined,
                size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              'Como correu?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Wrap rather than Row: four labels with intervals do not fit on one
        // line on a narrow phone, and truncating them defeats the point.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final quality in ReviewQuality.values)
              _RatingButton(
                quality: quality,
                interval: previews[quality]!,
                color: _colors[quality]!,
                isDark: isDark,
                onPressed: () => onRated(quality, previews[quality]!),
              ),
          ],
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  final ReviewQuality quality;
  final int interval;
  final Color color;
  final bool isDark;
  final VoidCallback onPressed;

  const _RatingButton({
    required this.quality,
    required this.interval,
    required this.color,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(isDark ? 40 : 20),
      borderRadius: BorderRadius.circular(radiusS),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(radiusS),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radiusS),
            border: Border.all(color: color.withAlpha(90)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                quality.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ReviewRatingBar.formatInterval(interval),
                style: TextStyle(
                  fontSize: 11,
                  color: color.withAlpha(200),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
