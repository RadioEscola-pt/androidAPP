import 'package:flutter/material.dart';

/// Consistent bottom navigation bar with shadow and safe area padding.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );
  }
}
