import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question.dart';
import '../services/question_service.dart';

enum Category { cat1, cat2, cat3 }

const categoryFiles = {
  Category.cat1: 'question1.json',
  Category.cat2: 'question2.json',
  Category.cat3: 'question3.json',
};

final questionServiceProvider = Provider<QuestionService>((ref) {
  return QuestionService();
});

/// Loads all questions for a [Category], cached by Riverpod.
final questionsProvider =
    FutureProvider.family<List<Question>, Category>((ref, category) async {
  final service = ref.watch(questionServiceProvider);
  final fileName = categoryFiles[category]!;
  return service.loadQuestions('assets/$fileName');
});

/// Tracks the current question index in study mode, per category.
final studyIndexProvider =
    StateProvider.family<int, Category>((ref, category) => 0);

/// The number of questions in an exam.
const examQuestionCount = 40;

class ExamState {
  final List<Question> questions;
  final List<int> answers; // -1 = unanswered, 0-3 = selected answer index
  final int currentIndex;
  final bool isFinalized;

  const ExamState({
    required this.questions,
    required this.answers,
    required this.currentIndex,
    required this.isFinalized,
  });

  ExamState copyWith({
    List<Question>? questions,
    List<int>? answers,
    int? currentIndex,
    bool? isFinalized,
  }) {
    return ExamState(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      isFinalized: isFinalized ?? this.isFinalized,
    );
  }

  /// Scoring constants matching the original Android app.
  static const double correctScore = 1.0;
  static const double wrongScore = -0.25;

  /// Calculate the total exam score.
  double get totalScore {
    double score = 0.0;
    for (int i = 0; i < questions.length; i++) {
      final selected = answers[i];
      if (selected == -1) {
        // unanswered: no score change
      } else if (selected == questions[i].correctAnswerZeroBased) {
        score += correctScore;
      } else {
        score += wrongScore;
      }
    }
    return score;
  }

  int get correctCount => _countMatching((s, q) => s == q.correctAnswerZeroBased);
  int get wrongCount => _countMatching((s, q) => s != -1 && s != q.correctAnswerZeroBased);
  int get unansweredCount => answers.where((a) => a == -1).length;

  int _countMatching(bool Function(int selected, Question q) test) {
    int count = 0;
    for (int i = 0; i < questions.length; i++) {
      if (test(answers[i], questions[i])) count++;
    }
    return count;
  }

  /// Creates an exam state from a pool of questions by shuffling and selecting
  /// up to [examQuestionCount] questions.
  static ExamState createExam(List<Question> allQuestions, [Random? random]) {
    final shuffled = List<Question>.from(allQuestions)..shuffle(random);
    final selected =
        shuffled.sublist(0, min(examQuestionCount, shuffled.length));
    return ExamState(
      questions: selected,
      answers: List<int>.filled(selected.length, -1),
      currentIndex: 0,
      isFinalized: false,
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

  /// Initialize the exam with questions loaded from the given category.
  /// Shuffles and picks [examQuestionCount] random questions.
  void startExam(List<Question> allQuestions, [Random? random]) {
    state = ExamState.createExam(allQuestions, random);
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

  void finalize() {
    state = state.copyWith(isFinalized: true);
  }
}

final examNotifierProvider =
    NotifierProvider.family<ExamNotifier, ExamState, Category>(
        ExamNotifier.new);
