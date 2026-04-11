import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exam_result_view.dart';

enum Category { cat1, cat2, cat3 }

const categoryFiles = {
  Category.cat1: 'question1.json',
  Category.cat2: 'question2.json',
  Category.cat3: 'question3.json',
};

class Question {
  final String question;
  final List<String> answers;
  final int correctIndex; // 1-based from JSON
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

  int get correctAnswerZeroBased => correctIndex - 1;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] as String,
      answers: List<String>.from(json['answers'] as List),
      correctIndex: json['correctIndex'] as int,
      notes: json['notes'] as String? ?? '',
      img: json['img'] as String?,
      uniqueID: json['uniqueID'] as int? ?? 0,
    );
  }
}

class ExamState {
  final List<Question> questions;
  final List<int> answers; // -1 = unanswered, 0-3 = selected answer index
  final int currentIndex;
  final bool isFinalized;
  final Duration remainingTime;

  const ExamState({
    required this.questions,
    required this.answers,
    this.currentIndex = 0,
    this.isFinalized = false,
    this.remainingTime = const Duration(minutes: 60),
  });

  ExamState copyWith({
    List<Question>? questions,
    List<int>? answers,
    int? currentIndex,
    bool? isFinalized,
    Duration? remainingTime,
  }) {
    return ExamState(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      isFinalized: isFinalized ?? this.isFinalized,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }
}

class ExamNotifier extends StateNotifier<ExamState> {
  ExamNotifier()
      : super(const ExamState(
          questions: [],
          answers: [],
        ));

  Future<void> initialize(Category category) async {
    final fileName = categoryFiles[category]!;
    final jsonString = await rootBundle.loadString('assets/$fileName');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final allQuestions = (data['questions'] as List)
        .map((q) => Question.fromJson(q as Map<String, dynamic>))
        .toList();

    // Shuffle and take 40 (or fewer if not enough questions)
    allQuestions.shuffle(Random());
    final selected = allQuestions.sublist(0, min(40, allQuestions.length));

    state = ExamState(
      questions: selected,
      answers: List.filled(selected.length, -1),
    );
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

  void updateTimer(Duration remaining) {
    state = state.copyWith(remainingTime: remaining);
  }

  void finalize() {
    state = state.copyWith(isFinalized: true);
  }
}

final examProvider = StateNotifierProvider<ExamNotifier, ExamState>((ref) {
  return ExamNotifier();
});

class ExamScore {
  final int correct;
  final int wrong;
  final int unanswered;
  final double total;

  const ExamScore({
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.total,
  });

  factory ExamScore.calculate(List<Question> questions, List<int> answers) {
    int correct = 0;
    int wrong = 0;
    int unanswered = 0;
    double total = 0.0;

    for (int i = 0; i < questions.length; i++) {
      final selected = answers[i];
      final correctIdx = questions[i].correctAnswerZeroBased;

      if (selected == -1) {
        unanswered++;
      } else if (selected == correctIdx) {
        correct++;
        total += 1.0;
      } else {
        wrong++;
        total -= 0.25;
      }
    }

    return ExamScore(
      correct: correct,
      wrong: wrong,
      unanswered: unanswered,
      total: total,
    );
  }
}

class ExamScreen extends ConsumerStatefulWidget {
  final Category category;

  const ExamScreen({super.key, required this.category});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  Timer? _timer;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Schedule initialization after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final notifier = ref.read(examProvider.notifier);
    await notifier.initialize(widget.category);
    _startTimer();
    setState(() => _initialized = true);
  }

  void _startTimer() {
    const tickDuration = Duration(seconds: 1);
    _timer = Timer.periodic(tickDuration, (_) {
      final notifier = ref.read(examProvider.notifier);
      final current = ref.read(examProvider).remainingTime;
      final next = current - tickDuration;

      if (next.inSeconds <= 0) {
        notifier.updateTimer(Duration.zero);
        notifier.finalize();
        _timer?.cancel();
      } else {
        notifier.updateTimer(next);
      }
    });
  }

  void _finalizeExam() {
    _timer?.cancel();
    ref.read(examProvider.notifier).finalize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final state = ref.watch(examProvider);

    if (state.isFinalized) {
      return ExamResultView(
        questions: state.questions,
        answers: state.answers,
      );
    }

    return _buildExamView(state);
  }

  Widget _buildExamView(ExamState state) {
    final question = state.questions[state.currentIndex];
    final selectedAnswer = state.answers[state.currentIndex];
    final isLastQuestion =
        state.currentIndex == state.questions.length - 1;

    final minutes = state.remainingTime.inMinutes;
    final seconds = state.remainingTime.inSeconds % 60;
    final timerText =
        'tempo: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exame'),
      ),
      body: Column(
        children: [
          // Timer
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              timerText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Question counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Pergunta ${state.currentIndex + 1} de ${state.questions.length}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          // Scrollable question area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Text(
                    question.question,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  // Optional image
                  if (question.img != null && question.img!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Image.asset(
                        'assets/${question.img}',
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  // Answer options
                  RadioGroup<int>(
                    groupValue:
                        selectedAnswer == -1 ? null : selectedAnswer,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(examProvider.notifier).selectAnswer(value);
                      }
                    },
                    child: Column(
                      children: List.generate(question.answers.length, (i) {
                        return RadioListTile<int>(
                          title: Text(question.answers[i]),
                          value: i,
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (state.currentIndex > 0)
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(examProvider.notifier).previousQuestion(),
                    child: const Text('Voltar'),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton(
                  onPressed: () {
                    if (isLastQuestion) {
                      _showFinalizeDialog();
                    } else {
                      ref.read(examProvider.notifier).nextQuestion();
                    }
                  },
                  child:
                      Text(isLastQuestion ? 'Finalizar' : 'Proximo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalizeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Exame'),
        content:
            const Text('Tem a certeza que deseja finalizar o exame?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _finalizeExam();
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }
}
