import 'package:flutter_test/flutter_test.dart';

import 'package:radio_escola/models/progress.dart';
import 'package:radio_escola/models/progress_queries.dart';

UserProgress _progress(Map<String, QuestionStats> stats, {UserStats? user}) {
  return UserProgress(
    questionStats: stats,
    stats: user ?? const UserStats(),
  );
}

QuestionStats _stats({
  int attempts = 0,
  int correct = 0,
  bool bookmarked = false,
  int? bookmarkedAt,
  SpacedRepetitionStats? spacedRep,
}) {
  return QuestionStats(
    attempts: attempts,
    correct: correct,
    bookmarked: bookmarked,
    bookmarkedAt: bookmarkedAt,
    spacedRep: spacedRep,
  );
}

void main() {
  group('weakQuestions', () {
    test('orders by success rate, worst first', () {
      final progress = _progress({
        'cat1_1': _stats(attempts: 4, correct: 3), // 75%
        'cat1_2': _stats(attempts: 4, correct: 1), // 25%
        'cat1_3': _stats(attempts: 4, correct: 2), // 50%
      });

      expect(
        weakQuestions(progress).map((r) => r.questionId),
        [2, 3, 1],
      );
    });

    test('ignores questions without enough attempts to judge', () {
      final progress = _progress({
        'cat1_1': _stats(attempts: 1, correct: 0),
        'cat1_2': _stats(attempts: 2, correct: 0),
      });

      expect(weakQuestions(progress).map((r) => r.questionId), [2]);
      expect(
        weakQuestions(progress, minAttempts: 1).map((r) => r.questionId),
        [1, 2],
      );
    });

    test('recovers category and id from the stat key', () {
      final progress = _progress({'cat3_207': _stats(attempts: 2, correct: 0)});

      final record = weakQuestions(progress).single;
      expect(record.category, '3');
      expect(record.questionId, 207);
      expect(record.successRate, 0);
    });

    test('skips malformed keys rather than throwing', () {
      final progress = _progress({
        'nonsense': _stats(attempts: 5, correct: 0),
        'cat1_9': _stats(attempts: 5, correct: 0),
      });

      expect(weakQuestions(progress).map((r) => r.questionId), [9]);
    });
  });

  group('bookmarkedQuestions', () {
    test('returns only bookmarked, most recent first', () {
      final progress = _progress({
        'cat1_1': _stats(bookmarked: true, bookmarkedAt: 100),
        'cat1_2': _stats(attempts: 3, correct: 3),
        'cat1_3': _stats(bookmarked: true, bookmarkedAt: 300),
        'cat2_4': _stats(bookmarked: true, bookmarkedAt: 200),
      });

      expect(
        bookmarkedQuestions(progress).map((r) => r.questionId),
        [3, 4, 1],
      );
    });

    test('is empty when nothing is bookmarked', () {
      expect(bookmarkedQuestions(_progress({})), isEmpty);
    });
  });

  group('categoryProgress', () {
    test('counts a question as mastered at 2+ correct and 70%+', () {
      final progress = _progress({
        'cat1_1': _stats(attempts: 2, correct: 2), // 100%, mastered
        'cat1_2': _stats(attempts: 3, correct: 2), // 67%, not mastered
        'cat1_3': _stats(attempts: 1, correct: 1), // only one correct
        'cat1_4': _stats(attempts: 10, correct: 8), // 80%, mastered
      });

      final result = categoryProgress(progress, '1', 100);
      expect(result.mastered, 2);
      expect(result.attempted, 4);
      expect(result.masteryRate, 0.02);
      expect(result.coverageRate, 0.04);
    });

    test('counts only the requested category', () {
      final progress = _progress({
        'cat1_1': _stats(attempts: 2, correct: 2),
        'cat2_1': _stats(attempts: 2, correct: 2),
        'cat3_1': _stats(attempts: 2, correct: 2),
      });

      expect(categoryProgress(progress, '2', 10).attempted, 1);
    });

    test('a bookmark alone does not count as an attempt', () {
      // The website counts any stat key with the right prefix, so bookmarking
      // a question never answered inflates its "attempted" number.
      final progress = _progress({
        'cat1_1': _stats(bookmarked: true, bookmarkedAt: 1),
      });

      final result = categoryProgress(progress, '1', 10);
      expect(result.attempted, 0);
      expect(result.mastered, 0);
    });

    test('does not divide by zero on an empty bank', () {
      expect(categoryProgress(_progress({}), '1', 0).masteryRate, 0);
    });
  });

  group('passRate', () {
    test('is zero before any exam is taken', () {
      expect(passRate(_progress({})), 0);
    });

    test('is the share of exams passed', () {
      final progress = _progress(
        {},
        user: const UserStats(totalExams: 4, totalPassed: 3),
      );

      expect(passRate(progress), 0.75);
    });
  });
}
