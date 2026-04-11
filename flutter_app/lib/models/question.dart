class Question {
  final String question;
  final List<String> answers;
  final int correctIndex; // 1-based (from JSON)
  final String notes;
  final String? img;
  final int uniqueID;

  const Question({
    required this.question,
    required this.answers,
    required this.correctIndex,
    required this.notes,
    this.img,
    required this.uniqueID,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] as String,
      answers: List<String>.from(json['answers'] as List),
      correctIndex: json['correctIndex'] as int,
      notes: json['notes'] as String,
      img: json['img'] as String?,
      uniqueID: json['uniqueID'] as int,
    );
  }

  /// Returns the correct answer index as 0-based for use with List indexing.
  int get correctAnswerZeroBased => correctIndex - 1;
}
