import 'progress.dart';
import '../services/spaced_repetition.dart';

/// Read-only views over a loaded [UserProgress].
///
/// These mirror the helpers in the website's `lib/storage/localStorage.ts` so
/// both surfaces describe the same progress the same way. They take the already
/// loaded document rather than reading storage, so a screen rendering a list of
/// questions does not hit the store once per row.

/// One question's record, with its identity recovered from the stat key.
class QuestionRecord {
  final String category;
  final int questionId;
  final QuestionStats stats;

  const QuestionRecord({
    required this.category,
    required this.questionId,
    required this.stats,
  });

  /// Share of attempts answered correctly, 0 when never attempted.
  double get successRate => stats.attempts == 0 ? 0 : stats.correct / stats.attempts;
}

/// Parses a `cat{n}_{id}` key back into its parts, or null if malformed.
QuestionRecord? _record(String key, QuestionStats stats) {
  final match = RegExp(r'^cat(\d+)_(\d+)$').firstMatch(key);
  if (match == null) return null;
  return QuestionRecord(
    category: match.group(1)!,
    questionId: int.parse(match.group(2)!),
    stats: stats,
  );
}

Iterable<QuestionRecord> _records(UserProgress progress) sync* {
  for (final entry in progress.questionStats.entries) {
    final record = _record(entry.key, entry.value);
    if (record != null) yield record;
  }
}

/// Questions answered at least [minAttempts] times, worst success rate first.
List<QuestionRecord> weakQuestions(
  UserProgress progress, {
  int minAttempts = 2,
}) {
  final weak = _records(progress)
      .where((r) => r.stats.attempts >= minAttempts)
      .toList()
    ..sort((a, b) => a.successRate.compareTo(b.successRate));
  return weak;
}

/// Bookmarked questions, most recently bookmarked first.
List<QuestionRecord> bookmarkedQuestions(UserProgress progress) {
  final marked = _records(progress).where((r) => r.stats.bookmarked).toList()
    ..sort((a, b) =>
        (b.stats.bookmarkedAt ?? 0).compareTo(a.stats.bookmarkedAt ?? 0));
  return marked;
}

/// Questions in [category] whose review is due, including ones never seen.
List<QuestionRecord> dueForReview(
  UserProgress progress,
  String category, {
  int? now,
}) {
  return _records(progress)
      .where((r) =>
          r.category == category &&
          r.stats.attempts > 0 &&
          isReviewDue(r.stats.spacedRep, now: now))
      .toList();
}

class CategoryProgress {
  /// Questions answered correctly at least twice, at a 70%+ success rate.
  final int mastered;

  /// Questions attempted at least once.
  final int attempted;

  /// Questions in the category's bank.
  final int total;

  const CategoryProgress({
    required this.mastered,
    required this.attempted,
    required this.total,
  });

  double get masteryRate => total == 0 ? 0 : mastered / total;
  double get coverageRate => total == 0 ? 0 : attempted / total;
}

/// How far through a category the user is.
///
/// Unlike the website's version, a question that was only ever bookmarked does
/// not count as attempted. There, any stat key with the right prefix increments
/// `attempted`, so bookmarking inflated the number without an answer given.
CategoryProgress categoryProgress(
  UserProgress progress,
  String category,
  int totalQuestions,
) {
  var mastered = 0;
  var attempted = 0;

  for (final record in _records(progress)) {
    if (record.category != category || record.stats.attempts == 0) continue;
    attempted++;
    if (record.stats.correct >= 2 && record.successRate >= 0.7) mastered++;
  }

  return CategoryProgress(
    mastered: mastered,
    attempted: attempted,
    total: totalQuestions,
  );
}

/// Share of exams taken that were passes, 0 when none have been taken.
double passRate(UserProgress progress) {
  final total = progress.stats.totalExams;
  return total == 0 ? 0 : progress.stats.totalPassed / total;
}
