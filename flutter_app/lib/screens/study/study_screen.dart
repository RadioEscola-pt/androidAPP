import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/progress.dart';
import '../../models/question.dart';
import '../../providers/progress_providers.dart';
import '../../providers/question_providers.dart';
import '../../services/spaced_repetition.dart';
import '../../theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/question_view.dart';
import '../../widgets/review_rating_bar.dart';

class StudyScreen extends ConsumerStatefulWidget {
  final Category category;

  const StudyScreen({super.key, required this.category});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  int? _selectedAnswer;

  /// The interval the question was scheduled for, once rated. Null until then,
  /// which is also what stops the bar inviting a second rating that would
  /// schedule the same question twice.
  int? _ratedInterval;

  bool get _rated => _ratedInterval != null;

  bool get _answered => _selectedAnswer != null;

  Color get _accentColor => categoryAccentColor(widget.category.index);

  void _resetAnswer() {
    setState(() {
      _selectedAnswer = null;
      _ratedInterval = null;
    });
  }

  void _onRated(ReviewQuality quality, int interval, Question question) {
    if (_rated) return;
    setState(() => _ratedInterval = interval);
    ref.read(progressProvider.notifier).recordReview(
          category: widget.category,
          questionId: question.id,
          quality: quality,
        );
  }

  SpacedRepetitionStats? _srStatsFor(Question question) {
    final progress = ref.read(progressProvider).valueOrNull;
    return questionStatsFor(progress, widget.category, question)?.spacedRep;
  }

  void _onAnswerSelected(int index, Question question) {
    if (_answered) return;
    setState(() => _selectedAnswer = index);
    final correct = index == question.correctIndex;
    // Fire-and-forget: answering should not wait on a disk write, and a failed
    // write must not swallow the answer the user just gave.
    ref.read(progressProvider.notifier).recordAnswer(
          category: widget.category,
          questionId: question.id,
          correct: correct,
        );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsProvider(widget.category));
    final questionIndex = ref.watch(studyIndexProvider(widget.category));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.label),
        foregroundColor: Colors.white,
        backgroundColor: _accentColor,
        actions: [
          questionsAsync.maybeWhen(
            data: (questions) => questions.isEmpty
                ? const SizedBox.shrink()
                : _BookmarkAction(
                    category: widget.category,
                    question:
                        questions[questionIndex.clamp(0, questions.length - 1)],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
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
                      question, idx, questions.length),
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
  ) {
    return QuestionView(
      question: question,
      accentColor: _accentColor,
      positionLabel: 'Pergunta ${index + 1} de $totalQuestions',
      selectedAnswer: _selectedAnswer,
      onAnswer: (i) => _onAnswerSelected(i, question),
      footer: _rated
          ? RatedNotice(
              accentColor: _accentColor,
              label: 'Revisão em ${ReviewRatingBar.formatInterval(_ratedInterval!)}',
            )
          : ReviewRatingBar(
              current: _srStatsFor(question),
              onRated: (quality, interval) =>
                  _onRated(quality, interval, question),
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

/// Bookmark toggle for the question currently on screen.
class _BookmarkAction extends ConsumerWidget {
  final Category category;
  final Question question;

  const _BookmarkAction({required this.category, required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider).valueOrNull;
    final bookmarked =
        questionStatsFor(progress, category, question)?.bookmarked ?? false;

    return IconButton(
      tooltip: bookmarked ? 'Remover dos guardados' : 'Guardar pergunta',
      icon: Icon(
        bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      ),
      onPressed: () => ref.read(progressProvider.notifier).toggleBookmark(
            category: category,
            questionId: question.id,
          ),
    );
  }
}

/// Replaces the rating bar once the question has been scheduled.
