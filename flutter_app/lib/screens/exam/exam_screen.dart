import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/question_providers.dart';
import '../../theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/countdown_timer.dart';
import 'exam_result_view.dart';

class ExamScreen extends ConsumerStatefulWidget {
  final Category category;

  const ExamScreen({super.key, required this.category});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  bool _questionsLoaded = false;
  bool _examStarted = false;
  final _timerKey = UniqueKey();

  Color get _accentColor => categoryAccentColor(widget.category.index);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestions());
  }

  Future<void> _loadQuestions() async {
    final questions =
        await ref.read(questionsProvider(widget.category).future);
    final config = await ref.read(examConfigProvider.future);
    ref
        .read(examNotifierProvider(widget.category).notifier)
        .startExam(questions, config);
    setState(() => _questionsLoaded = true);
  }

  void _startExam() => setState(() => _examStarted = true);

  void _finalizeExam() {
    ref.read(examNotifierProvider(widget.category).notifier).finalize();
  }

  @override
  Widget build(BuildContext context) {
    if (!_questionsLoaded) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: _accentColor)),
      );
    }

    final examState = ref.watch(examNotifierProvider(widget.category));

    if (examState.isFinalized) {
      return ExamResultView(
        examState: examState,
        accentColor: _accentColor,
        categoryLabel: widget.category.label,
      );
    }

    if (!_examStarted) return _buildExamIntro(examState);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showLeaveDialog();
      },
      child: _buildExamView(examState),
    );
  }

  Widget _buildExamIntro(ExamState examState) {
    final config = examState.config!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Exame - ${widget.category.label}'),
        foregroundColor: Colors.white,
        backgroundColor: _accentColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color:
                            _accentColor.withAlpha(isDark ? 40 : 20),
                        borderRadius:
                            BorderRadius.circular(radiusM + 2),
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        size: 32,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Pronto para o exame?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ExamRule(
                      icon: Icons.quiz_outlined,
                      text:
                          '${examState.questions.length} perguntas aleatórias',
                      accentColor: _accentColor,
                    ),
                    _ExamRule(
                      icon: Icons.timer_outlined,
                      text: '${config.duration.inMinutes} minutos para completar',
                      accentColor: _accentColor,
                    ),
                    _ExamRule(
                      icon: Icons.check_circle_outline,
                      text: 'Resposta certa: +1 ponto',
                      accentColor: _accentColor,
                    ),
                    _ExamRule(
                      icon: Icons.cancel_outlined,
                      text:
                          'Resposta errada: -${_trimZero(config.wrongAnswerPenalty)} pontos',
                      accentColor: _accentColor,
                    ),
                    _ExamRule(
                      icon: Icons.flag_outlined,
                      text:
                          'Nota mínima de aprovação: ${_trimZero(config.passingScore)} pontos',
                      accentColor: _accentColor,
                    ),
                    _ExamRule(
                      icon: Icons.remove_circle_outline,
                      text: 'Sem resposta: 0 pontos',
                      accentColor: _accentColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Podes navegar entre perguntas livremente. O resultado é mostrado no final.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _startExam,
                child: const Text('Começar Exame'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamView(ExamState examState) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final question = examState.questions[examState.currentIndex];
    final selectedAnswer = examState.answers[examState.currentIndex];
    final isLastQuestion =
        examState.currentIndex == examState.questions.length - 1;
    final progress =
        (examState.currentIndex + 1) / examState.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Exame - ${widget.category.label}'),
        foregroundColor: Colors.white,
        backgroundColor: _accentColor,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: _accentColor.withAlpha(30),
            color: _accentColor,
            minHeight: 3,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: screenPaddingH, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pergunta ${examState.currentIndex + 1} de ${examState.questions.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CountdownTimer(
                    key: _timerKey,
                    duration: examState.config!.duration,
                    onTimeUp: _finalizeExam,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  screenPaddingH, 4, screenPaddingH, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.question,
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (question.img != null && question.img!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(radiusS),
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxHeight: 300),
                          child: Image.asset(
                            question.img!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  RadioGroup<int>(
                    groupValue:
                        selectedAnswer == -1 ? null : selectedAnswer,
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(examNotifierProvider(widget.category)
                                .notifier)
                            .selectAnswer(value);
                      }
                    },
                    child: Column(
                      children: List.generate(
                          question.options.length, (i) {
                        final isSelected = selectedAnswer == i;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _accentColor
                                      .withAlpha(isDark ? 40 : 20)
                                  : colorScheme
                                      .surfaceContainerHighest
                                      .withAlpha(100),
                              borderRadius:
                                  BorderRadius.circular(radiusS),
                              border: Border.all(
                                color: isSelected
                                    ? _accentColor.withAlpha(80)
                                    : colorScheme.outlineVariant
                                        .withAlpha(80),
                              ),
                            ),
                            child: RadioListTile<int>(
                              title: Text(question.options[i]),
                              value: i,
                              activeColor: _accentColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    radiusS),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BottomNavBar(
            child: Row(
              children: [
                if (examState.currentIndex > 0)
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => ref
                          .read(examNotifierProvider(widget.category)
                              .notifier)
                          .previousQuestion(),
                      child: const Text('Voltar'),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isLastQuestion
                          ? warningColor
                          : _accentColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (isLastQuestion) {
                        _showFinalizeDialog();
                      } else {
                        ref
                            .read(examNotifierProvider(widget.category)
                                .notifier)
                            .nextQuestion();
                      }
                    },
                    child: Text(isLastQuestion
                        ? 'Terminar Exame'
                        : 'Próximo'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do exame?'),
        content: const Text(
            'O teu progresso será perdido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuar exame'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: errorColor),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _showFinalizeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminar Exame?'),
        content: const Text(
            'Depois de terminar não poderá alterar as respostas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: warningColor),
            onPressed: () {
              Navigator.of(ctx).pop();
              _finalizeExam();
            },
            child: const Text('Terminar'),
          ),
        ],
      ),
    );
  }
}

/// Formats a rule value for display: 20.0 reads as "20", 0.25 stays "0.25".
///
/// The values come from the generated config as doubles, and a pass line
/// printed as "20.0 pontos" looks like a rounding artefact rather than a rule.
String _trimZero(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
}

class _ExamRule extends StatelessWidget {
  const _ExamRule({
    required this.icon,
    required this.text,
    required this.accentColor,
  });

  final IconData icon;
  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
