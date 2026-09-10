import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/question_providers.dart';
import '../../theme.dart';
import '../../widgets/answer_tile.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/notes_container.dart';
import '../../widgets/share_result_card.dart';

class ExamResultView extends StatefulWidget {
  final ExamState examState;
  final Color accentColor;
  final String categoryLabel;

  const ExamResultView({
    super.key,
    required this.examState,
    required this.accentColor,
    required this.categoryLabel,
  });

  @override
  State<ExamResultView> createState() => _ExamResultViewState();
}

class _ExamResultViewState extends State<ExamResultView> {
  bool _reviewMode = false;
  int _reviewIndex = 0;
  final _shareCardKey = GlobalKey();

  // The finished exam is taken as it stands rather than rebuilt from its
  // parts: reconstructing it here dropped the ExamConfig, and with it the
  // rules used to decide whether the candidate passed.
  ExamState get _examState => widget.examState;

  Future<void> _shareResult() async {
    final bytes = await ShareResultCard.capture(_shareCardKey);
    if (bytes == null) return;

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes,
              name: 'resultado_exame.png', mimeType: 'image/png'),
        ],
        text: 'Fiz ${_examState.totalScore.toStringAsFixed(1)} pontos '
            'no exame de ${widget.categoryLabel}! '
            '#RádioEscola #RadioAmador',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_reviewMode ? 'Revisão' : 'Resultado'),
        foregroundColor: Colors.white,
        backgroundColor: widget.accentColor,
      ),
      body: Stack(
        children: [
          _reviewMode ? _buildReviewView() : _buildResultSummary(),
          // Offscreen share card for capture
          Positioned(
            left: -1000,
            child: ShareResultCard(
              repaintKey: _shareCardKey,
              score: _examState.totalScore,
              correct: _examState.correctCount,
              wrong: _examState.wrongCount,
              unanswered: _examState.unansweredCount,
              total: _examState.questions.length,
              categoryLabel: widget.categoryLabel,
              accentColor: widget.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSummary() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passed = _examState.passed;
    final scoreColor = passed ? successColor : errorColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withAlpha(isDark ? 40 : 20),
              border: Border.all(
                color: scoreColor.withAlpha(100),
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _examState.totalScore.toStringAsFixed(1),
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
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '${_examState.correctCount}',
                  label: 'Certas',
                  color: successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '${_examState.wrongCount}',
                  label: 'Erradas',
                  color: errorColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '${_examState.unansweredCount}',
                  label: 'Sem resposta',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: widget.accentColor,
              foregroundColor: Colors.white,
            ),
            onPressed: _shareResult,
            icon: const Icon(Icons.share_rounded, size: 20),
            label: const Text('Partilhar Resultado'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _reviewMode = true),
            child: const Text('Rever Respostas'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Voltar ao início'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewView() {
    final colorScheme = Theme.of(context).colorScheme;
    final question = _examState.questions[_reviewIndex];
    final selectedAnswer = _examState.answers[_reviewIndex];
    final correctIdx = question.correctIndex;
    final progress = (_reviewIndex + 1) / _examState.questions.length;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: widget.accentColor.withAlpha(30),
          color: widget.accentColor,
          minHeight: 3,
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Pergunta ${_reviewIndex + 1} de ${_examState.questions.length}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.accentColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                screenPaddingH, 0, screenPaddingH, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        constraints:
                            const BoxConstraints(maxHeight: 300),
                        child: Image.asset(
                          question.img!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ...List.generate(question.options.length, (i) {
                  return AnswerTile(
                    text: question.options[i],
                    index: i,
                    isSelected: i == selectedAnswer,
                    isCorrect: i == correctIdx,
                    showCorrectFeedback: true,
                    showWrongFeedback:
                        i == selectedAnswer && selectedAnswer != correctIdx,
                    accentColor: widget.accentColor,
                  );
                }),
                const SizedBox(height: 16),
                NotesContainer(
                  notes: question.explanationHtml,
                  accentColor: widget.accentColor,
                ),
              ],
            ),
          ),
        ),
        BottomNavBar(
          child: Row(
            children: [
              if (_reviewIndex > 0)
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () =>
                        setState(() => _reviewIndex--),
                    child: const Text('Voltar'),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 12),
              if (_reviewIndex < _examState.questions.length - 1)
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        setState(() => _reviewIndex++),
                    child: const Text('Próximo'),
                  ),
                )
              else
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        setState(() => _reviewMode = false),
                    child: const Text('Ver Resultado'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 30 : 15),
        borderRadius: BorderRadius.circular(radiusS),
        border: Border.all(color: color.withAlpha(isDark ? 50 : 30)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}
