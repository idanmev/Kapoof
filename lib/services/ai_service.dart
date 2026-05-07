import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kapoof/models/parsed_kid_input.dart';
import 'package:kapoof/models/wizard_model.dart';

class AIService {
  // Retrieve API key from .env file
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // Content-generation model: raw HTML/JS/CSS output
  final GenerativeModel _contentModel;

  // Voice-parser model: returns strict JSON, no markdown
  final GenerativeModel _parserModel;

  AIService()
      : _contentModel = GenerativeModel(
          model: 'gemini-2.5-flash-preview-05-20',
          apiKey: _apiKey,
          systemInstruction: Content.system('''
You are a magical creative engine for children aged 5-8.
You output ONLY raw self-contained HTML+CSS+JS. 
No markdown. No backticks. No explanations. No comments outside of code.
The output must run perfectly in a mobile WebView with no internet connection.
No external libraries. No CDN links. Pure vanilla HTML+CSS+JS only.

Visual rules:
- Bright saturated colors, nothing grey or dull
- Big bold text minimum 24px, fun rounded fonts via @import Google Fonts
- Generous use of emoji as visual elements
- Smooth CSS animations on everything — nothing should be static
- Full viewport: width 100vw, height 100vh, overflow hidden
- Mobile touch events: use both onclick AND ontouchstart
- Always show the creation title at the top in large playful text
'''),
        ),
        _parserModel = GenerativeModel(
          model: 'gemini-2.0-flash-001',
          apiKey: _apiKey,
          systemInstruction: Content.system('''
You are a magical interpreter for young children aged 5-8.

A child just spoke out loud about something they want to create.
Their description may be rambling, contradictory, full of sound effects,
random objects, made-up words, or things that make no logical sense to adults.

YOUR RULES:
- NEVER judge, simplify, or discard anything they said
- NEVER replace their ideas with more "sensible" ones
- Treat every detail as intentional — a white cheese going to a pool
  is a valid hero. A dinosaur fighting a unicorn screaming "yaa yaa"
  is a valid story conflict.
- If they contradict themselves, include BOTH things — let the creation
  hold the contradiction, that's what makes it magical
- Fill only the gaps they left completely empty, using the same wild
  energy they brought
- Keep their exact words and sounds where possible ("yaa yaa" stays
  as "yaa yaa")
- If they mentioned a sound effect, it becomes part of the experience
- Your interpretation should make the child say "YES that's exactly it!"
  not "I guess that's close enough"

Return ONLY valid JSON, no markdown, no explanation:
{
  "hero": "exact character(s) they described",
  "world": "the setting they described",
  "conflict": "what's happening / the action",
  "extras": ["every extra detail they mentioned"],
  "sounds": ["any sound effects or words they performed"],
  "mood": "the energy of what they described (wild/funny/scary/magical/etc)",
  "summary_for_kid": "One sentence in excited kid language reflecting EXACTLY what they said back to them, using their own words. Start with OK SO..."
}
'''),
        );

  // ─── Voice Parser ──────────────────────────────────────────────────────────

  /// Parses a raw voice transcript into a structured [ParsedKidInput].
  /// If the transcript is under 8 words, returns a minimal object using
  /// the text as-is without calling Gemini.
  Future<ParsedKidInput> parseKidVoiceInput(
    String rawTranscript,
    String creationType,
  ) async {
    final wordCount = rawTranscript.trim().split(RegExp(r'\s+')).length;

    if (wordCount < 8) {
      // Short utterance — use as-is, no AI round-trip needed
      return ParsedKidInput(
        hero: rawTranscript,
        world: '',
        conflict: '',
        extras: [],
        sounds: [],
        mood: 'magical',
        summaryForKid: 'OK SO... ${rawTranscript.trim()} — let\'s make it! ✨',
      );
    }

    final prompt =
        'The child wants to create a $creationType. They said:\n"$rawTranscript"\n\nReturn the JSON interpretation now.';
    debugPrint('KAPOOF PROMPT: $prompt');
    final response = await _parserModel.generateContent([Content.text(prompt)]);
    final raw = (response.text ?? '').trim();
    debugPrint('KAPOOF RESPONSE: $raw');

    // Strip markdown code fences if Gemini wraps its output anyway
    final cleaned =
        raw.replaceAll(RegExp(r'^```json?\s*', multiLine: true), '').replaceAll(RegExp(r'```\s*$', multiLine: true), '').trim();

    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return ParsedKidInput.fromJson(json);
    } catch (e) {
      // Fallback: treat entire transcript as a minimal input
      return ParsedKidInput(
        hero: rawTranscript,
        world: '',
        conflict: '',
        extras: [],
        sounds: [],
        mood: 'magical',
        summaryForKid: 'OK SO... ${rawTranscript.trim()} — let\'s make it! ✨',
      );
    }
  }

  // ─── Content Generator ─────────────────────────────────────────────────────

  String _buildBasePrompt(WizardState state, {ParsedKidInput? parsedInput}) {
    final buffer = StringBuffer();
    
    // Extract ingredients based on parsed input or manual answers
    String hero = parsedInput?.hero ?? state.answers[0] ?? 'Unknown hero';
    String world = parsedInput?.world ?? state.answers[1] ?? 'Unknown world';
    String moodOrGoal = parsedInput?.mood ?? state.answers[2] ?? 'Fun';
    String extrasOrEnemy = (parsedInput != null && parsedInput.extras.isNotEmpty) 
        ? parsedInput.extras.join(', ') 
        : state.answers[3] ?? 'None';
    String powerOrEnding = state.answers[4] ?? 'Magic';

    if (state.creationType == 'drawing') {
      buffer.writeln('''
Create a beautiful interactive animated drawing for a child aged 5-8.

The drawing features:
- Main subject: $hero
- Setting: $world  
- Mood: $moodOrGoal
- Extra elements: $extrasOrEnemy

Requirements:
- Use an HTML5 canvas that fills the screen
- Animate everything — the main subject should move, bounce, or float
- Add particle effects (stars, bubbles, sparkles) matching the mood
- Make it interactive — tapping/clicking anywhere adds a magical effect
- Include at least 3 animated elements on screen at all times
- The mood "$moodOrGoal" should define the color palette and animation speed
- Draw the main subject using canvas shapes and emoji overlaid on canvas
- Title at top: big, colorful, fun font
''');
    } else if (state.creationType == 'dartgame') {
      buffer.writeln('''
Create a fun playable mobile game for a child aged 5-8.

The game features:
- Hero character: $hero
- World/setting: $world
- Goal: $moodOrGoal
- Enemy/obstacle: $extrasOrEnemy
- Special power: $powerOrEnding

Requirements:
- Playable by touch (tap, swipe) AND keyboard arrows
- Display score prominently at top — big colorful number
- Hero is represented by a large emoji that moves smoothly
- Enemies/obstacles appear from edges and move toward hero
- Collecting items or avoiding obstacles increases score
- Special power activates on double-tap or spacebar
- Game over screen with big emoji, score, and "Play Again!" button
- Victory condition at score 10 with celebration animation (confetti)
- Frame rate smooth using requestAnimationFrame
''');
    } else if (state.creationType == 'story') {
      buffer.writeln('''
Write and display a beautiful illustrated story for a child aged 5-8.

The story features:
- Main character: $hero
- Setting: $world
- Problem to solve: $moodOrGoal
- Ending: $extrasOrEnemy

Requirements:
- 4 paragraphs, each on its own colorful section/page
- Each section has a large emoji illustration (4rem+) centered above the text
- Font: Fredoka One for titles, Nunito for body text (import from Google Fonts)
- Text size minimum 22px, line height 1.8, maximum 60 characters per line
- Alternating background colors per section (use the Kapoof palette: pink, yellow, mint, blue)
- Smooth scroll or tap-to-advance between sections
- Final section: big celebration with animated confetti and "THE END 🌟" 
- Story content must directly use the character names and setting provided
- Happy ending always
''');
    }

    return buffer.toString().trim();
  }

  Future<String> generateContent(
    WizardState state, {
    List<String> followUps = const [],
    ParsedKidInput? parsedInput,
  }) async {
    final prompt = _buildBasePrompt(state, parsedInput: parsedInput);
    final buffer = StringBuffer(prompt);

    if (followUps.isNotEmpty) {
      buffer.writeln(
          '\nAdditionally, please apply these magical follow-up instructions:');
      for (final followUp in followUps) {
        buffer.writeln('- $followUp');
      }
    }

    final finalPrompt = buffer.toString();
    debugPrint('KAPOOF PROMPT: $finalPrompt');
    
    final response =
        await _contentModel.generateContent([Content.text(finalPrompt)]);
    final responseText = response.text ?? '';
    debugPrint('KAPOOF RESPONSE: $responseText');
    return responseText;
  }

  // ─── Thumbnail ─────────────────────────────────────────────────────────────

  // Thumbnail generation intentionally disabled — Imagen requires Vertex AI.
  // The ResultScreen handles null gracefully with a colour placeholder.
  Future<Uint8List?> generateThumbnail(String description) async => null;
}
