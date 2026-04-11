import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'exam_screen.dart';

/// Displays exam results and provides a review mode to navigate through
/// all questions with color-coded feedback.
class ExamResultView extends StatefulWidget {
  final List<Question> questions;
  final List<int> answers;

  const ExamResultView({
    super.key,
    required this.questions,
    required this.answers,
  });

  @override
  State<ExamResultView> createState() => _ExamResultViewState();
}

class _ExamResultViewState extends State<ExamResultView> {
  bool _reviewMode = false;
  int _reviewIndex = 0;

  late final ExamScore score;

  @override
  void initState() {
    super.initState();
    score = ExamScore.calculate(widget.questions, widget.answers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_reviewMode ? 'Revisao' : 'Resultado do Exame'),
      ),
      body: _reviewMode ? _buildReviewView() : _buildResultSummary(),
    );
  }

  Widget _buildResultSummary() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resultado do Exame',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _resultRow('Respostas certas', '${score.correct}'),
          _resultRow('Respostas erradas', '${score.wrong}'),
          _resultRow('Sem Resposta', '${score.unanswered}'),
          const Divider(height: 32),
          _resultRow('Total', '${score.total.toStringAsFixed(2)} pontos',
              bold: true),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: () => setState(() => _reviewMode = true),
              child: const Text('Rever Respostas'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: 18,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _buildReviewView() {
    final question = widget.questions[_reviewIndex];
    final selectedAnswer = widget.answers[_reviewIndex];
    final correctIdx = question.correctAnswerZeroBased;

    return Column(
      children: [
        // Question counter
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Pergunta ${_reviewIndex + 1} de ${widget.questions.length}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        // Scrollable content
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
                // Answer options with color coding
                ...List.generate(question.answers.length, (i) {
                  Color? tileColor;
                  if (i == correctIdx) {
                    // Correct answer highlighted in green
                    tileColor = Colors.green.shade100;
                  } else if (i == selectedAnswer && selectedAnswer != correctIdx) {
                    // Wrong selected answer highlighted in red
                    tileColor = Colors.red.shade100;
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2.0),
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(
                        i == selectedAnswer
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: i == correctIdx
                            ? Colors.green
                            : (i == selectedAnswer ? Colors.red : null),
                      ),
                      title: Text(question.answers[i]),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                // Notes / explanation
                if (question.notes.isNotEmpty) ...[
                  const Text(
                    'Notas:',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Html(data: question.notes),
                ],
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
              if (_reviewIndex > 0)
                ElevatedButton(
                  onPressed: () =>
                      setState(() => _reviewIndex--),
                  child: const Text('Voltar'),
                )
              else
                const SizedBox.shrink(),
              if (_reviewIndex < widget.questions.length - 1)
                ElevatedButton(
                  onPressed: () =>
                      setState(() => _reviewIndex++),
                  child: const Text('Proximo'),
                )
              else
                ElevatedButton(
                  onPressed: () =>
                      setState(() => _reviewMode = false),
                  child: const Text('Ver Resultado'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
