import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/question.dart';
import '../../providers/progress_providers.dart';
import '../../providers/question_providers.dart';
import '../../theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/notes_container.dart';

class StudyScreen extends ConsumerStatefulWidget {
  final Category category;

  const StudyScreen({super.key, required this.category});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  int? _selectedAnswer;

  bool get _answered => _selectedAnswer != null;

  Color get _accentColor => categoryAccentColor(widget.category.index);

  void _resetAnswer() {
    setState(() => _selectedAnswer = null);
  }

  void _onAnswerSelected(int index, Question question) {
    if (_answered) return;
    setState(() => _selectedAnswer = index);
    final correct = index == question.correctIndex;
    // Fire-and-forget: the snackbar below should not wait on a disk write, and
    // a failed write must not swallow the answer the user just gave.
    ref.read(progressProvider.notifier).recordAnswer(
          category: widget.category,
          questionId: question.id,
          correct: correct,
        );
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                correct
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Correto!' : 'Incorreto',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          backgroundColor: correct ? successColor : errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusS)),
          margin: EdgeInsets.fromLTRB(
            16, 0, 16,
            76 + MediaQuery.of(context).padding.bottom,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsProvider(widget.category));
    final questionIndex = ref.watch(studyIndexProvider(widget.category));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.label),
        foregroundColor: Colors.white,
        backgroundColor: _accentColor,
      ),
      body: questionsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: _accentColor)),
        error: (err, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Não foi possível carregar as perguntas.\n'
              'Verifique a aplicação e tente novamente.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
                child: Text('Nenhuma pergunta disponível.'));
          }
          final idx = questionIndex.clamp(0, questions.length - 1);
          final question = questions[idx];
          final isFirst = idx == 0;
          final isLast = idx == questions.length - 1;
          final progress = (idx + 1) / questions.length;

          return Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: _accentColor.withAlpha(30),
                color: _accentColor,
                minHeight: 3,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      screenPaddingH, 16, screenPaddingH, 20),
                  child: _buildQuestionContent(
                      question, idx, questions.length, colorScheme),
                ),
              ),
              _buildNavigationBar(isFirst, isLast),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionContent(
    Question question,
    int index,
    int totalQuestions,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          'Pergunta ${index + 1} de $totalQuestions',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _accentColor,
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
        _buildAnswerOptions(question),
        if (_answered) ...[
          const SizedBox(height: 20),
          NotesContainer(
              notes: question.explanationHtml, accentColor: _accentColor),
        ],
      ],
    );
  }

  Widget _buildAnswerOptions(Question question) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RadioGroup<int>(
      groupValue: _selectedAnswer ?? -1,
      onChanged: (val) {
        if (!_answered && val != null) {
          _onAnswerSelected(val, question);
        }
      },
      child: Column(
        children: List.generate(question.options.length, (i) {
          final isSelected = _selectedAnswer == i;
          final isCorrect = i == question.correctIndex;

          Color tileColor;
          Color borderColor;
          if (_answered && isCorrect) {
            tileColor = successColor.withAlpha(isDark ? 40 : 25);
            borderColor = successColor.withAlpha(100);
          } else if (_answered && isSelected && !isCorrect) {
            tileColor = errorColor.withAlpha(isDark ? 40 : 25);
            borderColor = errorColor.withAlpha(100);
          } else if (isSelected) {
            tileColor = _accentColor.withAlpha(isDark ? 40 : 20);
            borderColor = _accentColor.withAlpha(80);
          } else {
            tileColor =
                colorScheme.surfaceContainerHighest.withAlpha(100);
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
                    fontWeight: (_answered && isCorrect)
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: (_answered && isCorrect)
                        ? successColor
                        : (_answered && isSelected && !isCorrect)
                            ? errorColor
                            : colorScheme.onSurface,
                  ),
                ),
                activeColor: _answered
                    ? (isCorrect ? successColor : errorColor)
                    : _accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusS),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationBar(bool isFirst, bool isLast) {
    return BottomNavBar(
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {
                  ref
                      .read(
                          studyIndexProvider(widget.category).notifier)
                      .state--;
                  _resetAnswer();
                },
                child: const Text('Voltar'),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 12),
          if (!isLast)
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ref
                      .read(
                          studyIndexProvider(widget.category).notifier)
                      .state++;
                  _resetAnswer();
                },
                child: const Text('Próximo'),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}
