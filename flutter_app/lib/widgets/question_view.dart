import 'package:flutter/material.dart';

/// Displays a single question with optional image, radio-button answers,
/// correct/incorrect feedback, and an optional notes widget.
class QuestionView extends StatelessWidget {
  final String questionText;
  final String? imageAsset;
  final List<String> answers;
  final int? selectedAnswer;
  final int? correctAnswer;
  final bool showFeedback;
  final ValueChanged<int>? onAnswerSelected;
  final Widget? notesWidget;

  const QuestionView({
    super.key,
    required this.questionText,
    this.imageAsset,
    required this.answers,
    this.selectedAnswer,
    this.correctAnswer,
    this.showFeedback = false,
    this.onAnswerSelected,
    this.notesWidget,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),

          if (imageAsset != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Image.asset(
                  'assets/$imageAsset',
                  fit: BoxFit.contain,
                  width: double.infinity,
                  alignment: Alignment.topLeft,
                ),
              ),
            ),

          RadioGroup<int>(
            groupValue: selectedAnswer,
            onChanged: (value) {
              if (value != null && onAnswerSelected != null) {
                onAnswerSelected!(value);
              }
            },
            child: Column(
              children: List.generate(answers.length, (index) {
                final isSelected = selectedAnswer == index;
                final isCorrect = correctAnswer == index;

                Color? tileColor;
                if (showFeedback) {
                  if (isCorrect) {
                    tileColor = Colors.green.withAlpha(40);
                  } else if (isSelected && !isCorrect) {
                    tileColor = Colors.red.withAlpha(40);
                  }
                }

                return Container(
                  color: tileColor,
                  child: RadioListTile<int>(
                    value: index,
                    title: Text(
                      answers[index],
                      style: TextStyle(
                        color: showFeedback && isCorrect
                            ? Colors.green.shade800
                            : showFeedback && isSelected && !isCorrect
                                ? Colors.red.shade800
                                : null,
                        fontWeight:
                            showFeedback && isCorrect ? FontWeight.bold : null,
                      ),
                    ),
                    activeColor: showFeedback
                        ? (isCorrect ? Colors.green : Colors.red)
                        : null,
                    contentPadding: EdgeInsets.zero,
                  ),
                );
              }),
            ),
          ),

          if (notesWidget != null) ...[
            const SizedBox(height: 16),
            notesWidget!,
          ],
        ],
      ),
    );
  }
}
