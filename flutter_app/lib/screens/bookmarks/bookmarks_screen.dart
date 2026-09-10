import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/progress.dart';
import '../../models/progress_queries.dart';
import '../../models/question.dart';
import '../../providers/progress_providers.dart';
import '../../providers/question_providers.dart';
import '../../theme.dart';

/// Questions the user has saved, newest first.
///
/// Tapping one opens it in study mode rather than showing a read-only copy:
/// the reason to bookmark a question is to come back and work on it, and a
/// second rendering of a question would be a second thing to keep in step with
/// the study screen.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressProvider);
    final bankAsync = ref.watch(allQuestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardados'),
        foregroundColor: Colors.white,
        backgroundColor: brandColor,
      ),
      body: switch ((progressAsync, bankAsync)) {
        (AsyncData(value: final progress), AsyncData(value: final bank)) =>
          _BookmarkList(progress: progress, bank: bank),
        (AsyncError(), _) || (_, AsyncError()) => const _Message(
            icon: Icons.error_outline,
            title: 'Não foi possível carregar',
            body: 'Tenta novamente mais tarde.',
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _BookmarkList extends ConsumerWidget {
  final UserProgress progress;
  final Map<Category, List<Question>> bank;

  const _BookmarkList({required this.progress, required this.bank});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = bookmarkedQuestions(progress);

    if (records.isEmpty) {
      return const _Message(
        icon: Icons.bookmark_border_rounded,
        title: 'Sem perguntas guardadas',
        body: 'Toca no marcador enquanto estudas para guardar '
            'as perguntas a que queres voltar.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          screenPaddingH, 12, screenPaddingH, 24),
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final record = records[i];
        final found = findQuestion(bank, record.category, record.questionId);

        // A bookmark can outlive the question it points at, if ANACOM retires
        // one. Showing it as unavailable beats a crash or a silent omission,
        // and it can still be removed from here.
        if (found == null) {
          return _MissingTile(record: record);
        }

        return _BookmarkTile(
          record: record,
          category: found.category,
          question: found.question,
          onTap: () {
            ref.read(studyIndexProvider(found.category).notifier).state =
                found.index;
            context.pushNamed('study', pathParameters: {
              'category': found.category.name,
            });
          },
        );
      },
    );
  }
}

class _BookmarkTile extends ConsumerWidget {
  final QuestionRecord record;
  final Category category;
  final Question question;
  final VoidCallback onTap;

  const _BookmarkTile({
    required this.record,
    required this.category,
    required this.question,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = categoryAccentColor(category.index);

    return Material(
      color: colorScheme.surfaceContainerHighest.withAlpha(100),
      borderRadius: BorderRadius.circular(radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusM),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryChip(category: category, accent: accent),
                  const Spacer(),
                  if (record.stats.attempts > 0)
                    Text(
                      '${(record.successRate * 100).round()}% · '
                      '${record.stats.attempts} tentativas',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remover dos guardados',
                    icon: const Icon(Icons.bookmark_remove_outlined, size: 20),
                    onPressed: () =>
                        ref.read(progressProvider.notifier).toggleBookmark(
                              category: category,
                              questionId: question.id,
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                question.question,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingTile extends ConsumerWidget {
  final QuestionRecord record;

  const _MissingTile({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(radiusM),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline,
              size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pergunta ${record.questionId} da categoria ${record.category} '
              'já não existe no banco de perguntas.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final Color accent;

  const _CategoryChip({required this.category, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withAlpha(isDark ? 50 : 25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
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
