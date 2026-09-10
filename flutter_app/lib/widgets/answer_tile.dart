import 'package:flutter/material.dart';

import '../theme.dart';

/// A styled answer option tile with optional correct/incorrect feedback.
class AnswerTile extends StatelessWidget {
  const AnswerTile({
    super.key,
    required this.text,
    required this.index,
    this.isSelected = false,
    this.isCorrect = false,
    this.showCorrectFeedback = false,
    this.showWrongFeedback = false,
    this.accentColor,
  });

  final String text;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool showCorrectFeedback;
  final bool showWrongFeedback;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? colorScheme.primary;

    Color tileColor;
    Color borderColor;

    if (showCorrectFeedback && isCorrect) {
      tileColor = successColor.withAlpha(isDark ? 40 : 25);
      borderColor = successColor.withAlpha(100);
    } else if (showWrongFeedback && isSelected) {
      tileColor = errorColor.withAlpha(isDark ? 40 : 25);
      borderColor = errorColor.withAlpha(100);
    } else if (isSelected) {
      tileColor = accent.withAlpha(isDark ? 40 : 20);
      borderColor = accent.withAlpha(80);
    } else {
      tileColor = colorScheme.surfaceContainerHighest.withAlpha(100);
      borderColor = colorScheme.outlineVariant.withAlpha(80);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(radiusS),
          border: Border.all(color: borderColor),
        ),
        child: ListTile(
          leading: Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: (showCorrectFeedback && isCorrect)
                ? successColor
                : (showWrongFeedback && isSelected)
                    ? errorColor
                    : isSelected
                        ? accent
                        : colorScheme.onSurfaceVariant,
          ),
          title: Text(
            text,
            style: TextStyle(
              fontWeight: (showCorrectFeedback && isCorrect)
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: (showCorrectFeedback && isCorrect)
                  ? successColor
                  : (showWrongFeedback && isSelected)
                      ? errorColor
                      : colorScheme.onSurface,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
        ),
      ),
    );
  }
}
