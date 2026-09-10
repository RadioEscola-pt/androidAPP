import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/progress.dart';
import '../../models/question.dart';
import '../../providers/progress_providers.dart';
import '../../providers/question_providers.dart';
import '../../services/question_selector.dart';
import '../../services/spaced_repetition.dart';
import '../../theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/question_view.dart';
import '../../widgets/review_rating_bar.dart';

/// A spaced-repetition session: the scheduler picks what to show, in the order
/// it decides, until the queue is done.
///
/// This is what makes the SM-2 state mean anything. Study mode walks the bank
/// in editorial order, so the intervals it records are never read back; here
/// the schedule chooses.
///
/// Answer, then rate. Rating is what advances the queue, because the rating is
/// the point — a question answered but not rated has not been scheduled.
class ReviewScreen extends ConsumerStatefulWidget {
  final Category category;

  const ReviewScreen({super.key, required this.category});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  /// The queue, chosen once when the session starts.
  ///
  /// Held rather than recomputed because rating a question changes the progress
  /// the selector reads: re-running it would reorder the remaining questions
  /// underneath the learner, and could drop the one on screen.
  List<PrioritisedQuestion>? _queue;

  int _cursor = 0;
  int? _selectedAnswer;
  final _ratings = <ReviewQuality, int>{};

  Color get _accentColor => categoryAccentColor(widget.category.index);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildQueue());
  }

  Future<void> _buildQueue() async {
    final questions = await ref.read(questionsProvider(widget.category).future);
    final progress = await ref.read(progressProvider.future);
    if (!mounted) return;

    setState(() {
      _queue = selectQuestionsForReview(
        questions: questions,
        progress: progress,
        category: widget.category.id,
      );
    });
  }

  void _onRated(ReviewQuality quality, Question question) {
    ref.read(progressProvider.notifier).recordReview(
          category: widget.category,
          questionId: question.id,
          quality: quality,
        );

    setState(() {
      _ratings[quality] = (_ratings[quality] ?? 0) + 1;
      _cursor++;
      _selectedAnswer = null;
    });
  }

  SpacedRepetitionStats? _srStatsFor(Question question) {
    final progress = ref.read(progressProvider).valueOrNull;
    return questionStatsFor(progress, widget.category, question)?.spacedRep;
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queue;

    return Scaffold(
      appBar: AppBar(
        title: Text('Rever · ${widget.category.label}'),
        foregroundColor: Colors.white,
        backgroundColor: _accentColor,
      ),
      body: switch (queue) {
        null => Center(child: CircularProgressIndicator(color: _accentColor)),
        [] => _NothingToReview(accentColor: _accentColor),
        _ when _cursor >= queue.length => _SessionSummary(
            ratings: _ratings,
            accentColor: _accentColor,
            onRestart: () {
              setState(() {
                _queue = null;
                _cursor = 0;
                _ratings.clear();
                _selectedAnswer = null;
              });
              _buildQueue();
            },
          ),
        _ => _buildQuestion(queue),
      },
    );
  }

  Widget _buildQuestion(List<PrioritisedQuestion> queue) {
    final entry = queue[_cursor];
    final question = entry.question;

    return Column(
      children: [
        LinearProgressIndicator(
          value: _cursor / queue.length,
          backgroundColor: _accentColor.withAlpha(30),
          color: _accentColor,
          minHeight: 3,
        ),
        Expanded(
          child: SingleChildScrollView(
            // Keyed so scroll position resets between questions rather than
            // leaving the next one scrolled to the previous one's explanation.
            key: ValueKey(question.id),
            padding: const EdgeInsets.fromLTRB(
                screenPaddingH, 16, screenPaddingH, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PriorityChip(priority: entry.priority),
                QuestionView(
                  question: question,
                  accentColor: _accentColor,
                  positionLabel:
                      'Pergunta ${_cursor + 1} de ${queue.length}',
                  selectedAnswer: _selectedAnswer,
                  onAnswer: (i) => setState(() => _selectedAnswer = i),
                  footer: ReviewRatingBar(
                    current: _srStatsFor(question),
                    onRated: (quality, _) => _onRated(quality, question),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedAnswer == null)
          BottomNavBar(
            child: Text(
              'Escolhe uma resposta para veres a explicação.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Why the scheduler picked this question, so the order is not a mystery.
class _PriorityChip extends StatelessWidget {
  final QuestionPriority priority;

  const _PriorityChip({required this.priority});

  static const _labels = {
    QuestionPriority.dueNow: ('Para rever', warningColor),
    QuestionPriority.isNew: ('Nova', categoryCat2Color),
    QuestionPriority.dueSoon: ('Em breve', categoryCat2Color),
    QuestionPriority.weak: ('A precisar de treino', errorColor),
    QuestionPriority.later: ('Extra', successColor),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, color) = _labels[priority]!;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 50 : 25),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _NothingToReview extends StatelessWidget {
  final Color accentColor;

  const _NothingToReview({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all_rounded, size: 48, color: accentColor),
            const SizedBox(height: 16),
            Text(
              'Tudo em dia',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não há perguntas desta categoria para rever agora.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  final Map<ReviewQuality, int> ratings;
  final Color accentColor;
  final VoidCallback onRestart;

  const _SessionSummary({
    required this.ratings,
    required this.accentColor,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = ratings.values.fold(0, (sum, n) => sum + n);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Icon(Icons.check_circle_outline, size: 56, color: successColor),
                const SizedBox(height: 16),
                Text(
                  total == 1
                      ? '1 pergunta revista'
                      : '$total perguntas revistas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                for (final quality in ReviewQuality.values)
                  if ((ratings[quality] ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            quality.label,
                            style: TextStyle(
                              fontSize: 15,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${ratings[quality]}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
        BottomNavBar(
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => context.pop(),
                  child: const Text('Terminar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onRestart,
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
