import 'dart:async';

import 'package:flutter/material.dart';

/// Displays a countdown timer in MM:SS format.
///
/// Defaults to 60 minutes (matching the Android exam simulation).
/// Calls [onTimeUp] when the timer reaches zero.
class CountdownTimer extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onTimeUp;

  const CountdownTimer({
    super.key,
    this.duration = const Duration(minutes: 60),
    this.onTimeUp,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 1) {
        setState(() => _remaining = Duration.zero);
        _timer?.cancel();
        widget.onTimeUp?.call();
      } else {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Tempo: ${_formatDuration(_remaining)}',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
