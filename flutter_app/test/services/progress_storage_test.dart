import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:escola_radio_amador/models/progress.dart';
import 'package:escola_radio_amador/services/progress_storage.dart';

ProgressStorage _storage() =>
    ProgressStorage(prefs: SharedPreferences.getInstance);

Future<Map<String, dynamic>> _raw() async {
  final stored =
      (await SharedPreferences.getInstance()).getString(ProgressStorage.storageKey);
  return json.decode(stored!) as Map<String, dynamic>;
}

ExamAttempt _attempt({
  String id = 'a',
  String category = '1',
  double score = 25,
  bool passed = true,
  int timestamp = 1700000000000,
}) {
  return ExamAttempt(
    id: id,
    category: category,
    score: score,
    totalQuestions: 40,
    correctCount: 26,
    incorrectCount: 4,
    unansweredCount: 10,
    timeSpent: 1800,
    passed: passed,
    timestamp: timestamp,
    questionIds: const [1, 2, 3],
    answers: const {1: 0, 2: 3},
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('storage contract with the website', () {
    test('uses the key the website reads', () {
      expect(ProgressStorage.storageKey, 'hamradio_progress');
    });

    test('question keys match the website getQuestionKey', () {
      expect(questionStatsKey('1', 42), 'cat1_42');
      expect(questionStatsKey('3', 7), 'cat3_7');
    });

    test('reads a document the website wrote', () async {
      SharedPreferences.setMockInitialValues({
        ProgressStorage.storageKey: json.encode({
          'version': 4,
          'lastUpdated': 1700000000000,
          'questionStats': {
            'cat1_42': {
              'attempts': 3,
              'correct': 2,
              'lastAttempt': 1699999999000,
              'lastCorrect': true,
              'spacedRep': {
                'interval': 6,
                'easeFactor': 2.5,
                'nextReviewDate': 1700500000000,
                'repetitionNumber': 2,
              },
              'bookmarked': true,
              'notes': 'rever isto',
              'bookmarkedAt': 1699000000000,
            },
          },
          'examHistory': [
            {
              'id': 'uuid-1',
              'category': '1',
              'score': 22.5,
              'totalQuestions': 40,
              'correctCount': 24,
              'incorrectCount': 6,
              'unansweredCount': 10,
              'timeSpent': 2400,
              'passed': true,
              'timestamp': 1699000000000,
              'questionIds': [1, 2],
              'answers': {'1': 0, '2': 2},
            },
          ],
          'stats': {
            'totalExams': 1,
            'totalPassed': 1,
            'bestScores': {'1': 22.5},
            'currentStreak': 3,
            'longestStreak': 5,
            'lastStudyDate': '2023-11-14',
          },
          'gamification': {'xp': 1200, 'level': 4},
        }),
      });

      final progress = (await _storage().read())!;

      expect(progress.version, 4);
      final stats = progress.questionStats['cat1_42']!;
      expect(stats.attempts, 3);
      expect(stats.bookmarked, isTrue);
      expect(stats.notes, 'rever isto');
      expect(stats.spacedRep!.interval, 6);
      expect(stats.spacedRep!.easeFactor, 2.5);

      final exam = progress.examHistory.single;
      expect(exam.id, 'uuid-1');
      expect(exam.score, 22.5);
      // Record<number, number> serialises with string keys.
      expect(exam.answers, {1: 0, 2: 2});

      expect(progress.stats.longestStreak, 5);
      expect(progress.stats.bestScores['1'], 22.5);
    });

    test('writes gamification back untouched', () async {
      // The app models none of this. Dropping it would mean opening the app
      // quietly destroys state the website owns.
      SharedPreferences.setMockInitialValues({
        ProgressStorage.storageKey: json.encode({
          'version': 4,
          'lastUpdated': 1,
          'questionStats': {},
          'examHistory': [],
          'stats': {
            'totalExams': 0,
            'totalPassed': 0,
            'bestScores': {},
            'currentStreak': 0,
            'longestStreak': 0,
            'lastStudyDate': null,
          },
          'gamification': {
            'xp': 1200,
            'unlockedAchievements': [
              {'achievementId': 'first-exam', 'unlockedAt': 123}
            ],
          },
          'somethingAddedLater': {'nested': true},
        }),
      });

      await _storage().recordQuestionAttempt(
        category: '1',
        questionId: 42,
        correct: true,
      );

      final written = await _raw();
      expect(written['gamification'], {
        'xp': 1200,
        'unlockedAchievements': [
          {'achievementId': 'first-exam', 'unlockedAt': 123}
        ],
      });
      expect(written['somethingAddedLater'], {'nested': true});
    });

    test('omits absent optional fields rather than writing nulls', () async {
      await _storage().recordQuestionAttempt(
        category: '1',
        questionId: 42,
        correct: true,
      );

      final stats = (await _raw())['questionStats']['cat1_42']
          as Map<String, dynamic>;
      expect(stats.containsKey('spacedRep'), isFalse);
      expect(stats.containsKey('bookmarked'), isFalse);
      expect(stats.containsKey('notes'), isFalse);
    });

    test('survives a full round trip unchanged', () async {
      final storage = _storage();
      await storage.recordQuestionAttempt(
          category: '2', questionId: 7, correct: false);
      await storage.toggleBookmark(category: '2', questionId: 7);
      await storage.recordExamAttempt(_attempt());

      final first = await _raw();
      await storage.write(UserProgress.fromJson(first));
      final second = await _raw();

      // lastUpdated is restamped on every write by design.
      first.remove('lastUpdated');
      second.remove('lastUpdated');
      expect(second, equals(first));
    });
  });

  group('recordQuestionAttempt', () {
    test('creates stats for a question seen for the first time', () async {
      await _storage().recordQuestionAttempt(
        category: '1',
        questionId: 42,
        correct: true,
        timestamp: 1700000000000,
      );

      final stats = (await _storage().read())!.questionStats['cat1_42']!;
      expect(stats.attempts, 1);
      expect(stats.correct, 1);
      expect(stats.lastAttempt, 1700000000000);
      expect(stats.lastCorrect, isTrue);
    });

    test('accumulates across attempts', () async {
      final storage = _storage();
      await storage.recordQuestionAttempt(
          category: '1', questionId: 42, correct: true);
      await storage.recordQuestionAttempt(
          category: '1', questionId: 42, correct: false);

      final stats = (await storage.read())!.questionStats['cat1_42']!;
      expect(stats.attempts, 2);
      expect(stats.correct, 1);
      expect(stats.lastCorrect, isFalse);
    });

    test('keeps the bookmark and notes when the question is answered again',
        () async {
      // The website rebuilds this object from a fixed field list and drops
      // bookmarked/notes/bookmarkedAt here, losing them silently.
      SharedPreferences.setMockInitialValues({
        ProgressStorage.storageKey: json.encode({
          'version': 4,
          'lastUpdated': 1,
          'questionStats': {
            'cat1_42': {
              'attempts': 1,
              'correct': 1,
              'lastAttempt': 1,
              'lastCorrect': true,
              'bookmarked': true,
              'notes': 'rever isto',
              'bookmarkedAt': 99,
            },
          },
          'examHistory': [],
          'stats': {
            'totalExams': 0,
            'totalPassed': 0,
            'bestScores': {},
            'currentStreak': 0,
            'longestStreak': 0,
            'lastStudyDate': null,
          },
        }),
      });

      await _storage().recordQuestionAttempt(
          category: '1', questionId: 42, correct: false);

      final stats = (await _storage().read())!.questionStats['cat1_42']!;
      expect(stats.attempts, 2);
      expect(stats.bookmarked, isTrue);
      expect(stats.notes, 'rever isto');
      expect(stats.bookmarkedAt, 99);
    });
  });

  group('recordExamAttempt', () {
    test('prepends to history and updates the counters', () async {
      final storage = _storage();
      await storage.recordExamAttempt(
          _attempt(id: 'older', timestamp: 1000, score: 10, passed: false));
      await storage.recordExamAttempt(
          _attempt(id: 'newer', timestamp: 2000, score: 30));

      final progress = (await storage.read())!;
      expect(progress.examHistory.map((e) => e.id), ['newer', 'older']);
      expect(progress.stats.totalExams, 2);
      expect(progress.stats.totalPassed, 1);
      expect(progress.stats.bestScores['1'], 30);
    });

    test('keeps the best score when a later exam scores lower', () async {
      final storage = _storage();
      await storage.recordExamAttempt(_attempt(id: 'a', score: 30));
      await storage.recordExamAttempt(_attempt(id: 'b', score: 12));

      expect((await storage.read())!.stats.bestScores['1'], 30);
    });

    test('tracks best scores per category', () async {
      final storage = _storage();
      await storage.recordExamAttempt(_attempt(id: 'a', category: '1', score: 30));
      await storage.recordExamAttempt(_attempt(id: 'b', category: '3', score: 21));

      final scores = (await storage.read())!.stats.bestScores;
      expect(scores, {'1': 30, '3': 21});
    });
  });

  group('toggleBookmark', () {
    test('bookmarks a question never answered', () async {
      final progress =
          await _storage().toggleBookmark(category: '1', questionId: 42);

      final stats = progress.questionStats['cat1_42']!;
      expect(stats.bookmarked, isTrue);
      expect(stats.bookmarkedAt, isNotNull);
      expect(stats.attempts, 0);
    });

    test('un-bookmarking clears the timestamp but keeps the stats', () async {
      final storage = _storage();
      await storage.recordQuestionAttempt(
          category: '1', questionId: 42, correct: true);
      await storage.toggleBookmark(category: '1', questionId: 42);
      final progress =
          await storage.toggleBookmark(category: '1', questionId: 42);

      final stats = progress.questionStats['cat1_42']!;
      expect(stats.bookmarked, isFalse);
      expect(stats.bookmarkedAt, isNull);
      expect(stats.attempts, 1);
    });
  });

  group('streak', () {
    Future<void> studyOn(ProgressStorage storage, DateTime day) {
      return storage.recordQuestionAttempt(
        category: '1',
        questionId: 1,
        correct: true,
        timestamp: day.millisecondsSinceEpoch,
      );
    }

    test('starts at one on the first study day', () async {
      final storage = _storage();
      await studyOn(storage, DateTime(2024, 3, 1, 10));

      final stats = (await storage.read())!.stats;
      expect(stats.currentStreak, 1);
      expect(stats.longestStreak, 1);
      expect(stats.lastStudyDate, '2024-03-01');
    });

    test('does not advance twice in one day', () async {
      final storage = _storage();
      await studyOn(storage, DateTime(2024, 3, 1, 10));
      await studyOn(storage, DateTime(2024, 3, 1, 22));

      expect((await storage.read())!.stats.currentStreak, 1);
    });

    test('extends on consecutive days', () async {
      final storage = _storage();
      await studyOn(storage, DateTime(2024, 3, 1, 10));
      await studyOn(storage, DateTime(2024, 3, 2, 10));
      await studyOn(storage, DateTime(2024, 3, 3, 10));

      final stats = (await storage.read())!.stats;
      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
    });

    test('counts a late night and an early morning as two days', () async {
      // Ten minutes apart, but two calendar days — comparing elapsed time
      // instead of dates would call this the same day and stall the streak.
      final storage = _storage();
      await studyOn(storage, DateTime(2024, 3, 1, 23, 50));
      await studyOn(storage, DateTime(2024, 3, 2, 0, 10));

      expect((await storage.read())!.stats.currentStreak, 2);
    });

    test('resets after a missed day but keeps the record', () async {
      final storage = _storage();
      await studyOn(storage, DateTime(2024, 3, 1, 10));
      await studyOn(storage, DateTime(2024, 3, 2, 10));
      await studyOn(storage, DateTime(2024, 3, 5, 10));

      final stats = (await storage.read())!.stats;
      expect(stats.currentStreak, 1);
      expect(stats.longestStreak, 2);
    });
  });

  group('read', () {
    test('returns null when nothing is stored', () async {
      expect(await _storage().read(), isNull);
    });

    test('leaves an unreadable document in place instead of clearing it',
        () async {
      SharedPreferences.setMockInitialValues({
        ProgressStorage.storageKey: 'not json',
      });

      expect(await _storage().read(), isNull);
      expect(
        (await SharedPreferences.getInstance())
            .getString(ProgressStorage.storageKey),
        'not json',
      );
    });
  });
}
