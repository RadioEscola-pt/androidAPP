import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:radio_escola/models/exam_config.dart';
import 'package:radio_escola/models/question.dart';
import 'package:radio_escola/providers/question_providers.dart';

/// The real ANACOM rules, matching what the pipeline generates.
const _config = ExamConfig(
  duration: Duration(seconds: 3600),
  maxQuestions: 40,
  passingScore: 20,
  wrongAnswerPenalty: 0.25,
);

List<Question> _makeQuestions(int count) {
  return List.generate(
    count,
    (i) => Question(
      id: i,
      question: 'Question $i',
      options: const ['A', 'B', 'C', 'D'],
      correctIndex: 0,
    ),
  );
}

ExamState _finished(List<int> answers, {ExamConfig? config = _config}) {
  return ExamState(
    questions: _makeQuestions(answers.length),
    answers: answers,
    currentIndex: 0,
    isFinalized: true,
    config: config,
  );
}

void main() {
  group('ExamState scoring', () {
    test('correct answer scores +1.0', () {
      final examState = _finished([0]);

      expect(examState.totalScore, 1.0);
      expect(examState.correctCount, 1);
      expect(examState.wrongCount, 0);
      expect(examState.unansweredCount, 0);
    });

    test('wrong answer scores -0.25', () {
      final examState = _finished([2]);

      expect(examState.totalScore, -0.25);
      expect(examState.correctCount, 0);
      expect(examState.wrongCount, 1);
      expect(examState.unansweredCount, 0);
    });

    test('unanswered scores 0', () {
      final examState = _finished([-1]);

      expect(examState.totalScore, 0.0);
      expect(examState.correctCount, 0);
      expect(examState.wrongCount, 0);
      expect(examState.unansweredCount, 1);
    });

    test('mixed scoring across multiple questions', () {
      final examState = _finished([0, 2, -1, 0]);

      expect(examState.totalScore, 1.75);
      expect(examState.correctCount, 2);
      expect(examState.wrongCount, 1);
      expect(examState.unansweredCount, 1);
    });

    test('applies the penalty the config carries, not a hardcoded one', () {
      final examState = _finished(
        [2],
        config: const ExamConfig(
          duration: Duration(seconds: 3600),
          maxQuestions: 40,
          passingScore: 20,
          wrongAnswerPenalty: 0.5,
        ),
      );

      expect(examState.totalScore, -0.5);
    });
  });

  group('ExamState pass line', () {
    // The regression this group exists for: `passed` was `totalScore > 0`, so
    // four correct answers out of 40 reported a pass. The real line is 20.
    test('a positive score below the line is not a pass', () {
      final examState = _finished([0, 0, 0, 0, ...List.filled(36, -1)]);

      expect(examState.totalScore, 4.0);
      expect(examState.passed, isFalse);
    });

    test('exactly the passing score passes', () {
      final examState = _finished([...List.filled(20, 0), ...List.filled(20, -1)]);

      expect(examState.totalScore, 20.0);
      expect(examState.passed, isTrue);
    });

    test('the line accounts for the penalty, not just correct answers', () {
      // 21 correct, 4 wrong: 21 - 1.0 = 20.0, still a pass. One more wrong
      // answer drops it below the line.
      final pass = _finished([
        ...List.filled(21, 0),
        ...List.filled(4, 1),
        ...List.filled(15, -1),
      ]);
      expect(pass.totalScore, 20.0);
      expect(pass.passed, isTrue);

      final fail = _finished([
        ...List.filled(21, 0),
        ...List.filled(5, 1),
        ...List.filled(14, -1),
      ]);
      expect(fail.totalScore, 19.75);
      expect(fail.passed, isFalse);
    });

    test('an exam with no rules attached does not claim a pass', () {
      final examState = _finished(List.filled(40, 0), config: null);

      expect(examState.passed, isFalse);
    });
  });

  group('ExamState random selection', () {
    test('selects maxQuestions when the pool is large enough', () {
      final examState =
          ExamState.createExam(_makeQuestions(100), _config, Random(42));

      expect(examState.questions.length, 40);
      expect(examState.answers.length, 40);
      expect(examState.answers.every((a) => a == -1), isTrue);
      expect(examState.config, _config);
    });

    test('selects all questions when the pool is smaller', () {
      final examState =
          ExamState.createExam(_makeQuestions(10), _config, Random(42));

      expect(examState.questions.length, 10);
    });

    test('shuffles questions (different order with different seeds)', () {
      final allQuestions = _makeQuestions(100);

      final state1 = ExamState.createExam(allQuestions, _config, Random(1));
      final state2 = ExamState.createExam(allQuestions, _config, Random(2));

      expect(
        state1.questions.map((q) => q.id).toList(),
        isNot(equals(state2.questions.map((q) => q.id).toList())),
      );
    });
  });

  group('ExamState copyWith', () {
    test('preserves unchanged fields, including the rules', () {
      final original = _finished([-1, -1]).copyWith(isFinalized: false);

      final updated = original.copyWith(currentIndex: 1);
      expect(updated.currentIndex, 1);
      expect(updated.questions, original.questions);
      expect(updated.isFinalized, false);
      expect(updated.config, _config);
    });
  });
}
