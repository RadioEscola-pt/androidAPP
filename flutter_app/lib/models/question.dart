/// A place a question appears in an official ANACOM exam paper.
///
/// `question` is the pergunta number printed in the paper and `page` is the PDF
/// page it sits on — unrelated numbers, since a paper carries about four
/// questions per page. Never show one as the other.
///
/// [url] is absent when the paper is one nobody has a scan of; the citation is
/// still worth showing, so the caller renders it as text rather than a tap that
/// goes nowhere.
class SourceRef {
  final String pdf;
  final int question;
  final int? page;
  final String? url;

  const SourceRef({
    required this.pdf,
    required this.question,
    this.page,
    this.url,
  });

  bool get isAvailable => url != null;

  factory SourceRef.fromJson(Map<String, dynamic> json) {
    return SourceRef(
      pdf: json['pdf'] as String? ?? '',
      question: json['question'] as int? ?? 0,
      page: json['page'] as int?,
      url: json['url'] as String?,
    );
  }
}

/// One exam question, as compiled by the website's content pipeline.
///
/// The shape mirrors `lib/content/schema.ts` in the hamradiostudy repo, which
/// is the single definition of what a question is. Two things that used to be
/// this file's problem are now resolved before the JSON is written:
/// [correctIndex] is 0-based, so it indexes [options] directly, and
/// [explanationHtml] arrives as HTML with every path already pointing at a
/// bundled asset or an absolute URL.
///
/// Nothing here normalises or repairs content. If a question looks wrong, fix
/// it in `content/questions/` and rebuild — a runtime coercion would hide the
/// problem from the build check that exists to catch it.
class Question {
  final int id;
  final String question;
  final List<String> options;

  /// 0-based index into [options].
  final int correctIndex;

  /// Explanation as HTML, or empty when the question has none.
  final String explanationHtml;

  /// Bundled figure, e.g. `assets/images/cat1/fig1.png`.
  final String? img;

  final String? topic;
  final List<SourceRef> sources;

  const Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanationHtml = '',
    this.img,
    this.topic,
    this.sources = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      options:
          (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
      // -1 rather than 0: a missing answer key must not silently make the first
      // option correct. Callers compare against the selected index, so an
      // out-of-range value marks every answer wrong instead of one right.
      correctIndex: json['correctIndex'] as int? ?? -1,
      explanationHtml: json['explanationHtml'] as String? ?? '',
      img: json['img'] as String?,
      topic: json['topic'] as String?,
      sources: (json['sources'] as List?)
              ?.map((s) => SourceRef.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  bool get hasExplanation => explanationHtml.isNotEmpty;
}
