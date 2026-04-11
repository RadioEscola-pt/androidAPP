import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/question.dart';
import 'package:flutter_app/providers/question_providers.dart';

List<Question> _makeQuestions(int count) {
  return List.generate(
    count,
    (i) => Question(
      question: 'Question $i',
      answers: ['A', 'B', 'C', 'D'],
      correctIndex: 1, // correct answer is index 0 (zero-based)
      notes: '',
      uniqueID: i,
    ),
  );
}

void main() {
  group('ExamState scoring', () {
    test('correct answer scores +1.0', () {
      final questions = _makeQuestions(1);
      final examState = ExamState(
        questions: questions,
        answers: [0], // correct (correctIndex=1 -> zeroBased=0)
        currentIndex: 0,
        isFinalized: true,
      );

      expect(examState.totalScore, 1.0);
      expect(examState.correctCount, 1);
      expect(examState.wrongCount, 0);
      expect(examState.unansweredCount, 0);
    });

    test('wrong answer scores -0.25', () {
      final questions = _makeQuestions(1);
      final examState = ExamState(
        questions: questions,
        answers: [2], // wrong
        currentIndex: 0,
        isFinalized: true,
      );

      expect(examState.totalScore, -0.25);
      expect(examState.correctCount, 0);
      expect(examState.wrongCount, 1);
      expect(examState.unansweredCount, 0);
    });

    test('unanswered scores 0', () {
      final questions = _makeQuestions(1);
      final examState = ExamState(
        questions: questions,
        answers: [-1], // unanswered
        currentIndex: 0,
        isFinalized: true,
      );

      expect(examState.totalScore, 0.0);
      expect(examState.correctCount, 0);
      expect(examState.wrongCount, 0);
      expect(examState.unansweredCount, 1);
    });

    test('mixed scoring across multiple questions', () {
      final questions = _makeQuestions(4);
      // All have correctIndex=1 -> zeroBased=0
      final examState = ExamState(
        questions: questions,
        answers: [0, 2, -1, 0], // correct, wrong, unanswered, correct
        currentIndex: 0,
        isFinalized: true,
      );

      // 2 correct (+2.0) + 1 wrong (-0.25) + 1 unanswered (0) = 1.75
      expect(examState.totalScore, 1.75);
      expect(examState.correctCount, 2);
      expect(examState.wrongCount, 1);
      expect(examState.unansweredCount, 1);
    });
  });

  group('ExamState random selection', () {
    test('selects exactly 40 questions when pool is large enough', () {
      final allQuestions = _makeQuestions(100);
      final examState = ExamState.createExam(allQuestions, Random(42));

      expect(examState.questions.length, 40);
      expect(examState.answers.length, 40);
      expect(examState.answers.every((a) => a == -1), isTrue);
    });

    test('selects all questions when pool is smaller than 40', () {
      final allQuestions = _makeQuestions(10);
      final examState = ExamState.createExam(allQuestions, Random(42));

      expect(examState.questions.length, 10);
    });

    test('shuffles questions (different order with different seeds)', () {
      final allQuestions = _makeQuestions(100);

      final state1 = ExamState.createExam(allQuestions, Random(1));
      final state2 = ExamState.createExam(allQuestions, Random(2));

      final ids1 = state1.questions.map((q) => q.uniqueID).toList();
      final ids2 = state2.questions.map((q) => q.uniqueID).toList();
      expect(ids1, isNot(equals(ids2)));
    });
  });

  group('ExamState navigation', () {
    test('copyWith preserves unchanged fields', () {
      final questions = _makeQuestions(2);
      final original = ExamState(
        questions: questions,
        answers: [-1, -1],
        currentIndex: 0,
        isFinalized: false,
      );

      final updated = original.copyWith(currentIndex: 1);
      expect(updated.currentIndex, 1);
      expect(updated.questions, questions);
      expect(updated.isFinalized, false);
    });
  });
}
