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

class WizardState {
  final String creationType;
  final Map<int, String> answers; // Map of question index to answer label

  WizardState({
    required this.creationType,
    required this.answers,
  });

  WizardState copyWith({
    String? creationType,
    Map<int, String>? answers,
  }) {
    return WizardState(
      creationType: creationType ?? this.creationType,
      answers: answers ?? Map.from(this.answers),
    );
  }
}
