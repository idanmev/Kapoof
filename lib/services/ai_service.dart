import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kapoof/models/parsed_kid_input.dart';
import 'package:kapoof/models/wizard_model.dart';
import 'package:kapoof/services/app_settings.dart';

class AIService {
  // Retrieve API key dynamically
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  String get _ageRange => AppSettings.instance.ageMode.ageRange;
  bool get _isBigKid => AppSettings.instance.ageMode == AgeMode.big;

  // Content-generation model: raw HTML/JS/CSS output
  GenerativeModel get _contentModel => GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: _apiKey,
        systemInstruction: Content.system('''
You are a magical creative engine for children aged $_ageRange.
You output ONLY raw self-contained HTML+CSS+JS.
No markdown. No backticks. No explanations. No comments outside of code.
The output must run perfectly in a mobile WebView with no internet connection.
No external libraries. No CDN links. Pure vanilla HTML+CSS+JS only.

${_isBigKid ? '''
For ages 8-10: more sophisticated mechanics, multi-step interactions,
score-keeping, light gameplay logic, vocabulary is OK to be slightly more advanced.
Avoid baby-talk; treat the user as a smart kid.
''' : '''
For ages 5-7: very simple cause-and-effect, big buttons, simple words,
celebrate every interaction with sparkles/sound/animation.
'''}

Visual rules:
- Bright saturated colors, nothing grey or dull
- Big bold text minimum ${_isBigKid ? '20px' : '24px'}, fun rounded fonts via @import Google Fonts
- Generous use of emoji as visual elements
- Smooth CSS animations on everything — nothing should be static
- Full viewport: width 100vw, height 100vh, overflow hidden
- Mobile touch events: use both onclick AND ontouchstart
- Always show the creation title at the top in large playful text
'''),
      );

  // Image-generation model (Nano Banana)
  GenerativeModel get _imageModel => GenerativeModel(
        model: 'gemini-2.5-flash-image',
        apiKey: _apiKey,
      );

  // Learning model — low temperature for factual answers
  GenerativeModel get _learningModel => GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(temperature: 0.2, topP: 0.8),
        systemInstruction: Content.system('''
You teach children aged $_ageRange about anything they want to learn.

CRITICAL RULES:
- ONLY share facts you are confident about. If unsure, output the literal text:
  "Hmm, let's ask a grown-up about that one!" inside the lesson.
- Never invent statistics, dates, or names.
- Avoid scary, violent, or adult topics. If asked about war, death, or anything
  upsetting, gently redirect: "That's a big topic — let's learn it with a grown-up."
- Use words a ${_isBigKid ? '9-year-old' : '6-year-old'} would know. ${_isBigKid ? 'Sentences can be longer; introduce one new vocabulary word per section and explain it.' : 'Short sentences.'}
- Be wildly enthusiastic and curious — kids learn through wonder.

Output ONLY raw self-contained HTML+CSS+JS. No markdown, no backticks.
The page must contain:
1. A big colorful title at the top with the topic name
2. THREE sections, each with: a giant emoji illustration, 2-3 sentence explanation, fun rounded fonts
3. A "Did you know?" surprising fact box
4. A simple kid quiz at the bottom with 3 multiple-choice buttons (one correct,
   confetti animation when they tap the right one)
5. Bright saturated colors, smooth CSS animations, mobile-friendly viewport
'''),
      );

  // Voice-parser model: returns strict JSON, no markdown
  GenerativeModel get _parserModel => GenerativeModel(
        model: 'gemini-3.1-flash-lite-preview',
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

  AIService();

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
    
    try {
      final response = await _parserModel.generateContent([Content.text(prompt)]);
      final raw = (response.text ?? '').trim();
      debugPrint('KAPOOF RESPONSE: $raw');

      // Strip markdown code fences if Gemini wraps its output anyway
      final cleaned =
          raw.replaceAll(RegExp(r'^```json?\s*', multiLine: true), '').replaceAll(RegExp(r'```\s*$', multiLine: true), '').trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return ParsedKidInput.fromJson(json);
    } catch (e) {
      debugPrint('KAPOOF PARSER ERROR: $e');
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

  // ─── Surprise Me ───────────────────────────────────────────────────────────

  /// Generates a single short, kid-friendly remix instruction.
  /// Returns something like "Add a flying unicorn that giggles" — never empty.
  Future<String> generateSurpriseRemix(String creationType, String currentHtml) async {
    final prompt = '''
A child made a $creationType. Suggest ONE silly, magical change for them.
Reply with ONLY the instruction, max 8 words, starting with an emoji.
Examples: "🌈 Make everything rainbow striped", "🦖 Add a tiny dancing dinosaur".
No quotes, no explanation, just the instruction.
''';
    try {
      final response = await _parserModel.generateContent([Content.text(prompt)]);
      final text = (response.text ?? '').trim().replaceAll('"', '');
      if (text.isEmpty) return '🎉 Make it extra magical';
      return text.split('\n').first.trim();
    } catch (e) {
      debugPrint('SURPRISE ERROR: $e');
      return '🎉 Make it extra magical';
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
    debugPrint('KAPOOF FINAL PROMPT: $finalPrompt');
    
    try {
      if (_apiKey.isEmpty) throw Exception('API Key is missing from .env!');
      
      final response = await _contentModel.generateContent([Content.text(finalPrompt)]);
      
      if (response.text == null) {
        final reason = response.candidates.first.finishReason;
        debugPrint('KAPOOF BLOCKED: $reason');
        throw Exception('The magic was blocked ($reason). Try different words!');
      }

      final raw = response.text ?? '';
      // Strip markdown code fences if the model wraps its output
      final responseText = raw
          .replaceAll(RegExp(r'^```html?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*$', multiLine: true), '')
          .trim();
          
      debugPrint('KAPOOF RESPONSE length: ${responseText.length}');
      return responseText;
    } catch (e) {
      debugPrint('KAPOOF ERROR: $e');
      rethrow;
    }
  }

  // ─── Image Generation ──────────────────────────────────────────────────────

  /// Generates a static colorful illustration. Returns PNG bytes.
  Future<Uint8List> generateImage(WizardState state, {ParsedKidInput? parsedInput}) async {
    final hero = parsedInput?.hero ?? state.answers[0] ?? '';
    final world = parsedInput?.world ?? state.answers[1] ?? '';
    final mood = parsedInput?.mood ?? state.answers[2] ?? 'happy';
    final extras = (parsedInput != null && parsedInput.extras.isNotEmpty)
        ? parsedInput.extras.join(', ')
        : (state.answers[3] ?? '');

    final prompt = '''
A bright, joyful, kid-friendly cartoon illustration of $hero in $world.
Mood: $mood. Extra elements: $extras.
Style: Pixar-meets-storybook, saturated rainbow colors, big friendly shapes,
no text, no watermarks. Centered composition. Square format.
''';
    return _runImageGen(prompt);
  }

  /// Generates a printable line-art coloring page (black outlines, white background).
  Future<Uint8List> generateColoringPage(WizardState state, {ParsedKidInput? parsedInput}) async {
    final hero = parsedInput?.hero ?? state.answers[0] ?? '';
    final world = parsedInput?.world ?? state.answers[1] ?? '';
    final extras = (parsedInput != null && parsedInput.extras.isNotEmpty)
        ? parsedInput.extras.join(', ')
        : (state.answers[3] ?? '');

    final prompt = '''
A coloring book page for a child aged 5-8.
Subject: $hero in $world. Extra: $extras.
STRICT STYLE: Pure black outlines on PURE WHITE background only.
No shading, no fill, no gray, no color whatsoever — only line art.
Bold thick lines (2-4 pixels), rounded simple shapes, easy for a child to color in.
Big distinct regions to color. No text. No background pattern. Centered composition.
''';
    return _runImageGen(prompt);
  }

  Future<Uint8List> _runImageGen(String prompt) async {
    if (_apiKey.isEmpty) throw Exception('API Key is missing from .env!');
    final response = await _imageModel.generateContent([Content.text(prompt)]);
    for (final candidate in response.candidates) {
      for (final part in candidate.content.parts) {
        if (part is DataPart) return part.bytes;
      }
    }
    throw Exception('Image model returned no image data');
  }

  // ─── Webpage / Story Page (clean HTML, printable) ──────────────────────────

  /// Generates a clean, blog-style HTML page (vs the animated app-style story).
  Future<String> generateWebpage(WizardState state, {ParsedKidInput? parsedInput}) async {
    final hero = parsedInput?.hero ?? state.answers[0] ?? '';
    final world = parsedInput?.world ?? state.answers[1] ?? '';
    final mood = parsedInput?.mood ?? state.answers[2] ?? '';
    final extras = (parsedInput != null && parsedInput.extras.isNotEmpty)
        ? parsedInput.extras.join(', ')
        : (state.answers[3] ?? '');

    final prompt = '''
Write and display a STATIC website page version of a story for a child aged 5-8.
Topic: $hero in $world. Mood: $mood. Extras: $extras.

Requirements:
- Looks like a real readable website / blog post (not an app)
- Centered max-width 720px column, generous padding, white background
- Title at top in big bold playful font (Fredoka One via Google Fonts)
- Body in Nunito, 20px+, line-height 1.7
- 4 short paragraphs telling the story, each preceded by a single large emoji
- One pull-quote box in the middle (colorful background, big italic text)
- Print-friendly: @media print rule that hides nothing and keeps colors
- A footer line at the bottom: "Made with Kapoof ✨"
- NO animations, NO interactivity, NO scripts — just clean static HTML+CSS
- Mobile-friendly viewport meta tag
- Output ONLY the raw HTML, no markdown, no backticks
''';
    if (_apiKey.isEmpty) throw Exception('API Key is missing from .env!');
    final response = await _contentModel.generateContent([Content.text(prompt)]);
    final raw = response.text ?? '';
    return raw
        .replaceAll(RegExp(r'^```html?\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*$', multiLine: true), '')
        .trim();
  }

  // ─── Learning Mode ─────────────────────────────────────────────────────────

  /// Generates an HTML mini-lesson on the given topic. Low temperature, safety guardrails.
  Future<String> generateLesson(String topic) async {
    if (_apiKey.isEmpty) throw Exception('API Key is missing from .env!');
    final prompt = 'A child wants to learn about: "$topic". Build the lesson page now.';
    final response = await _learningModel.generateContent([Content.text(prompt)]);
    final raw = response.text ?? '';
    return raw
        .replaceAll(RegExp(r'^```html?\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*$', multiLine: true), '')
        .trim();
  }

  // ─── Website Mode (personal site) ──────────────────────────────────────────

  /// Generates a personal homepage HTML for a kid.
  /// [photoBase64] is optional (data:image/jpeg;base64,...).
  Future<String> generatePersonalSite({
    required String name,
    required int? age,
    required List<String> hobbies,
    required String vibe,
    String? photoBase64,
  }) async {
    if (_apiKey.isEmpty) throw Exception('API Key is missing from .env!');
    final hobbiesText = hobbies.isEmpty ? 'fun stuff' : hobbies.join(', ');
    final ageText = age != null ? '$age years old' : '';
    final photoNote = photoBase64 != null
        ? 'IMPORTANT: there is a photo of the child. Embed it in the page using exactly this img tag (already includes data URI):\n<img src="$photoBase64" alt="$name" id="kid-photo" />\nStyle the photo as a circular avatar with a thick colorful border, max 200px.'
        : 'No photo provided. Use a big colorful emoji avatar instead.';

    final prompt = '''
Build a personal website homepage for a child named $name $ageText.
Their hobbies: $hobbiesText.
Vibe / theme: $vibe.

$photoNote

Requirements:
- This must FEEL like a real website the kid built themselves.
- Big bold "Welcome to $name's Website!" header, animated entrance
- "About me" section with their age and a fun made-up superpower based on hobbies
- "My Hobbies" section as a colorful card grid, one card per hobby with a fitting emoji
- "Fun Fact" section with an animated rotating fun fact
- Footer says: "Built by $name with Kapoof ✨"
- Theme colors must match the chosen vibe ($vibe)
- Smooth CSS animations, hover effects, mobile-friendly viewport
- Output ONLY raw HTML+CSS+JS, no markdown, no backticks
''';
    final response = await _contentModel.generateContent([Content.text(prompt)]);
    final raw = response.text ?? '';
    return raw
        .replaceAll(RegExp(r'^```html?\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*$', multiLine: true), '')
        .trim();
  }
}
