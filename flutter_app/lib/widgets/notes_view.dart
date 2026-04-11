import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

/// Renders HTML notes content, handling inline images and links.
///
/// Images with `src` like `images/cat2/foo.png` are mapped to Flutter assets
/// at `assets/images/cat2/foo.png`.
class NotesView extends StatelessWidget {
  final String notes;

  const NotesView({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    return Html(
      data: notes,
      extensions: [
        ImageExtension(
          builder: (extensionContext) {
            final src = extensionContext.attributes['src'] ?? '';
            final assetPath = src.startsWith('assets/') ? src : 'assets/$src';
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            );
          },
        ),
      ],
      style: {
        'body': Style(
          fontSize: FontSize(16),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
      },
    );
  }
}
