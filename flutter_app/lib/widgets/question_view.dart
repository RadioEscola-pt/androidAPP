import 'package:flutter/material.dart';

import '../models/question.dart';
import '../theme.dart';
import 'notes_container.dart';

/// One question: prompt, figure, answer options, and the explanation once
/// answered.
///
/// Shared by study mode and review sessions. They differ in what surrounds a
/// question — linear navigation against a session queue — not in how a question
/// looks, and two renderings of the same thing is exactly what drifts.
///
/// The widget is stateless about the answer: [selectedAnswer] and [onAnswer]
/// belong to the screen, since the screens disagree about what answering means
/// (study lets you browse on, a session advances its queue).
class QuestionView extends StatelessWidget {
  final Question question;
  final Color accentColor;

  /// Text above the prompt, e.g. "Pergunta 3 de 20".
  final String positionLabel;

  /// Null until the question is answered.
  final int? selectedAnswer;

  final ValueChanged<int> onAnswer;

  /// Shown under the explanation — the rating bar, or its replacement.
  final Widget? footer;

  const QuestionView({
    super.key,
    required this.question,
    required this.accentColor,
    required this.positionLabel,
    required this.selectedAnswer,
    required this.onAnswer,
    this.footer,
  });

  bool get _answered => selectedAnswer != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          positionLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accentColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          question.question,
          style: TextStyle(
            fontSize: 18,
            color: colorScheme.onSurface,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        if (question.img != null && question.img!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radiusS),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Image.asset(
                  question.img!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        _AnswerOptions(
          question: question,
          accentColor: accentColor,
          selectedAnswer: selectedAnswer,
          onAnswer: onAnswer,
        ),
        if (_answered && question.hasExplanation) ...[
          const SizedBox(height: 20),
          NotesContainer(
            notes: question.explanationHtml,
            accentColor: accentColor,
          ),
        ],
        if (_answered && footer != null) ...[
          const SizedBox(height: 20),
          footer!,
        ],
      ],
    );
  }
}

class _AnswerOptions extends StatelessWidget {
  final Question question;
  final Color accentColor;
  final int? selectedAnswer;
  final ValueChanged<int> onAnswer;

  const _AnswerOptions({
    required this.question,
    required this.accentColor,
    required this.selectedAnswer,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final answered = selectedAnswer != null;

    return RadioGroup<int>(
      groupValue: selectedAnswer ?? -1,
      onChanged: (val) {
        if (!answered && val != null) onAnswer(val);
      },
      child: Column(
        children: List.generate(question.options.length, (i) {
          final isSelected = selectedAnswer == i;
          final isCorrect = i == question.correctIndex;

          Color tileColor;
          Color borderColor;
          if (answered && isCorrect) {
            tileColor = successColor.withAlpha(isDark ? 40 : 25);
            borderColor = successColor.withAlpha(100);
          } else if (answered && isSelected && !isCorrect) {
            tileColor = errorColor.withAlpha(isDark ? 40 : 25);
            borderColor = errorColor.withAlpha(100);
          } else if (isSelected) {
            tileColor = accentColor.withAlpha(isDark ? 40 : 20);
            borderColor = accentColor.withAlpha(80);
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
              child: RadioListTile<int>(
                value: i,
                title: Text(
                  question.options[i],
                  style: TextStyle(
                    fontWeight: (answered && isCorrect)
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: (answered && isCorrect)
                        ? successColor
                        : (answered && isSelected && !isCorrect)
                            ? errorColor
                            : colorScheme.onSurface,
                  ),
                ),
                activeColor:
                    answered ? (isCorrect ? successColor : errorColor) : accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusS),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Confirms a question has been scheduled, in place of the rating bar.
class RatedNotice extends StatelessWidget {
  final Color accentColor;
  final String label;

  const RatedNotice({
    super.key,
    required this.accentColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_outline, size: 16, color: accentColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}
