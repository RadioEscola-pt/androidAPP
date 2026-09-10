import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/exam_config.dart';
import '../../models/progress.dart';
import '../../models/progress_queries.dart';
import '../../models/question.dart';
import '../../providers/progress_providers.dart';
import '../../providers/question_providers.dart';
import '../../services/question_selector.dart';
import '../../theme.dart';

/// Progress overview: streak, exam record, per-category mastery, what is due
/// for review, and the questions being got wrong most often.
///
/// Ordered by what should change the user's next action. The weak-questions
/// list is last but is the point of the screen — the site's design principle is
/// "weak areas first", and a dashboard that only congratulates is decoration.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressProvider);
    final bankAsync = ref.watch(allQuestionsProvider);
    final configAsync = ref.watch(examConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progresso'),
        foregroundColor: Colors.white,
        backgroundColor: brandColor,
        actions: [
          if (progressAsync.valueOrNull?.questionStats.isNotEmpty ?? false)
            IconButton(
              tooltip: 'Apagar progresso',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: switch ((progressAsync, bankAsync, configAsync)) {
        (
          AsyncData(value: final progress),
          AsyncData(value: final bank),
          AsyncData(value: final config)
        ) =>
          _Dashboard(progress: progress, bank: bank, config: config),
        (AsyncError(), _, _) || (_, AsyncError(), _) || (_, _, AsyncError()) =>
          const Center(child: Text('Não foi possível carregar o progresso.')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar progresso?'),
        content: const Text(
          'Isto apaga todas as respostas, exames e perguntas guardadas '
          'neste dispositivo. Não pode ser desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(progressProvider.notifier).clear();
    }
  }
}

class _Dashboard extends StatelessWidget {
  final UserProgress progress;
  final Map<Category, List<Question>> bank;
  final ExamConfig config;

  const _Dashboard({
    required this.progress,
    required this.bank,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final answered =
        progress.questionStats.values.where((s) => s.attempts > 0).length;

    if (answered == 0 && progress.stats.totalExams == 0) {
      return const _EmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          screenPaddingH, 16, screenPaddingH, 32),
      children: [
        _StreakCard(stats: progress.stats),
        const SizedBox(height: 20),
        _SectionTitle('Exames'),
        const SizedBox(height: 8),
        _ExamSummary(progress: progress, config: config),
        const SizedBox(height: 20),
        _SectionTitle('Por categoria'),
        const SizedBox(height: 8),
        for (final category in Category.values) ...[
          _CategoryRow(
            category: category,
            progress: categoryProgress(
              progress,
              category.id,
              bank[category]?.length ?? 0,
            ),
            // The selector's definition, so the number here is the work the
            // review session will actually serve.
            due: dueCount(
              questions: bank[category] ?? const [],
              progress: progress,
              category: category.id,
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        _SectionTitle('A rever'),
        const SizedBox(height: 8),
        _WeakQuestions(progress: progress, bank: bank),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights_outlined,
                size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Ainda sem progresso',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Responde a algumas perguntas ou faz um exame — '
              'o teu progresso aparece aqui.',
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

class _StreakCard extends StatelessWidget {
  final UserStats stats;

  const _StreakCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: brandColor.withAlpha(isDark ? 40 : 22),
        borderRadius: BorderRadius.circular(radiusM),
        border: Border.all(color: brandColor.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded,
              size: 36, color: brandColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.currentStreak == 1
                      ? '1 dia seguido'
                      : '${stats.currentStreak} dias seguidos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Melhor: ${stats.longestStreak}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamSummary extends StatelessWidget {
  final UserProgress progress;
  final ExamConfig config;

  const _ExamSummary({required this.progress, required this.config});

  @override
  Widget build(BuildContext context) {
    final stats = progress.stats;
    final colorScheme = Theme.of(context).colorScheme;

    if (stats.totalExams == 0) {
      return Text(
        'Ainda não fizeste nenhum exame.',
        style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
      );
    }

    final best = stats.bestScores.values.isEmpty
        ? null
        : stats.bestScores.values.reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
          child: _Stat(
            value: '${stats.totalExams}',
            label: stats.totalExams == 1 ? 'exame' : 'exames',
          ),
        ),
        Expanded(
          child: _Stat(
            value: '${(passRate(progress) * 100).round()}%',
            label: 'aprovação',
            // Green only once the record is actually a passing one.
            color: stats.totalPassed > 0 ? successColor : null,
          ),
        ),
        Expanded(
          child: _Stat(
            value: best == null ? '—' : _trimZero(best),
            label: 'melhor (de ${config.maxQuestions})',
            color: best != null && best >= config.passingScore
                ? successColor
                : null,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const _Stat({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color ?? colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  final CategoryProgress progress;
  final int due;

  const _CategoryRow({
    required this.category,
    required this.progress,
    required this.due,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = categoryAccentColor(category.index);

    // The due count is the reason to act, so the row that shows it is what
    // starts the session.
    return InkWell(
      onTap: () => context.push('/review/${category.name}'),
      borderRadius: BorderRadius.circular(radiusS),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: _content(context, colorScheme, accent),
      ),
    );
  }

  Widget _content(
      BuildContext context, ColorScheme colorScheme, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              category.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (due > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '$due a rever',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: warningColor,
                  ),
                ),
              ),
            Text(
              '${progress.mastered}/${progress.total}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              // Two bars: how much of the category has been seen at all, and
              // how much is actually mastered. Coverage without mastery is the
              // state worth noticing, and one bar cannot show it.
              LinearProgressIndicator(
                value: progress.coverageRate,
                minHeight: 8,
                backgroundColor: accent.withAlpha(25),
                color: accent.withAlpha(70),
              ),
              LinearProgressIndicator(
                value: progress.masteryRate,
                minHeight: 8,
                backgroundColor: Colors.transparent,
                color: accent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeakQuestions extends ConsumerWidget {
  final UserProgress progress;
  final Map<Category, List<Question>> bank;

  const _WeakQuestions({required this.progress, required this.bank});

  /// Enough to act on without turning the dashboard into a list screen.
  static const _limit = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final weak = weakQuestions(progress)
        .where((r) => r.successRate < 1)
        .take(_limit)
        .toList();

    if (weak.isEmpty) {
      return Text(
        'Nada a assinalar — responde a mais perguntas para veres '
        'onde precisas de treinar.',
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: [
        for (final record in weak)
          Builder(builder: (context) {
            final found =
                findQuestion(bank, record.category, record.questionId);
            if (found == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: colorScheme.surfaceContainerHighest.withAlpha(100),
                borderRadius: BorderRadius.circular(radiusS),
                child: InkWell(
                  borderRadius: BorderRadius.circular(radiusS),
                  onTap: () {
                    ref
                        .read(studyIndexProvider(found.category).notifier)
                        .state = found.index;
                    context.pushNamed('study', pathParameters: {
                      'category': found.category.name,
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            found.question.question,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(record.successRate * 100).round()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: record.successRate < 0.5
                                ? errorColor
                                : warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// 20.0 reads as "20", 19.75 stays "19.75".
String _trimZero(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
