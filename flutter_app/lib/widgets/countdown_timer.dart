import 'dart:async';

import 'package:flutter/material.dart';

/// Displays a countdown timer in MM:SS format.
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
    final isLow = _remaining.inMinutes < 5;
    final isCritical = _remaining.inMinutes < 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLow)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.timer_outlined,
              size: 18,
              color: isCritical ? const Color(0xFFC62828) : const Color(0xFFE65100),
            ),
          ),
        Text(
          _formatDuration(_remaining),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isCritical
                ? const Color(0xFFC62828)
                : isLow
                    ? const Color(0xFFE65100)
                    : null,
          ),
        ),
      ],
    );
  }
}
