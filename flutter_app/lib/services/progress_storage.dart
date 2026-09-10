import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress.dart';

/// Reads and writes the progress document.
///
/// The storage key and the JSON shape are the website's, so a document written
/// here is one the site can import and vice versa. See [UserProgress] for why
/// that matters and what keeps it true.
///
/// Every mutation is read-modify-write against what is currently stored rather
/// than against a snapshot held in memory. The website does the same, for the
/// same reason: two writes racing on a stale copy silently drop one of them.
class ProgressStorage {
  /// The key the website uses in localStorage.
  static const storageKey = 'hamradio_progress';

  /// Injected in tests; production uses the platform store.
  final Future<SharedPreferences> Function() _prefs;

  ProgressStorage({Future<SharedPreferences> Function()? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance;

  Future<UserProgress?> read() async {
    final stored = (await _prefs()).getString(storageKey);
    if (stored == null) return null;
    try {
      return UserProgress.fromJson(
        json.decode(stored) as Map<String, dynamic>,
      );
    } on FormatException {
      // Unreadable progress is left in place rather than overwritten: a parse
      // failure is far more likely to be a bug here than a corrupt document,
      // and clearing it would destroy the user's history to hide the bug.
      return null;
    }
  }

  Future<void> write(UserProgress progress) async {
    final stamped = progress.copyWith(lastUpdated: _now());
    await (await _prefs()).setString(storageKey, json.encode(stamped.toJson()));
  }

  Future<UserProgress> readOrEmpty() async =>
      await read() ?? UserProgress(lastUpdated: _now());

  /// Records one answer in study mode.
  ///
  /// Unlike the website's version, this preserves the bookmark and personal
  /// notes on the question. There, answering a question you had bookmarked
  /// rebuilt the stats object from a fixed field list and silently dropped
  /// `bookmarked`, `notes` and `bookmarkedAt`.
  Future<UserProgress> recordQuestionAttempt({
    required String category,
    required int questionId,
    required bool correct,
    int? timestamp,
  }) async {
    final at = timestamp ?? _now();
    final progress = await readOrEmpty();
    final key = questionStatsKey(category, questionId);
    final existing = progress.questionStats[key];

    final updated = existing == null
        ? QuestionStats(
            attempts: 1,
            correct: correct ? 1 : 0,
            lastAttempt: at,
            lastCorrect: correct,
          )
        : existing.copyWith(
            attempts: existing.attempts + 1,
            correct: existing.correct + (correct ? 1 : 0),
            lastAttempt: at,
            lastCorrect: correct,
          );

    final next = progress.copyWith(
      questionStats: {...progress.questionStats, key: updated},
      stats: _withStreak(progress.stats, at),
    );
    await write(next);
    return next;
  }

  /// Records a finished exam, newest first.
  Future<UserProgress> recordExamAttempt(ExamAttempt attempt) async {
    final progress = await readOrEmpty();
    final best = progress.stats.bestScores[attempt.category];

    final next = progress.copyWith(
      examHistory: [attempt, ...progress.examHistory],
      stats: _withStreak(
        progress.stats.copyWith(
          totalExams: progress.stats.totalExams + 1,
          totalPassed: progress.stats.totalPassed + (attempt.passed ? 1 : 0),
          bestScores: {
            ...progress.stats.bestScores,
            if (best == null || attempt.score > best)
              attempt.category: attempt.score,
          },
        ),
        attempt.timestamp,
      ),
    );
    await write(next);
    return next;
  }

  /// Records a spaced-repetition review: counts the attempt and stores the
  /// schedule SM-2 produced for the question.
  Future<UserProgress> recordReview({
    required String category,
    required int questionId,
    required SpacedRepetitionStats spacedRep,
    required bool wasCorrect,
    int? timestamp,
  }) async {
    final at = timestamp ?? _now();
    final progress = await readOrEmpty();
    final key = questionStatsKey(category, questionId);
    final existing = progress.questionStats[key] ?? const QuestionStats();

    final next = progress.copyWith(
      questionStats: {
        ...progress.questionStats,
        key: existing.copyWith(
          attempts: existing.attempts + 1,
          correct: existing.correct + (wasCorrect ? 1 : 0),
          lastAttempt: at,
          lastCorrect: wasCorrect,
          spacedRep: spacedRep,
        ),
      },
      stats: _withStreak(progress.stats, at),
    );
    await write(next);
    return next;
  }

  Future<UserProgress> saveQuestionNotes({
    required String category,
    required int questionId,
    required String notes,
  }) async {
    final progress = await readOrEmpty();
    final key = questionStatsKey(category, questionId);
    final existing = progress.questionStats[key] ?? const QuestionStats();

    final next = progress.copyWith(
      questionStats: {
        ...progress.questionStats,
        key: existing.copyWith(notes: notes),
      },
    );
    await write(next);
    return next;
  }

  Future<UserProgress> toggleBookmark({
    required String category,
    required int questionId,
  }) async {
    final progress = await readOrEmpty();
    final key = questionStatsKey(category, questionId);
    final existing = progress.questionStats[key] ?? const QuestionStats();
    final bookmarked = !existing.bookmarked;

    final next = progress.copyWith(
      questionStats: {
        ...progress.questionStats,
        key: existing.copyWith(
          bookmarked: bookmarked,
          bookmarkedAt: bookmarked ? _now() : null,
          clearBookmarkedAt: !bookmarked,
        ),
      },
    );
    await write(next);
    return next;
  }

  Future<void> clear() async => (await _prefs()).remove(storageKey);

  int _now() => DateTime.now().millisecondsSinceEpoch;

  /// Extends, holds or resets the study streak for the day [at] falls on.
  ///
  /// Compares calendar days rather than elapsed milliseconds so a session at
  /// 23:50 followed by one at 00:10 counts as two consecutive days, and so a
  /// daylight-saving shift cannot make a day 23 or 25 hours long and break it.
  UserStats _withStreak(UserStats stats, int at) {
    final today = _localDateString(DateTime.fromMillisecondsSinceEpoch(at));
    final last = stats.lastStudyDate;

    if (last == today) return stats;
    if (last == null) {
      return stats.copyWith(
        currentStreak: 1,
        longestStreak: stats.longestStreak < 1 ? 1 : stats.longestStreak,
        lastStudyDate: today,
      );
    }

    final gap = DateTime.parse(today).difference(DateTime.parse(last)).inDays;
    final current = gap == 1 ? stats.currentStreak + 1 : 1;

    return stats.copyWith(
      currentStreak: current,
      longestStreak: current > stats.longestStreak ? current : stats.longestStreak,
      lastStudyDate: today,
    );
  }

  /// `YYYY-MM-DD` in local time, matching the website's `toLocalDateString`.
  static String _localDateString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
