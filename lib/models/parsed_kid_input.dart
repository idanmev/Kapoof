
class ParsedKidInput {
  final String hero;
  final String world;
  final String conflict;
  final List<String> extras;
  final List<String> sounds;
  final String mood;
  final String summaryForKid;

  ParsedKidInput({
    required this.hero,
    required this.world,
    required this.conflict,
    required this.extras,
    required this.sounds,
    required this.mood,
    required this.summaryForKid,
  });

  factory ParsedKidInput.fromJson(Map<String, dynamic> json) {
    return ParsedKidInput(
      hero: json['hero'] as String? ?? '',
      world: json['world'] as String? ?? '',
      conflict: json['conflict'] as String? ?? '',
      extras: List<String>.from(json['extras'] as List? ?? []),
      sounds: List<String>.from(json['sounds'] as List? ?? []),
      mood: json['mood'] as String? ?? 'magical',
      summaryForKid: json['summary_for_kid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'hero': hero,
    'world': world,
    'conflict': conflict,
    'extras': extras,
    'sounds': sounds,
    'mood': mood,
    'summary_for_kid': summaryForKid,
  };

  /// Returns an emoji that matches the mood
  String get moodEmoji {
    switch (mood.toLowerCase()) {
      case 'wild': return '🌪️';
      case 'funny': return '🤣';
      case 'scary': return '👻';
      case 'magical': return '✨';
      case 'calm': return '😌';
      case 'epic': return '🦸';
      case 'chaotic': return '💥';
      default: return '🌟';
    }
  }

  /// A WizardState-compatible answers map derived from parsed input
  Map<int, String> toWizardAnswers() {
    final answers = <int, String>{};
    if (hero.isNotEmpty) answers[0] = hero;
    if (world.isNotEmpty) answers[1] = world;
    if (conflict.isNotEmpty) answers[2] = conflict;
    if (extras.isNotEmpty) answers[3] = extras.join(', ');
    if (sounds.isNotEmpty) answers[4] = sounds.join(', ');
    return answers;
  }

  /// Build a rich prompt string for the AI content generator
  String toPromptString() {
    final buffer = StringBuffer();
    buffer.writeln('Hero: $hero');
    buffer.writeln('World: $world');
    buffer.writeln('What happens: $conflict');
    if (extras.isNotEmpty) buffer.writeln('Extra details: ${extras.join(', ')}');
    if (sounds.isNotEmpty) buffer.writeln('Sound effects to include: ${sounds.join(', ')}');
    buffer.writeln('Overall mood/energy: $mood');
    return buffer.toString();
  }
}
