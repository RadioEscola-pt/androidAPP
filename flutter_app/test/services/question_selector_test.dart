import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:radio_escola/models/progress.dart';
import 'package:radio_escola/models/question.dart';
import 'package:radio_escola/services/question_selector.dart';

const _now = 1700000000000;
const _day = Duration.millisecondsPerDay;

Question _question(int id) => Question(
      id: id,
      question: 'Question $id',
      options: const ['A', 'B'],
      correctIndex: 0,
    );

List<Question> _bank(int count) =>
    List.generate(count, (i) => _question(i + 1));

/// Stats for a question scheduled to come due [inDays] from now.
QuestionStats _scheduled({
  required int inDays,
  int attempts = 3,
  int correct = 2,
}) {
  return QuestionStats(
    attempts: attempts,
    correct: correct,
    lastAttempt: _now,
    spacedRep: SpacedRepetitionStats(
      interval: 5,
      easeFactor: 2.5,
      nextReviewDate: _now + inDays * _day,
      repetitionNumber: 2,
    ),
  );
}

/// Stats for a question answered but never rated, [daysAgo] days back.
QuestionStats _unrated({
  required int daysAgo,
  int attempts = 1,
  int correct = 1,
}) {
  return QuestionStats(
    attempts: attempts,
    correct: correct,
    lastAttempt: _now - daysAgo * _day,
  );
}

UserProgress _progress(Map<String, QuestionStats> stats) =>
    UserProgress(questionStats: stats);

List<int> _idsOf(List<PrioritisedQuestion> queue) =>
    queue.map((q) => q.question.id).toList();

void main() {
  group('priority assignment', () {
    test('a question past its review date is due now', () {
      final queue = selectQuestionsForReview(
        questions: _bank(1),
        progress: _progress({'cat1_1': _scheduled(inDays: -2)}),
        category: '1',
        now: _now,
      );

      expect(queue.single.priority, QuestionPriority.dueNow);
      expect(queue.single.daysUntilDue, -2);
    });

    test('a question never touched is new', () {
      final queue = selectQuestionsForReview(
        questions: _bank(1),
        progress: _progress({}),
        category: '1',
        now: _now,
      );

      expect(queue.single.priority, QuestionPriority.isNew);
    });

    test('a question due within three days is due soon', () {
      final queue = selectQuestionsForReview(
        questions: _bank(2),
        progress: _progress({
          'cat1_1': _scheduled(inDays: 3),
          'cat1_2': _scheduled(inDays: 4),
        }),
        category: '1',
        now: _now,
      );

      final byId = {for (final q in queue) q.question.id: q.priority};
      expect(byId[1], QuestionPriority.dueSoon);
      expect(byId[2], QuestionPriority.later);
    });

    test('an unrated question answered mostly wrong is weak', () {
      final queue = selectQuestionsForReview(
        questions: _bank(1),
        progress: _progress({
          'cat1_1': _unrated(daysAgo: 1, attempts: 4, correct: 1),
        }),
        category: '1',
        now: _now,
      );

      expect(queue.single.priority, QuestionPriority.weak);
    });

    test('an unrated question untouched for over a week is due soon', () {
      final queue = selectQuestionsForReview(
        questions: _bank(1),
        progress: _progress({'cat1_1': _unrated(daysAgo: 8)}),
        category: '1',
        now: _now,
      );

      expect(queue.single.priority, QuestionPriority.dueSoon);
    });

    test('a bookmark alone leaves the question new, not overdue', () {
      // The website only checks for a missing record, so a bookmark-only entry
      // reaches the staleness branch with lastAttempt 0 and is ranked as though
      // it were 19,000 days overdue.
      final queue = selectQuestionsForReview(
        questions: _bank(1),
        progress: _progress({
          'cat1_1': const QuestionStats(bookmarked: true, bookmarkedAt: 1),
        }),
        category: '1',
        now: _now,
      );

      expect(queue.single.priority, QuestionPriority.isNew);
      expect(queue.single.daysUntilDue, 0);
    });
  });

  group('ordering', () {
    test('serves tiers in order: due now, new, due soon, weak, later', () {
      final queue = selectQuestionsForReview(
        questions: _bank(5),
        progress: _progress({
          'cat1_1': _scheduled(inDays: 10), // later
          'cat1_2': _unrated(daysAgo: 1, attempts: 4, correct: 1), // weak
          'cat1_3': _scheduled(inDays: 2), // due soon
          // 4 has no record at all — new
          'cat1_5': _scheduled(inDays: -1), // due now
        }),
        category: '1',
        now: _now,
      );

      expect(_idsOf(queue), [5, 4, 3, 2, 1]);
    });

    test('most overdue first within the due tier', () {
      final queue = selectQuestionsForReview(
        questions: _bank(3),
        progress: _progress({
          'cat1_1': _scheduled(inDays: -1),
          'cat1_2': _scheduled(inDays: -9),
          'cat1_3': _scheduled(inDays: -4),
        }),
        category: '1',
        now: _now,
      );

      expect(_idsOf(queue), [2, 3, 1]);
    });

    test('worst success rate first within the weak tier', () {
      final queue = selectQuestionsForReview(
        questions: _bank(3),
        progress: _progress({
          'cat1_1': _unrated(daysAgo: 1, attempts: 10, correct: 5), // 50%
          'cat1_2': _unrated(daysAgo: 1, attempts: 10, correct: 1), // 10%
          'cat1_3': _unrated(daysAgo: 1, attempts: 10, correct: 3), // 30%
        }),
        category: '1',
        now: _now,
      );

      expect(_idsOf(queue), [2, 3, 1]);
    });
  });

  group('session size', () {
    test('caps the queue at the session size', () {
      final queue = selectQuestionsForReview(
        questions: _bank(100),
        progress: _progress({}),
        category: '1',
        now: _now,
      );

      expect(queue, hasLength(reviewSessionSize));
      expect(reviewSessionSize, 20);
    });

    test('honours a smaller target', () {
      final queue = selectQuestionsForReview(
        questions: _bank(100),
        progress: _progress({}),
        category: '1',
        targetCount: 5,
        now: _now,
      );

      expect(queue, hasLength(5));
    });

    test('returns everything when the bank is smaller than the target', () {
      final queue = selectQuestionsForReview(
        questions: _bank(3),
        progress: _progress({}),
        category: '1',
        now: _now,
      );

      expect(queue, hasLength(3));
    });

    test('is empty for an empty bank', () {
      expect(
        selectQuestionsForReview(
          questions: const [],
          progress: _progress({}),
          category: '1',
          now: _now,
        ),
        isEmpty,
      );
    });
  });

  group('category isolation', () {
    test('reads only the requested category\'s progress', () {
      // Same question id in another category must not schedule this one.
      final queue = selectQuestionsForReview(
        questions: _bank(1),
        progress: _progress({'cat2_1': _scheduled(inDays: -5)}),
        category: '1',
        now: _now,
      );

      expect(queue.single.priority, QuestionPriority.isNew);
    });
  });

  group('counts', () {
    test('tallies every question into exactly one tier', () {
      final progress = _progress({
        'cat1_1': _scheduled(inDays: -1),
        'cat1_2': _scheduled(inDays: 2),
        'cat1_3': _scheduled(inDays: 30),
        'cat1_4': _unrated(daysAgo: 1, attempts: 5, correct: 1),
      });

      final counts = questionCounts(
        questions: _bank(6),
        progress: progress,
        category: '1',
        now: _now,
      );

      expect(counts[QuestionPriority.dueNow], 1);
      expect(counts[QuestionPriority.dueSoon], 1);
      expect(counts[QuestionPriority.later], 1);
      expect(counts[QuestionPriority.weak], 1);
      expect(counts[QuestionPriority.isNew], 2);
      expect(counts.values.reduce((a, b) => a + b), 6);
    });

    test('due count is overdue plus nearly due, and excludes new', () {
      final counts = dueCount(
        questions: _bank(5),
        progress: _progress({
          'cat1_1': _scheduled(inDays: -1),
          'cat1_2': _scheduled(inDays: 1),
          'cat1_3': _scheduled(inDays: 60),
        }),
        category: '1',
        now: _now,
      );

      expect(counts, 2);
    });
  });

  group('parity with the website selector', () {
    // Generated by running the real selectQuestionsForReview from
    // lib/spaced-repetition/question-selector.ts over a bank spanning every
    // tier. A session started on either surface reads the same shared progress,
    // so the two must agree on what to serve and in what order.
    //
    // The fixture deliberately contains no bookmark-only entries: the app fixes
    // the site's handling of those, so they are the one case where the two are
    // meant to differ. That divergence is asserted separately above.
    final fixture = json.decode(
      File('test/fixtures/selector_reference.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final now = fixture['now'] as int;

    const day = Duration.millisecondsPerDay;
    QuestionStats sched(int inDays, [int attempts = 3, int correct = 2]) =>
        QuestionStats(
          attempts: attempts,
          correct: correct,
          lastAttempt: now,
          lastCorrect: true,
          spacedRep: SpacedRepetitionStats(
            interval: 5,
            easeFactor: 2.5,
            nextReviewDate: now + inDays * day,
            repetitionNumber: 2,
          ),
        );
    QuestionStats unrated(int daysAgo, [int attempts = 1, int correct = 1]) =>
        QuestionStats(
          attempts: attempts,
          correct: correct,
          lastAttempt: now - daysAgo * day,
          lastCorrect: true,
        );

    final progress = UserProgress(questionStats: {
      'cat1_1': sched(-1), 'cat1_2': sched(-9), 'cat1_3': sched(-4),
      'cat1_4': sched(2), 'cat1_5': sched(1), 'cat1_6': sched(3),
      'cat1_7': sched(30), 'cat1_8': sched(10),
      'cat1_9': unrated(1, 10, 1), 'cat1_10': unrated(1, 10, 5),
      'cat1_11': unrated(1, 10, 3),
      'cat1_12': unrated(20), 'cat1_13': unrated(9),
      'cat1_14': unrated(1, 3, 3), 'cat1_15': unrated(2, 1, 1),
    });

    const priorityNames = {
      QuestionPriority.dueNow: 'due-now',
      QuestionPriority.isNew: 'new',
      QuestionPriority.dueSoon: 'due-soon',
      QuestionPriority.weak: 'weak',
      QuestionPriority.later: 'later',
    };

    for (final target in [5, 20, 30]) {
      test('a $target-question session matches the TypeScript', () {
        final expected = (fixture['cases']['$target'] as List)
            .cast<Map<String, dynamic>>();

        final queue = selectQuestionsForReview(
          questions: _bank(30),
          progress: progress,
          category: '1',
          targetCount: target,
          now: now,
        );

        expect(_idsOf(queue), expected.map((e) => e['id']).toList());
        expect(
          queue.map((q) => priorityNames[q.priority]).toList(),
          expected.map((e) => e['priority']).toList(),
        );
        expect(
          queue.map((q) => q.daysUntilDue).toList(),
          expected.map((e) => e['daysUntilDue']).toList(),
        );
      });
    }
  });
}
