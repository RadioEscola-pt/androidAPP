import 'package:flutter/material.dart';

import 'notes_view.dart';

/// Styled container for question notes/explanations with accent left border.
class NotesContainer extends StatelessWidget {
  const NotesContainer({
    super.key,
    required this.notes,
    required this.accentColor,
  });

  final String notes;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final trimmed = notes.trim();
    if (trimmed.isEmpty || trimmed == 'Notas') return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Card.filled(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  'Explicação',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            NotesView(notes: notes),
          ],
        ),
      ),
    );
  }
}
