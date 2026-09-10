import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders a question's explanation.
///
/// The HTML arrives already resolved by the content pipeline: `**bold**` is
/// gone, figures point into the bundle, and everything else is an absolute URL.
/// So there is nothing to rewrite here — only two things to do with a path,
/// depending on which side of "does the app ship this?" it falls on.
class NotesView extends StatelessWidget {
  final String notes;

  const NotesView({super.key, required this.notes});

  Future<void> _openLink(String url, BuildContext context) async {
    final uri = Uri.tryParse(url);
    // Exam papers are ~169 MB in total and are not bundled, so these leave the
    // app for a browser. Before the links were made absolute they resolved to
    // nothing and 472 questions' worth of citations simply did nothing on tap.
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a ligação')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    return Html(
      data: notes,
      onLinkTap: (url, _, _) {
        if (url != null) _openLink(url, context);
      },
      extensions: [
        ImageExtension(
          builder: (extensionContext) {
            final src = extensionContext.attributes['src'] ?? '';
            // Two notes cite a path that is dead on the website too; they fall
            // through to the error builder rather than being special-cased.
            if (!src.startsWith('assets/')) return const SizedBox.shrink();
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Image.asset(
                src,
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
