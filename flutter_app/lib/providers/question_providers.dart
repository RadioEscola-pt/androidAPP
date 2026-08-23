import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exam_config.dart';
import '../models/question.dart';
import '../services/question_service.dart';

enum Category {
  cat1('Categoria 1', '1'),
  cat2('Categoria 2', '2'),
  cat3('Categoria 3', '3');

  const Category(this.label, this.id);

  final String label;

  /// The category id the content pipeline and the website use ("1", "2", "3").
  /// Progress keys are built from this, so both surfaces index the same map.
  final String id;
}

const categoryFiles = {
  Category.cat1: 'cat1.json',
  Category.cat2: 'cat2.json',
  Category.cat3: 'cat3.json',
};

final questionServiceProvider = Provider<QuestionService>((ref) {
  return QuestionService();
});

/// Loads all questions for a [Category], cached by Riverpod.
final questionsProvider =
    FutureProvider.family<List<Question>, Category>((ref, category) async {
  final service = ref.watch(questionServiceProvider);
  final fileName = categoryFiles[category]!;
  return service.loadQuestions('assets/content/$fileName');
});

/// The ANACOM exam rules, read from the generated bundle rather than declared.
final examConfigProvider = FutureProvider<ExamConfig>((ref) async {
  return ref.watch(questionServiceProvider).loadExamConfig();
});

/// Every category's questions, for surfaces that span the whole bank.
///
/// Bookmarks and the dashboard hold `cat{n}_{id}` keys rather than questions,
/// so they need to look the question up regardless of which category it is in.
/// The three futures are awaited together rather than in sequence.
final allQuestionsProvider =
    FutureProvider<Map<Category, List<Question>>>((ref) async {
  final lists = await Future.wait(
    Category.values.map((c) => ref.watch(questionsProvider(c).future)),
  );
  return Map.fromIterables(Category.values, lists);
});

/// Looks up a question by the category id and question id held in a stat key.
///
/// Returns null when the bank no longer has it — a question retired from the
/// ANACOM set can still be referenced by progress recorded before it went.
({Category category, Question question, int index})? findQuestion(
  Map<Category, List<Question>> bank,
  String categoryId,
  int questionId,
) {
  for (final entry in bank.entries) {
    if (entry.key.id != categoryId) continue;
    final index = entry.value.indexWhere((q) => q.id == questionId);
    if (index == -1) return null;
    return (category: entry.key, question: entry.value[index], index: index);
  }
  return null;
}

/// Tracks the current question index in study mode, per category.
final studyIndexProvider =
    StateProvider.family<int, Category>((ref, category) => 0);

class ExamState {
  final List<Question> questions;
  final List<int> answers; // -1 = unanswered, 0-3 = selected answer index
  final int currentIndex;
  final bool isFinalized;

  /// The rules this exam was started under. Null before [createExam] runs,
  /// when there are no questions to score either.
  final ExamConfig? config;

  const ExamState({
    required this.questions,
    required this.answers,
    required this.currentIndex,
    required this.isFinalized,
    this.config,
  });

  ExamState copyWith({
    List<Question>? questions,
    List<int>? answers,
    int? currentIndex,
    bool? isFinalized,
    ExamConfig? config,
  }) {
    return ExamState(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      isFinalized: isFinalized ?? this.isFinalized,
      config: config ?? this.config,
    );
  }

  static const double correctScore = 1.0;

  /// ANACOM scoring: +1 correct, -[ExamConfig.wrongAnswerPenalty] wrong,
  /// 0 unanswered — which is why leaving a question blank beats guessing.
  double get totalScore {
    final penalty = config?.wrongAnswerPenalty ?? 0;
    double score = 0.0;
    for (int i = 0; i < questions.length; i++) {
      final selected = answers[i];
      if (selected == -1) {
        // unanswered: no score change
      } else if (selected == questions[i].correctIndex) {
        score += correctScore;
      } else {
        score -= penalty;
      }
    }
    return score;
  }

  /// The real pass line is 20 of 40, not "better than nothing".
  ///
  /// This read `totalScore > 0` until the rules were generated rather than
  /// retyped, so a candidate who answered four questions correctly and left the
  /// rest blank was told they had passed.
  bool get passed {
    final line = config?.passingScore;
    return line != null && totalScore >= line;
  }

  int get correctCount => _countMatching((s, q) => s == q.correctIndex);
  int get wrongCount =>
      _countMatching((s, q) => s != -1 && s != q.correctIndex);
  int get unansweredCount => answers.where((a) => a == -1).length;

  int _countMatching(bool Function(int selected, Question q) test) {
    int count = 0;
    for (int i = 0; i < questions.length; i++) {
      if (test(answers[i], questions[i])) count++;
    }
    return count;
  }

  static ExamState createExam(
    List<Question> allQuestions,
    ExamConfig config, [
    Random? random,
  ]) {
    final shuffled = List<Question>.from(allQuestions)..shuffle(random);
    final selected =
        shuffled.sublist(0, min(config.maxQuestions, shuffled.length));
    return ExamState(
      questions: selected,
      answers: List<int>.filled(selected.length, -1),
      currentIndex: 0,
      isFinalized: false,
      config: config,
    );
  }
}

class ExamNotifier extends FamilyNotifier<ExamState, Category> {
  @override
  ExamState build(Category arg) {
    return const ExamState(
      questions: [],
      answers: [],
      currentIndex: 0,
      isFinalized: false,
    );
  }

  void startExam(List<Question> allQuestions, ExamConfig config,
      [Random? random]) {
    state = ExamState.createExam(allQuestions, config, random);
  }

  void selectAnswer(int answerIndex) {
    if (state.isFinalized) return;
    final newAnswers = List<int>.from(state.answers);
    newAnswers[state.currentIndex] = answerIndex;
    state = state.copyWith(answers: newAnswers);
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void finalize() {
    state = state.copyWith(isFinalized: true);
  }
}

final examNotifierProvider =
    NotifierProvider.family<ExamNotifier, ExamState, Category>(
        ExamNotifier.new);
