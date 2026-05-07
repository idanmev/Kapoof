import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/models/parsed_kid_input.dart';
import 'package:kapoof/models/wizard_model.dart';
import 'package:kapoof/screens/kid_confirmation_screen.dart';
import 'package:kapoof/screens/result_screen.dart';
import 'package:kapoof/services/ai_service.dart';
import 'package:kapoof/widgets/kid_error_widget.dart';
import 'package:kapoof/widgets/neobrutalist_widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class WizardScreen extends StatefulWidget {
  final String creationType;

  const WizardScreen({
    super.key,
    required this.creationType,
  });

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  late List<WizardQuestion> _questions;
  int _currentIndex = 0;
  final Map<int, String> _answers = {};

  final stt.SpeechToText _speech = stt.SpeechToText();
  final AIService _aiService = AIService();
  bool _isListening = false;
  bool _isParsing = false;
  String _voiceText = '';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    final sets = {
      'dartgame': [
        WizardQuestion(question: 'Who is your hero?', options: [
          WizardOption(label: 'Robot', emoji: '🤖'),
          WizardOption(label: 'Cat', emoji: '🐱'),
          WizardOption(label: 'Dino', emoji: '🦕'),
          WizardOption(label: 'Star', emoji: '⭐'),
        ]),
        WizardQuestion(question: 'Where does it happen?', options: [
          WizardOption(label: 'Outer Space', emoji: '🚀'),
          WizardOption(label: 'Underwater', emoji: '🌊'),
          WizardOption(label: 'Candy Land', emoji: '🍭'),
          WizardOption(label: 'Jungle', emoji: '🌴'),
        ]),
        WizardQuestion(question: 'What is the goal?', options: [
          WizardOption(label: 'Collect stars', emoji: '⭐'),
          WizardOption(label: 'Reach the finish', emoji: '🏁'),
          WizardOption(label: 'Defeat enemies', emoji: '👾'),
          WizardOption(label: 'Find treasure', emoji: '💎'),
        ]),
        WizardQuestion(question: 'Any bad guys?', options: [
          WizardOption(label: 'Ghosts', emoji: '👻'),
          WizardOption(label: 'Spiders', emoji: '🕷️'),
          WizardOption(label: 'Storms', emoji: '🌩️'),
          WizardOption(label: 'No bad guys', emoji: '❌'),
        ]),
        WizardQuestion(question: 'Special power?', options: [
          WizardOption(label: 'Super jump', emoji: '🦘'),
          WizardOption(label: 'Shoot fire', emoji: '🔥'),
          WizardOption(label: 'Super speed', emoji: '💨'),
          WizardOption(label: 'Magic wand', emoji: '🪄'),
        ]),
      ],
      'story': [
        WizardQuestion(question: 'Who is the main character?', options: [
          WizardOption(label: 'Fairy', emoji: '🧚'),
          WizardOption(label: 'Bear', emoji: '🐻'),
          WizardOption(label: 'Little girl', emoji: '👧'),
          WizardOption(label: 'Fox', emoji: '🦊'),
        ]),
        WizardQuestion(question: 'What makes them special?', options: [
          WizardOption(label: 'Very brave', emoji: '💪'),
          WizardOption(label: 'Super smart', emoji: '🤓'),
          WizardOption(label: 'Very funny', emoji: '🤣'),
          WizardOption(label: 'Has magic', emoji: '🪄'),
        ]),
        WizardQuestion(question: 'Where does it happen?', options: [
          WizardOption(label: 'Magic castle', emoji: '🏰'),
          WizardOption(label: 'Enchanted forest', emoji: '🌲'),
          WizardOption(label: 'Outer space', emoji: '🚀'),
          WizardOption(label: 'Under the sea', emoji: '🌊'),
        ]),
        WizardQuestion(question: "What's the big problem?", options: [
          WizardOption(label: 'Always dark', emoji: '🌑'),
          WizardOption(label: 'Scary dragon', emoji: '🐲'),
          WizardOption(label: 'Something stolen', emoji: '💎'),
          WizardOption(label: 'Friend is sick', emoji: '🤒'),
        ]),
        WizardQuestion(question: 'How does it end?', options: [
          WizardOption(label: 'Big celebration', emoji: '🎉'),
          WizardOption(label: 'Everyone friends', emoji: '🤝'),
          WizardOption(label: 'Win a prize', emoji: '🏆'),
          WizardOption(label: 'Magic fixes it', emoji: '🪄'),
        ]),
      ],
      'drawing': [
        WizardQuestion(question: "What's the main subject?", options: [
          WizardOption(label: 'Butterfly', emoji: '🦋'),
          WizardOption(label: 'Whale', emoji: '🐳'),
          WizardOption(label: 'Flower', emoji: '🌸'),
          WizardOption(label: 'Lion', emoji: '🦁'),
        ]),
        WizardQuestion(question: 'Where does it live?', options: [
          WizardOption(label: 'In the clouds', emoji: '☁️'),
          WizardOption(label: 'Under the sea', emoji: '🌊'),
          WizardOption(label: 'Magic garden', emoji: '🌺'),
          WizardOption(label: 'On the moon', emoji: '🌙'),
        ]),
        WizardQuestion(question: "What's the mood?", options: [
          WizardOption(label: 'Happy & fun', emoji: '🎉'),
          WizardOption(label: 'Calm & dreamy', emoji: '🌙'),
          WizardOption(label: 'Magical', emoji: '🔮'),
          WizardOption(label: 'Colorful chaos', emoji: '🌈'),
        ]),
        WizardQuestion(question: 'Add something extra!', options: [
          WizardOption(label: 'Lots of stars', emoji: '⭐'),
          WizardOption(label: 'Rainbows', emoji: '🌈'),
          WizardOption(label: 'Snowflakes', emoji: '❄️'),
          WizardOption(label: 'Magic sparkles', emoji: '✨'),
        ]),
      ],
    };

    _questions = sets[widget.creationType] ?? sets['dartgame']!;
  }

  void _nextQuestion(String answer) {
    setState(() => _answers[_currentIndex] = answer);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() => _currentIndex++);
      } else {
        _finishWizard();
      }
    });
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    } else {
      Navigator.pop(context);
    }
  }

  void _finishWizard({ParsedKidInput? parsedInput}) {
    final state = WizardState(
      creationType: widget.creationType,
      answers: parsedInput != null ? parsedInput.toWizardAnswers() : _answers,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          wizardState: state,
          parsedInput: parsedInput,
        ),
      ),
    );
  }

  Future<void> _listen() async {
    if (_isParsing) return;
    if (!_isListening) {
      final available = await _speech.initialize(
        onStatus: (val) => debugPrint('STT status: $val'),
        onError: (val) => debugPrint('STT error: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _voiceText = val.recognizedWords;
            if (val.finalResult && _voiceText.isNotEmpty) {
              _isListening = false;
              _onVoiceFinished(_voiceText);
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _onVoiceFinished(String transcript) async {
    setState(() => _isParsing = true);
    ParsedKidInput parsed;
    try {
      parsed = await _aiService.parseKidVoiceInput(transcript, widget.creationType);
    } catch (e) {
      debugPrint('Parse error: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: KidErrorWidget.voiceFailed(
              onRetry: () => Navigator.pop(context),
            ),
          ),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isParsing = false);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KidConfirmationScreen(
          parsedInput: parsed,
          creationType: widget.creationType,
          onConfirm: () {
            Navigator.of(context).pop();
            _finishWizard(parsedInput: parsed);
          },
          onRetry: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back + progress
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20.0 : 24.0,
                vertical: isTablet ? 14.0 : 18.0,
              ),
              child: Row(
                children: [
                  NeobrutalistButton(
                    size: isTablet ? 44.0 : 52.0,
                    onTap: _previousQuestion,
                    backgroundColor: AppColors.surface,
                    child: Icon(Icons.arrow_back,
                        color: AppColors.onBackground,
                        size: isTablet ? 20.0 : 26.0),
                  ),
                  SizedBox(width: isTablet ? 16.0 : 20.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step ${_currentIndex + 1} of ${_questions.length}',
                          style: GoogleFonts.lexend(
                            fontSize: isTablet ? 13.0 : 16.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                          ),
                        ),
                        SizedBox(height: isTablet ? 5.0 : 7.0),
                        Container(
                          height: isTablet ? 13.0 : 17.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.onBackground,
                                width: isTablet ? 2.0 : 3.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryContainer),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 28.0 : 28.0,
                  vertical: isTablet ? 12.0 : 16.0,
                ),
                child: Column(
                  children: [
                    Text(
                      currentQuestion.question,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isTablet ? 26.0 : 36.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onBackground,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: isTablet ? 20.0 : 28.0),

                    // Voice button
                    NeobrutalistButton(
                      isCircle: false,
                      size: isTablet ? 68.0 : 88.0,
                      backgroundColor: _isParsing
                          ? AppColors.tertiaryContainer
                          : _isListening
                              ? AppColors.errorContainer
                              : AppColors.primaryContainer,
                      onTap: _isParsing ? null : _listen,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20.0 : 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isTablet ? 6.0 : 8.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.onBackground,
                                    width: isTablet ? 1.5 : 2.0),
                              ),
                              child: _isParsing
                                  ? SizedBox(
                                      width: isTablet ? 22.0 : 28.0,
                                      height: isTablet ? 22.0 : 28.0,
                                      child: const CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.secondary),
                                    )
                                  : Icon(
                                      _isListening ? Icons.stop : Icons.mic,
                                      color: _isListening
                                          ? AppColors.error
                                          : AppColors.secondary,
                                      size: isTablet ? 22.0 : 28.0,
                                    ),
                            ),
                            SizedBox(width: isTablet ? 12.0 : 14.0),
                            Text(
                              _isParsing
                                  ? 'Understanding you... 🧠'
                                  : _isListening
                                      ? "I'm listening..."
                                      : 'Tell me! 🎤',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isTablet ? 17.0 : 22.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: isTablet ? 24.0 : 36.0),

                    // Option cards grid — 4 cols on tablet, 2 on phone
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isTablet ? 4 : 2,
                        crossAxisSpacing: isTablet ? 14.0 : 20.0,
                        mainAxisSpacing: isTablet ? 14.0 : 20.0,
                        childAspectRatio: isTablet ? 0.9 : 0.88,
                      ),
                      itemCount: currentQuestion.options.length,
                      itemBuilder: (context, index) {
                        final option = currentQuestion.options[index];
                        final isSelected =
                            _answers[_currentIndex] == option.label;

                        const colors = [
                          Color(0xFFB4E0FF),
                          Color(0xFFFFD8E7),
                          Color(0xFFFFE16D),
                          Color(0xFFC6E7FF),
                        ];
                        final cardColor = colors[index % colors.length];

                        return NeobrutalistCard(
                          backgroundColor: isSelected
                              ? AppColors.primaryContainer
                              : cardColor,
                          padding: EdgeInsets.all(isTablet ? 10.0 : 14.0),
                          borderRadius: isTablet ? 22.0 : 28.0,
                          borderWidth: isTablet ? 3.0 : 4.0,
                          shadowOffset: isSelected
                              ? (isTablet ? 2.0 : 3.0)
                              : (isTablet ? 5.0 : 7.0),
                          onTap: () => _nextQuestion(option.label),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                option.emoji,
                                style: TextStyle(
                                    fontSize: isTablet ? 46.0 : 64.0),
                              ),
                              SizedBox(height: isTablet ? 8.0 : 12.0),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 10.0 : 14.0,
                                  vertical: isTablet ? 5.0 : 7.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: AppColors.onBackground,
                                      width: isTablet ? 2.0 : 3.0),
                                ),
                                child: Text(
                                  option.label,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lexend(
                                    fontSize: isTablet ? 12.0 : 15.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: isTablet ? 24.0 : 32.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
