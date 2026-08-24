/// Chooses what to put in front of the learner next.
///
/// A port of `lib/spaced-repetition/question-selector.ts` from the website, so
/// a session started on either surface picks the same questions from the same
/// shared progress.
///
/// It walks the whole bank rather than only what SM-2 has scheduled, which is
/// what makes a session useful before anything has been rated: questions never
/// seen rank second, right behind ones that are actually overdue.
library;

import '../models/progress.dart';
import '../models/question.dart';
import 'spaced_repetition.dart';

/// Why a question was picked, in the order sessions serve them.
enum QuestionPriority {
  /// Scheduled by SM-2 and the date has passed.
  dueNow,

  /// Never attempted.
  isNew,

  /// Scheduled within the next three days, or answered long ago without ever
  /// being rated.
  dueSoon,

  /// Answered repeatedly and mostly wrong, but never rated.
  weak,

  /// Nothing to do with it yet.
  later,
}

class PrioritisedQuestion {
  final Question question;
  final QuestionPriority priority;

  /// Negative when overdue.
  final int daysUntilDue;

  final double successRate;
  final int attempts;

  const PrioritisedQuestion({
    required this.question,
    required this.priority,
    required this.daysUntilDue,
    required this.successRate,
    required this.attempts,
  });
}

/// How many questions a review session serves, matching the website's
/// SESSION_SIZE.
const int reviewSessionSize = 20;

/// A question rated within this many days is close enough to be worth serving.
const int _dueSoonDays = 3;

/// Below this success rate, a repeatedly-answered question counts as weak.
const double _weakThreshold = 0.6;

/// An unrated question untouched for this long is worth returning to.
const int _staleDays = 7;

({QuestionPriority priority, int daysUntilDue, double successRate})
    _prioritise(QuestionStats? stats, int now) {
  // No record, or a record created by bookmarking a question that was never
  // answered. The website only checks for a missing record, so a bookmark-only
  // entry falls through to the stale branch below and is served as though it
  // were badly overdue.
  if (stats == null || stats.attempts == 0) {
    return (priority: QuestionPriority.isNew, daysUntilDue: 0, successRate: 0);
  }

  final successRate = stats.correct / stats.attempts;
  final schedule = stats.spacedRep;

  if (schedule != null) {
    final days = daysUntilReview(schedule, now: now);
    final priority = days <= 0
        ? QuestionPriority.dueNow
        : days <= _dueSoonDays
            ? QuestionPriority.dueSoon
            : QuestionPriority.later;
    return (priority: priority, daysUntilDue: days, successRate: successRate);
  }

  // Answered before SM-2 ever saw it — in study mode, or on the website before
  // the schedule existed. Success rate and staleness stand in for a schedule.
  if (stats.attempts >= 2 && successRate < _weakThreshold) {
    return (
      priority: QuestionPriority.weak,
      daysUntilDue: 0,
      successRate: successRate
    );
  }

  final daysSinceAttempt =
      ((now - stats.lastAttempt) / Duration.millisecondsPerDay).floor();
  if (daysSinceAttempt > _staleDays) {
    return (
      priority: QuestionPriority.dueSoon,
      daysUntilDue: -daysSinceAttempt,
      successRate: successRate
    );
  }

  return (
    priority: QuestionPriority.later,
    daysUntilDue: _staleDays - daysSinceAttempt,
    successRate: successRate
  );
}

/// Builds a session queue for [category], most urgent first.
///
/// Callers should select once and hold the result: recording a review changes
/// the progress this reads, so re-running it mid-session would reorder the
/// queue under the learner.
List<PrioritisedQuestion> selectQuestionsForReview({
  required List<Question> questions,
  required UserProgress progress,
  required String category,
  int targetCount = reviewSessionSize,
  int? now,
}) {
  final at = now ?? DateTime.now().millisecondsSinceEpoch;

  final prioritised = questions.map((question) {
    final stats = progress.questionStats[questionStatsKey(category, question.id)];
    final p = _prioritise(stats, at);
    return PrioritisedQuestion(
      question: question,
      priority: p.priority,
      daysUntilDue: p.daysUntilDue,
      successRate: p.successRate,
      attempts: stats?.attempts ?? 0,
    );
  }).toList();

  prioritised.sort((a, b) {
    final byPriority = a.priority.index.compareTo(b.priority.index);
    if (byPriority != 0) return byPriority;

    // Within a tier: worst-performing weak questions first, most overdue
    // scheduled questions first.
    return switch (a.priority) {
      QuestionPriority.weak => a.successRate.compareTo(b.successRate),
      QuestionPriority.dueNow ||
      QuestionPriority.dueSoon =>
        a.daysUntilDue.compareTo(b.daysUntilDue),
      _ => 0,
    };
  });

  return prioritised.take(targetCount).toList();
}

/// How many questions sit in each tier, for showing what a session would hold.
Map<QuestionPriority, int> questionCounts({
  required List<Question> questions,
  required UserProgress progress,
  required String category,
  int? now,
}) {
  final at = now ?? DateTime.now().millisecondsSinceEpoch;
  final counts = {for (final p in QuestionPriority.values) p: 0};

  for (final question in questions) {
    final stats = progress.questionStats[questionStatsKey(category, question.id)];
    final priority = _prioritise(stats, at).priority;
    counts[priority] = counts[priority]! + 1;
  }

  return counts;
}

/// Questions worth reviewing now — overdue plus nearly due.
int dueCount({
  required List<Question> questions,
  required UserProgress progress,
  required String category,
  int? now,
}) {
  final counts = questionCounts(
    questions: questions,
    progress: progress,
    category: category,
    now: now,
  );
  return counts[QuestionPriority.dueNow]! + counts[QuestionPriority.dueSoon]!;
}
