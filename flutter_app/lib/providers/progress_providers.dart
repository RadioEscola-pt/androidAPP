import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/progress.dart';
import '../models/question.dart';
import '../services/progress_storage.dart';
import '../services/spaced_repetition.dart';
import 'question_providers.dart';

final progressStorageProvider = Provider<ProgressStorage>((ref) {
  return ProgressStorage();
});

/// The persisted progress document.
///
/// Every mutation goes through [ProgressNotifier] so the stored copy and the
/// one on screen cannot disagree: the storage layer returns what it wrote, and
/// that becomes the new state.
class ProgressNotifier extends AsyncNotifier<UserProgress> {
  static const _uuid = Uuid();

  ProgressStorage get _storage => ref.read(progressStorageProvider);

  @override
  Future<UserProgress> build() => _storage.readOrEmpty();

  Future<void> recordAnswer({
    required Category category,
    required int questionId,
    required bool correct,
  }) async {
    state = AsyncData(await _storage.recordQuestionAttempt(
      category: category.id,
      questionId: questionId,
      correct: correct,
    ));
  }

  /// Records a self-rated review and schedules the question's next one.
  ///
  /// The SM-2 state is read from what is currently stored rather than from the
  /// widget's copy, so a rating given on a stale screen still schedules from
  /// the question's real history.
  Future<void> recordReview({
    required Category category,
    required int questionId,
    required ReviewQuality quality,
  }) async {
    final stored = await _storage.readOrEmpty();
    final current =
        stored.questionStats[questionStatsKey(category.id, questionId)]?.spacedRep;

    final result = calculateSm2(quality: quality.rating, current: current);

    state = AsyncData(await _storage.recordReview(
      category: category.id,
      questionId: questionId,
      spacedRep: result.stats,
      wasCorrect: result.wasCorrect,
    ));
  }

  Future<void> toggleBookmark({
    required Category category,
    required int questionId,
  }) async {
    state = AsyncData(await _storage.toggleBookmark(
      category: category.id,
      questionId: questionId,
    ));
  }

  Future<void> saveNotes({
    required Category category,
    required int questionId,
    required String notes,
  }) async {
    state = AsyncData(await _storage.saveQuestionNotes(
      category: category.id,
      questionId: questionId,
      notes: notes,
    ));
  }

  /// Records a finished exam.
  ///
  /// [timeSpent] is seconds elapsed, so the caller subtracts what the timer had
  /// left from the configured duration rather than passing the remainder.
  Future<void> recordExam({
    required Category category,
    required ExamState examState,
    required int timeSpent,
  }) async {
    final questions = examState.questions;
    final answers = <int, int>{};
    for (var i = 0; i < questions.length; i++) {
      if (examState.answers[i] != -1) {
        answers[questions[i].id] = examState.answers[i];
      }
    }

    state = AsyncData(await _storage.recordExamAttempt(ExamAttempt(
      // A UUID, matching the website's crypto.randomUUID(): merging exam
      // history dedupes on this id, so two devices must never mint the same
      // one.
      id: _uuid.v4(),
      category: category.id,
      score: examState.totalScore,
      totalQuestions: questions.length,
      correctCount: examState.correctCount,
      incorrectCount: examState.wrongCount,
      unansweredCount: examState.unansweredCount,
      timeSpent: timeSpent,
      passed: examState.passed,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      questionIds: questions.map((q) => q.id).toList(),
      answers: answers,
    )));
  }

  Future<void> clear() async {
    await _storage.clear();
    state = AsyncData(await _storage.readOrEmpty());
  }
}

final progressProvider =
    AsyncNotifierProvider<ProgressNotifier, UserProgress>(ProgressNotifier.new);

/// Stats for one question, or null while progress is still loading.
///
/// Reads the loaded document rather than hitting storage, so a screen showing
/// many questions does not read the store once per tile.
QuestionStats? questionStatsFor(
  UserProgress? progress,
  Category category,
  Question question,
) {
  return progress?.questionStats[questionStatsKey(category.id, question.id)];
}
