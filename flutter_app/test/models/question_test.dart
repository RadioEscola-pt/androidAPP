import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/question.dart';

void main() {
  group('Question.fromJson', () {
    test('parses a valid JSON map', () {
      final json = {
        'question': 'What is 2+2?',
        'answers': ['3', '4', '5', '6'],
        'correctIndex': 2,
        'notes': 'Basic math',
        'img': null,
        'uniqueID': 42,
        'fonte': ['cat1/exam1'],
        'tutorial': null,
        'materia': null,
      };

      final q = Question.fromJson(json);

      expect(q.question, 'What is 2+2?');
      expect(q.answers, ['3', '4', '5', '6']);
      expect(q.correctIndex, 2);
      expect(q.notes, 'Basic math');
      expect(q.img, isNull);
      expect(q.uniqueID, 42);
    });

    test('parses img when present', () {
      final json = {
        'question': 'Look at the image',
        'answers': ['A', 'B', 'C', 'D'],
        'correctIndex': 1,
        'notes': 'See image',
        'img': 'circuit.png',
        'uniqueID': 7,
      };

      final q = Question.fromJson(json);
      expect(q.img, 'circuit.png');
    });

    test('correctAnswerZeroBased converts 1-based to 0-based', () {
      final q = Question(
        question: 'Q',
        answers: ['A', 'B', 'C', 'D'],
        correctIndex: 3,
        notes: '',
        uniqueID: 1,
      );

      expect(q.correctAnswerZeroBased, 2);
    });

    test('correctAnswerZeroBased for correctIndex 1', () {
      final q = Question(
        question: 'Q',
        answers: ['A', 'B', 'C', 'D'],
        correctIndex: 1,
        notes: '',
        uniqueID: 1,
      );

      expect(q.correctAnswerZeroBased, 0);
    });
  });
}
