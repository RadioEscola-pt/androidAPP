import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/question.dart';

class QuestionService {
  /// Loads questions from a JSON asset file at the given [assetPath].
  ///
  /// The JSON is expected to have a top-level "questions" array.
  Future<List<Question>> loadQuestions(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final questionsJson = data['questions'] as List;
    return questionsJson
        .map((q) => Question.fromJson(q as Map<String, dynamic>))
        .toList();
  }
}
