/// SM-2, the SuperMemo 2 scheduling algorithm.
///
/// A port of `lib/spaced-repetition/sm2.ts` from the website, kept
/// behaviour-identical so a question reviewed on either surface is scheduled
/// the same way and the shared `spacedRep` state stays meaningful across both.
///
/// The premise: each successful recall makes a memory last longer, by a factor
/// that depends on how hard the item is for that person. So rather than drilling
/// all 388 questions equally, each one comes back just before it would be
/// forgotten — easy ones drift out to months, missed ones return tomorrow.
library;

import '../models/progress.dart';

/// How well the question was recalled, 0 (blank) to 5 (perfect).
typedef QualityRating = int;

/// The four ratings the UI offers, mapped onto the 0–5 scale SM-2 expects.
enum ReviewQuality {
  /// Failed — show it again soon.
  again(1, 'Outra vez'),

  /// Correct, but it was hard work.
  hard(3, 'Difícil'),

  /// Correct with some effort.
  good(4, 'Bom'),

  /// Perfect recall.
  easy(5, 'Fácil');

  const ReviewQuality(this.rating, this.label);

  final QualityRating rating;
  final String label;
}

class Sm2Config {
  static const double minEaseFactor = 1.3;
  static const double maxEaseFactor = 2.5;
  static const double initialEaseFactor = 2.5;
  static const int initialInterval = 1;

  /// Ceiling on how far out a review can be pushed.
  static const int maxInterval = 365;
}

/// Anything at or above this counts as a successful recall.
const QualityRating _passingQuality = 3;

class Sm2Result {
  final SpacedRepetitionStats stats;
  final bool wasCorrect;

  const Sm2Result({required this.stats, required this.wasCorrect});
}

SpacedRepetitionStats _initialStats(int now) => SpacedRepetitionStats(
      interval: Sm2Config.initialInterval,
      easeFactor: Sm2Config.initialEaseFactor,
      // Due immediately: a question never seen is always ready to be asked.
      nextReviewDate: now,
      repetitionNumber: 0,
    );

/// Schedules the next review of a question.
///
/// [current] is null the first time a question is reviewed. [now] is injectable
/// so the schedule can be asserted without waiting for real time to pass.
Sm2Result calculateSm2({
  required QualityRating quality,
  SpacedRepetitionStats? current,
  int? now,
}) {
  final at = now ?? DateTime.now().millisecondsSinceEpoch;
  final stats = current ?? _initialStats(at);
  final wasCorrect = quality >= _passingQuality;

  // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
  final miss = 5 - quality;
  final efDelta = 0.1 - miss * (0.08 + miss * 0.02);
  var easeFactor = (stats.easeFactor + efDelta)
      .clamp(Sm2Config.minEaseFactor, Sm2Config.maxEaseFactor);

  int interval;
  int repetitionNumber;

  if (!wasCorrect) {
    // Failed recall restarts the ladder. The ease factor drops by a fixed 0.2
    // rather than by the formula above, which would fall much faster and make
    // a question that was missed once behave as if it were never learned.
    interval = 1;
    repetitionNumber = 1;
    easeFactor = (stats.easeFactor - 0.2).clamp(
      Sm2Config.minEaseFactor,
      Sm2Config.maxEaseFactor,
    );
  } else {
    repetitionNumber = stats.repetitionNumber + 1;

    // The first two intervals are fixed; only afterwards does the ease factor
    // take over, which is what makes the gaps personal to the learner.
    interval = switch (repetitionNumber) {
      1 => 1,
      2 => 3,
      _ => (stats.interval * easeFactor).round(),
    };

    if (quality == ReviewQuality.easy.rating) {
      interval = (interval * 1.1).round();
    }
  }

  if (interval > Sm2Config.maxInterval) interval = Sm2Config.maxInterval;

  return Sm2Result(
    wasCorrect: wasCorrect,
    stats: SpacedRepetitionStats(
      interval: interval,
      easeFactor: easeFactor,
      nextReviewDate: at + interval * Duration.millisecondsPerDay,
      repetitionNumber: repetitionNumber,
    ),
  );
}

/// Whether a question is ready to be asked again.
///
/// A question with no scheduling state has never been reviewed, so it is due —
/// that is how new material enters the rotation.
bool isReviewDue(SpacedRepetitionStats? stats, {int? now}) {
  if (stats == null) return true;
  return (now ?? DateTime.now().millisecondsSinceEpoch) >= stats.nextReviewDate;
}

/// Days until the next review; negative when overdue, 0 for a new question.
int daysUntilReview(SpacedRepetitionStats? stats, {int? now}) {
  if (stats == null) return 0;
  final at = now ?? DateTime.now().millisecondsSinceEpoch;
  return ((stats.nextReviewDate - at) / Duration.millisecondsPerDay).ceil();
}

/// What each button would do to the interval, so the choice is not a guess.
Map<ReviewQuality, int> intervalPreviews(SpacedRepetitionStats? current,
    {int? now}) {
  return {
    for (final quality in ReviewQuality.values)
      quality: calculateSm2(
        quality: quality.rating,
        current: current,
        now: now,
      ).stats.interval,
  };
}
