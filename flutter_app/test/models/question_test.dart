import 'package:flutter_test/flutter_test.dart';
import 'package:radio_escola/models/question.dart';

void main() {
  group('Question.fromJson', () {
    test('parses a question from the generated bundle', () {
      final json = {
        'id': 42,
        'question': 'What is 2+2?',
        'options': ['3', '4', '5', '6'],
        'correctIndex': 1,
        'explanationHtml': 'Basic <b>math</b>',
        'topic': 'aritmetica',
      };

      final q = Question.fromJson(json);

      expect(q.id, 42);
      expect(q.question, 'What is 2+2?');
      expect(q.options, ['3', '4', '5', '6']);
      expect(q.explanationHtml, 'Basic <b>math</b>');
      expect(q.topic, 'aritmetica');
      expect(q.img, isNull);
      expect(q.sources, isEmpty);
    });

    test('correctIndex indexes options directly', () {
      // The pipeline emits 0-based, so there is no decrement to forget. The
      // legacy bundle was 1-based and every read site had to remember.
      final q = Question.fromJson({
        'id': 1,
        'question': 'Q',
        'options': ['A', 'B', 'C', 'D'],
        'correctIndex': 1,
      });

      expect(q.options[q.correctIndex], 'B');
    });

    test('img keeps the asset path the pipeline resolved', () {
      final q = Question.fromJson({
        'id': 7,
        'question': 'Look at the image',
        'options': ['A', 'B'],
        'correctIndex': 0,
        'img': 'assets/images/cat1/circuit.png',
      });

      // Callers pass this to Image.asset unchanged; re-prepending "assets/"
      // was what the legacy relative form required.
      expect(q.img, 'assets/images/cat1/circuit.png');
    });

    test('a missing answer key marks nothing correct rather than option 0', () {
      final q = Question.fromJson({
        'id': 1,
        'question': 'Q',
        'options': ['A', 'B'],
      });

      expect(q.correctIndex, -1);
      expect(q.correctIndex, isNot(0));
    });

    test('reports whether it has an explanation', () {
      Question withHtml(String html) => Question.fromJson({
            'id': 1,
            'question': 'Q',
            'options': ['A', 'B'],
            'correctIndex': 0,
            'explanationHtml': html,
          });

      expect(withHtml('some prose').hasExplanation, isTrue);
      expect(withHtml('').hasExplanation, isFalse);
    });
  });

  group('SourceRef', () {
    test('parses a paper that has a scan', () {
      final q = Question.fromJson({
        'id': 1,
        'question': 'Q',
        'options': ['A', 'B'],
        'correctIndex': 0,
        'sources': [
          {
            'pdf': 'cat1/2024_01_02',
            'question': 8,
            'page': 2,
            'url': 'https://radioescola.pt/exams/cat1/2024_01_02.pdf',
          }
        ],
      });

      final s = q.sources.single;
      expect(s.pdf, 'cat1/2024_01_02');
      // Pergunta 8 sits on page 2 — the two numbers are unrelated.
      expect(s.question, 8);
      expect(s.page, 2);
      expect(s.isAvailable, isTrue);
    });

    test('a paper nobody has is citable but not linkable', () {
      final q = Question.fromJson({
        'id': 1,
        'question': 'Q',
        'options': ['A', 'B'],
        'correctIndex': 0,
        'sources': [
          {'pdf': 'cat1/1998_01_01', 'question': 3, 'unavailable': true}
        ],
      });

      final s = q.sources.single;
      expect(s.isAvailable, isFalse);
      expect(s.url, isNull);
      expect(s.page, isNull);
    });
  });
}
