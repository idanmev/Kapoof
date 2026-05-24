class WizardOption {
  final String label;
  final String emoji;

  WizardOption({required this.label, required this.emoji});
}

class WizardQuestion {
  final String question;
  final List<WizardOption> options;

  WizardQuestion({required this.question, required this.options});
}

/// Output format for a creation. Not all types support all formats.
/// - interactive: animated HTML+JS (default for everything)
/// - webpage: clean static HTML (story → blog-style page)
/// - picture: PNG image (drawing only)
/// - coloring: PNG line-art for printing (drawing only)
enum OutputFormat { interactive, webpage, picture, coloring }

class WizardState {
  final String creationType;
  final Map<int, String> answers; // Map of question index to answer label
  final OutputFormat format;

  WizardState({
    required this.creationType,
    required this.answers,
    this.format = OutputFormat.interactive,
  });

  WizardState copyWith({
    String? creationType,
    Map<int, String>? answers,
    OutputFormat? format,
  }) {
    return WizardState(
      creationType: creationType ?? this.creationType,
      answers: answers ?? Map.from(this.answers),
      format: format ?? this.format,
    );
  }
}
