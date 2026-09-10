/// The ANACOM exam rules, generated from the website's `lib/config/exam.ts`.
///
/// These are loaded rather than declared because declaring them here is how
/// they drifted: the app scored a pass at any total above zero while the real
/// line is 20 of 40, so a candidate answering four questions correctly was told
/// they had passed. There is now one definition, and it is not this file.
class ExamConfig {
  /// Total exam duration.
  final Duration duration;

  /// Questions sampled for one exam.
  final int maxQuestions;

  /// Minimum score required to pass.
  final double passingScore;

  /// Subtracted from the total for each wrong answer.
  final double wrongAnswerPenalty;

  const ExamConfig({
    required this.duration,
    required this.maxQuestions,
    required this.passingScore,
    required this.wrongAnswerPenalty,
  });

  factory ExamConfig.fromJson(Map<String, dynamic> json) {
    return ExamConfig(
      duration: Duration(seconds: (json['DURATION_SECONDS'] as num).toInt()),
      maxQuestions: (json['MAX_QUESTIONS'] as num).toInt(),
      passingScore: (json['PASSING_SCORE'] as num).toDouble(),
      wrongAnswerPenalty: (json['WRONG_ANSWER_PENALTY'] as num).toDouble(),
    );
  }
}
