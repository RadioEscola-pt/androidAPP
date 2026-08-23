/// User progress, in the same shape the website stores under
/// `localStorage["hamradio_progress"]`.
///
/// The shape is deliberately not redesigned for Dart. Both sides are meant to
/// exchange progress eventually — today by export/import, later by sync — and
/// that is only mechanical while a payload written by one reads cleanly in the
/// other. `lib/types/progress.ts` in the hamradiostudy repo is the definition;
/// this file follows it, including its key names and its version number.
///
/// Two rules keep the round trip lossless:
///
/// - Unknown fields survive. Anything this app does not model — gamification
///   today, whatever the site adds tomorrow — is kept as raw JSON and written
///   back untouched. Dropping it would mean a phone that opens the app quietly
///   destroys state the website owns.
/// - Exam attempts carry a UUID, matching the site's `crypto.randomUUID()`.
///   Merging dedupes on that id, so two devices must never mint the same one.
library;

/// Bumped in lockstep with `PROGRESS_VERSION` on the website.
const int progressVersion = 4;

/// SM-2 scheduling state for a single question.
class SpacedRepetitionStats {
  /// Days until the next review.
  final int interval;

  /// Difficulty multiplier, 1.3–2.5.
  final double easeFactor;

  /// When this question is next due, as a Unix timestamp in milliseconds.
  final int nextReviewDate;

  /// Which repetition in the sequence this is.
  final int repetitionNumber;

  const SpacedRepetitionStats({
    required this.interval,
    required this.easeFactor,
    required this.nextReviewDate,
    required this.repetitionNumber,
  });

  factory SpacedRepetitionStats.fromJson(Map<String, dynamic> json) {
    return SpacedRepetitionStats(
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      nextReviewDate: (json['nextReviewDate'] as num?)?.toInt() ?? 0,
      repetitionNumber: (json['repetitionNumber'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'interval': interval,
        'easeFactor': easeFactor,
        'nextReviewDate': nextReviewDate,
        'repetitionNumber': repetitionNumber,
      };
}

/// What is known about one question, keyed by [questionStatsKey].
class QuestionStats {
  final int attempts;
  final int correct;
  final int lastAttempt;
  final bool lastCorrect;
  final SpacedRepetitionStats? spacedRep;
  final bool bookmarked;
  final String? notes;
  final int? bookmarkedAt;

  const QuestionStats({
    this.attempts = 0,
    this.correct = 0,
    this.lastAttempt = 0,
    this.lastCorrect = false,
    this.spacedRep,
    this.bookmarked = false,
    this.notes,
    this.bookmarkedAt,
  });

  QuestionStats copyWith({
    int? attempts,
    int? correct,
    int? lastAttempt,
    bool? lastCorrect,
    SpacedRepetitionStats? spacedRep,
    bool? bookmarked,
    String? notes,
    int? bookmarkedAt,
    bool clearBookmarkedAt = false,
  }) {
    return QuestionStats(
      attempts: attempts ?? this.attempts,
      correct: correct ?? this.correct,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      lastCorrect: lastCorrect ?? this.lastCorrect,
      spacedRep: spacedRep ?? this.spacedRep,
      bookmarked: bookmarked ?? this.bookmarked,
      notes: notes ?? this.notes,
      bookmarkedAt:
          clearBookmarkedAt ? null : (bookmarkedAt ?? this.bookmarkedAt),
    );
  }

  factory QuestionStats.fromJson(Map<String, dynamic> json) {
    final sr = json['spacedRep'];
    return QuestionStats(
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      lastAttempt: (json['lastAttempt'] as num?)?.toInt() ?? 0,
      lastCorrect: json['lastCorrect'] as bool? ?? false,
      spacedRep: sr is Map<String, dynamic>
          ? SpacedRepetitionStats.fromJson(sr)
          : null,
      bookmarked: json['bookmarked'] as bool? ?? false,
      notes: json['notes'] as String?,
      bookmarkedAt: (json['bookmarkedAt'] as num?)?.toInt(),
    );
  }

  /// Optional fields are omitted rather than written as null, matching the
  /// website, where they are absent keys on a TypeScript optional.
  Map<String, dynamic> toJson() {
    return {
      'attempts': attempts,
      'correct': correct,
      'lastAttempt': lastAttempt,
      'lastCorrect': lastCorrect,
      if (spacedRep != null) 'spacedRep': spacedRep!.toJson(),
      if (bookmarked) 'bookmarked': true,
      if (notes != null) 'notes': notes,
      if (bookmarkedAt != null) 'bookmarkedAt': bookmarkedAt,
    };
  }
}

/// One completed exam. [id] is a UUID so merges can dedupe across devices.
class ExamAttempt {
  final String id;
  final String category;
  final double score;
  final int totalQuestions;
  final int correctCount;
  final int incorrectCount;
  final int unansweredCount;

  /// Seconds spent on the exam.
  final int timeSpent;

  final bool passed;
  final int timestamp;
  final List<int> questionIds;

  /// Question id -> selected option index.
  final Map<int, int> answers;

  const ExamAttempt({
    required this.id,
    required this.category,
    required this.score,
    required this.totalQuestions,
    required this.correctCount,
    required this.incorrectCount,
    required this.unansweredCount,
    required this.timeSpent,
    required this.passed,
    required this.timestamp,
    required this.questionIds,
    required this.answers,
  });

  factory ExamAttempt.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? const {};
    return ExamAttempt(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      incorrectCount: (json['incorrectCount'] as num?)?.toInt() ?? 0,
      unansweredCount: (json['unansweredCount'] as num?)?.toInt() ?? 0,
      timeSpent: (json['timeSpent'] as num?)?.toInt() ?? 0,
      passed: json['passed'] as bool? ?? false,
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      questionIds: (json['questionIds'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      // JSON object keys are strings; the website's Record<number, number>
      // serialises the same way, so the ids are parsed back here.
      answers: rawAnswers.map(
        (k, v) => MapEntry(int.parse(k), (v as num).toInt()),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'score': score,
        'totalQuestions': totalQuestions,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'unansweredCount': unansweredCount,
        'timeSpent': timeSpent,
        'passed': passed,
        'timestamp': timestamp,
        'questionIds': questionIds,
        'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      };
}

/// Aggregate counters shown on the progress surfaces.
class UserStats {
  final int totalExams;
  final int totalPassed;

  /// Category id -> best score.
  final Map<String, double> bestScores;

  final int currentStreak;
  final int longestStreak;

  /// `YYYY-MM-DD` in local time, or null before the first study day.
  final String? lastStudyDate;

  const UserStats({
    this.totalExams = 0,
    this.totalPassed = 0,
    this.bestScores = const {},
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudyDate,
  });

  UserStats copyWith({
    int? totalExams,
    int? totalPassed,
    Map<String, double>? bestScores,
    int? currentStreak,
    int? longestStreak,
    String? lastStudyDate,
  }) {
    return UserStats(
      totalExams: totalExams ?? this.totalExams,
      totalPassed: totalPassed ?? this.totalPassed,
      bestScores: bestScores ?? this.bestScores,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
    );
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final scores = json['bestScores'] as Map<String, dynamic>? ?? const {};
    return UserStats(
      totalExams: (json['totalExams'] as num?)?.toInt() ?? 0,
      totalPassed: (json['totalPassed'] as num?)?.toInt() ?? 0,
      bestScores: scores.map((k, v) => MapEntry(k, (v as num).toDouble())),
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      lastStudyDate: json['lastStudyDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalExams': totalExams,
        'totalPassed': totalPassed,
        'bestScores': bestScores,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastStudyDate': lastStudyDate,
      };
}

/// The whole persisted document.
class UserProgress {
  final int version;
  final int lastUpdated;
  final Map<String, QuestionStats> questionStats;

  /// Most recent first, as the website stores it.
  final List<ExamAttempt> examHistory;

  final UserStats stats;

  /// Fields this app does not model, carried through verbatim.
  ///
  /// Gamification is the one that exists today. The app awards no XP and shows
  /// no achievements, but a user who studies on both surfaces must not lose
  /// what the website recorded simply because the phone saved after them.
  final Map<String, dynamic> passthrough;

  const UserProgress({
    this.version = progressVersion,
    this.lastUpdated = 0,
    this.questionStats = const {},
    this.examHistory = const [],
    this.stats = const UserStats(),
    this.passthrough = const {},
  });

  UserProgress copyWith({
    int? lastUpdated,
    Map<String, QuestionStats>? questionStats,
    List<ExamAttempt>? examHistory,
    UserStats? stats,
  }) {
    return UserProgress(
      version: version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      questionStats: questionStats ?? this.questionStats,
      examHistory: examHistory ?? this.examHistory,
      stats: stats ?? this.stats,
      passthrough: passthrough,
    );
  }

  /// Keys this class owns; everything else in the document is [passthrough].
  static const _knownKeys = {
    'version',
    'lastUpdated',
    'questionStats',
    'examHistory',
    'stats',
  };

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final rawStats = json['questionStats'] as Map<String, dynamic>? ?? const {};
    return UserProgress(
      version: (json['version'] as num?)?.toInt() ?? progressVersion,
      lastUpdated: (json['lastUpdated'] as num?)?.toInt() ?? 0,
      questionStats: rawStats.map(
        (k, v) => MapEntry(k, QuestionStats.fromJson(v as Map<String, dynamic>)),
      ),
      examHistory: (json['examHistory'] as List?)
              ?.map((e) => ExamAttempt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      stats: UserStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? const {},
      ),
      passthrough: {
        for (final entry in json.entries)
          if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
      },
    );
  }

  Map<String, dynamic> toJson() => {
        ...passthrough,
        'version': version,
        'lastUpdated': lastUpdated,
        'questionStats': questionStats.map((k, v) => MapEntry(k, v.toJson())),
        'examHistory': examHistory.map((e) => e.toJson()).toList(),
        'stats': stats.toJson(),
      };
}

/// Matches the website's `getQuestionKey`, so both index the same map.
String questionStatsKey(String category, int questionId) =>
    'cat${category}_$questionId';
