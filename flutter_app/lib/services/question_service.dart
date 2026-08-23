import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/exam_config.dart';
import '../models/question.dart';

/// Reads the bundles compiled by the website's content pipeline.
///
/// Both files under `assets/content/` are build output of
/// `bun run content:build --mobile=<this app>` in the hamradiostudy repo. They
/// are not hand-edited: `content:check` fails there if they no longer match the
/// source, which is what keeps the app's question bank from drifting away from
/// the site's again.
class QuestionService {
  Future<List<Question>> loadQuestions(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final questionsJson = data['questions'] as List;
    return questionsJson
        .map((q) => Question.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  Future<ExamConfig> loadExamConfig() async {
    final jsonString =
        await rootBundle.loadString('assets/content/exam_config.json');
    return ExamConfig.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }
}
