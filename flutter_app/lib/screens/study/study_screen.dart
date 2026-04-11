import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

enum Category { cat1, cat2, cat3 }

const categoryFiles = {
  Category.cat1: 'question1.json',
  Category.cat2: 'question2.json',
  Category.cat3: 'question3.json',
};

const categoryLabels = {
  Category.cat1: 'Categoria 1',
  Category.cat2: 'Categoria 2',
  Category.cat3: 'Categoria 3',
};

class Question {
  final String question;
  final List<String> answers;
  final int correctIndex; // 1-based
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
      question: json['question'] as String? ?? '',
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      correctIndex: json['correctIndex'] as int? ?? 1,
      notes: json['notes'] as String? ?? '',
      img: json['img'] as String?,
      uniqueID: json['uniqueID'] as int? ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final questionsProvider =
    FutureProvider.family<List<Question>, Category>((ref, category) async {
  final fileName = categoryFiles[category]!;
  final jsonString = await rootBundle.loadString('assets/$fileName');
  final data = json.decode(jsonString) as Map<String, dynamic>;
  final list = data['questions'] as List<dynamic>;
  return list.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
});

final currentQuestionIndexProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// Study Screen
// ---------------------------------------------------------------------------

class StudyScreen extends ConsumerStatefulWidget {
  final Category category;

  const StudyScreen({super.key, required this.category});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  int? _selectedAnswer;

  bool get _answered => _selectedAnswer != null;

  void _resetAnswer() {
    setState(() {
      _selectedAnswer = null;
    });
  }

  void _onAnswerSelected(int index, Question question) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
    });
    final correct = index == question.correctAnswerZeroBased;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? 'CORRECTO' : 'ERRADO'),
        backgroundColor: correct ? Colors.blue : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsProvider(widget.category));
    final questionIndex = ref.watch(currentQuestionIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryLabels[widget.category] ?? 'Estudo'),
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro ao carregar: $err')),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('Sem perguntas disponíveis.'));
          }
          final clampedIndex = questionIndex.clamp(0, questions.length - 1);
          final question = questions[clampedIndex];
          final isFirst = clampedIndex == 0;
          final isLast = clampedIndex == questions.length - 1;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildQuestionContent(
                      question, clampedIndex, questions.length),
                ),
              ),
              _buildNavigationBar(isFirst, isLast),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionContent(
      Question question, int index, int totalQuestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pergunta ${index + 1} de $totalQuestions',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          question.question,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 12),
        if (question.img != null && question.img!.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Image.asset(
              'assets/${question.img}',
              fit: BoxFit.contain,
              errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        if (question.img != null && question.img!.isNotEmpty)
          const SizedBox(height: 12),
        _buildAnswerOptions(question),
        if (_answered) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _buildNotes(question.notes),
        ],
      ],
    );
  }

  Widget _buildAnswerOptions(Question question) {
    return Container(
      decoration: BoxDecoration(
        color: _answerBackgroundColor(question),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioGroup<int>(
        groupValue: _selectedAnswer ?? -1,
        onChanged: (val) {
          if (!_answered && val != null) {
            _onAnswerSelected(val, question);
          }
        },
        child: Column(
          children: List.generate(question.answers.length, (i) {
            return RadioListTile<int>(
              value: i,
              title: Text(question.answers[i]),
            );
          }),
        ),
      ),
    );
  }

  Color _answerBackgroundColor(Question question) {
    if (!_answered || _selectedAnswer == null) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
    final correct = _selectedAnswer == question.correctAnswerZeroBased;
    return correct
        ? Colors.blue.withValues(alpha: 0.15)
        : Colors.red.withValues(alpha: 0.15);
  }

  Widget _buildNotes(String notes) {
    return Html(
      data: notes,
      style: {
        'body': Style(
          fontSize: FontSize(14),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
      },
      extensions: [
        ImageExtension(
          builder: (extensionContext) {
            final src = extensionContext.attributes['src'] ?? '';
            if (src.startsWith('images/')) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Image.asset(
                  'assets/$src',
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildNavigationBar(bool isFirst, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {
                  ref.read(currentQuestionIndexProvider.notifier).state--;
                  _resetAnswer();
                },
                child: const Text('Voltar'),
              ),
            ),
          if (!isFirst && !isLast) const SizedBox(width: 12),
          if (!isLast)
            Expanded(
              child: FilledButton(
                onPressed: () {
                  ref.read(currentQuestionIndexProvider.notifier).state++;
                  _resetAnswer();
                },
                child: const Text('Próximo'),
              ),
            ),
        ],
      ),
    );
  }
}
