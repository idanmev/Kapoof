import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/services/ai_service.dart';
import 'package:kapoof/utils/html_renderer.dart' as html_renderer;
import 'package:kapoof/widgets/kid_error_widget.dart';
import 'package:kapoof/widgets/neobrutalist_widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:webview_flutter/webview_flutter.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with SingleTickerProviderStateMixin {
  final AIService _aiService = AIService();
  final TextEditingController _topicController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _isLoading = false;
  String _generatedHtml = '';
  WebViewController? _previewController;

  late AnimationController _spinController;

  static const List<String> _exampleTopics = [
    '🌋 Volcanoes',
    '🐙 Octopuses',
    '🌈 Rainbows',
    '🚀 Space',
    '🦕 Dinosaurs',
    '🐝 Bees',
    '🌙 The moon',
    '🦋 Butterflies',
    '🐳 Whales',
    '⚡ Lightning',
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      final available = await _speech.initialize(
        onStatus: (val) => debugPrint('STT status: $val'),
        onError: (val) => debugPrint('STT error: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _topicController.text = val.recognizedWords;
            if (val.finalResult) {
              _isListening = false;
              if (val.recognizedWords.isNotEmpty) _generate();
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _generate() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;
    setState(() {
      _isLoading = true;
      _spinController.repeat();
    });
    try {
      final html = await _aiService.generateLesson(topic);
      if (!mounted) return;
      if (html.isEmpty) throw Exception('Empty lesson');
      setState(() {
        _generatedHtml = html;
        if (!kIsWeb) {
          _previewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadHtmlString(html);
        }
        _isLoading = false;
        _spinController.stop();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _spinController.stop();
      });
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: KidErrorWidget(
            emoji: '🙈',
            message: "Hmm, learning didn't work. Try again!",
            onRetry: () => Navigator.pop(context),
          ),
        ),
      );
    }
  }

  Widget _buildPreview() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _spinController,
              child: const Text('🧠', style: TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 16),
            Text(
              'Learning about it...',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackground,
              ),
            ),
          ],
        ),
      );
    }
    if (_generatedHtml.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎓', style: TextStyle(fontSize: 96)),
              const SizedBox(height: 16),
              Text(
                'What do you want to learn?',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type or speak ANYTHING — animals, planets,\nhow stuff works, why the sky is blue!',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (kIsWeb) {
      return html_renderer.buildHtmlView(
        _generatedHtml,
        'kapoof-lesson-${_generatedHtml.hashCode}',
      );
    }
    if (_previewController == null) {
      return Container(color: AppColors.surfaceVariant);
    }
    return WebViewWidget(controller: _previewController!);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Text('🎓', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Text(
              'Learning Mode',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.onBackground,
              ),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: NeobrutalistButton(
            size: 44,
            backgroundColor: AppColors.surface,
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: AppColors.onBackground),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(3),
          child: SizedBox(
            height: 3,
            child: ColoredBox(color: AppColors.onBackground),
          ),
        ),
      ),
      body: Column(
        children: [
          // Topic input
          Padding(
            padding: EdgeInsets.all(isTablet ? 16.0 : 14.0),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 6.0 : 8.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(isTablet ? 28.0 : 36.0),
                border: Border.all(
                    color: AppColors.onBackground, width: isTablet ? 3.0 : 4.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onBackground,
                    offset: Offset(isTablet ? 3.0 : 4.0, isTablet ? 3.0 : 4.0),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  NeobrutalistButton(
                    size: isTablet ? 48.0 : 58.0,
                    backgroundColor: _isListening
                        ? AppColors.errorContainer
                        : AppColors.primaryContainer,
                    onTap: _listen,
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: _isListening
                          ? AppColors.error
                          : AppColors.onPrimaryContainer,
                      size: isTablet ? 22.0 : 28.0,
                    ),
                  ),
                  SizedBox(width: isTablet ? 10.0 : 14.0),
                  Expanded(
                    child: TextField(
                      controller: _topicController,
                      decoration: InputDecoration(
                        hintText: 'What do you want to learn?',
                        hintStyle: GoogleFonts.lexend(
                          fontSize: isTablet ? 13.0 : 16.0,
                          color:
                              AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.lexend(
                        fontSize: isTablet ? 13.0 : 16.0,
                        color: AppColors.onBackground,
                      ),
                      onSubmitted: (_) => _generate(),
                    ),
                  ),
                  NeobrutalistButton(
                    size: isTablet ? 48.0 : 58.0,
                    backgroundColor: AppColors.tertiaryContainer,
                    onTap: _isLoading ? () {} : _generate,
                    child: Icon(
                      Icons.school,
                      color: AppColors.onTertiaryContainer,
                      size: isTablet ? 22.0 : 28.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick example chips
          if (_generatedHtml.isEmpty && !_isLoading)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: _exampleTopics.map((t) {
                  final clean = t.replaceAll(RegExp(r'^[^\s]+\s'), '');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        _topicController.text = clean;
                        _generate();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: AppColors.onBackground, width: 2.5),
                        ),
                        child: Text(
                          t,
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Lesson preview
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 16.0 : 14.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.onBackground, width: isTablet ? 3 : 4),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.onBackground,
                      offset: Offset(5, 5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildPreview(),
                ),
              ),
            ),
          ),
          SizedBox(height: isTablet ? 16.0 : 14.0),
        ],
      ),
    );
  }
}
