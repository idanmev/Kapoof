import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/models/parsed_kid_input.dart';
import 'package:kapoof/models/wizard_model.dart';
import 'package:kapoof/screens/play_screen.dart';
import 'package:kapoof/services/ai_service.dart';
import 'package:kapoof/widgets/kid_error_widget.dart';
import 'package:kapoof/widgets/neobrutalist_widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class ResultScreen extends StatefulWidget {
  final WizardState wizardState;
  final ParsedKidInput? parsedInput;

  const ResultScreen({
    super.key,
    required this.wizardState,
    this.parsedInput,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  final AIService _aiService = AIService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _promptController = TextEditingController();

  bool _isLoading = true;
  bool _isListening = false;
  String _generatedHtml = '';
  Uint8List? _thumbnailBytes;
  final List<String> _followUps = [];

  late AnimationController _spinController;

  final List<String> _loadingMessages = [
    "Mixing your ingredients... 🧪",
    "Adding magic sparkles... ✨",
    "Almost ready... 🎉",
    "Waking up the robots... 🤖",
    "Painting the pixels... 🎨",
    "So much magic it's taking a moment... ⏳"
  ];
  int _loadingMessageIndex = 0;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _startGeneration();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _loadingTimer?.cancel();
    _promptController.dispose();
    super.dispose();
  }

  void _startGeneration() async {
    setState(() {
      _isLoading = true;
      _spinController.repeat();
    });

    _loadingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _loadingMessageIndex =
              (_loadingMessageIndex + 1) % _loadingMessages.length;
        });
      }
    });

    try {
      final description = widget.parsedInput?.summaryForKid ??
          widget.wizardState.answers.values.join(' ');
      final futures = await Future.wait([
        _aiService.generateContent(
          widget.wizardState,
          followUps: _followUps,
          parsedInput: widget.parsedInput,
        ),
        _aiService.generateThumbnail(description),
      ]);

      final html = futures[0] as String;
      if (html.trim().isEmpty) {
        throw Exception('Model returned empty content');
      }
      if (mounted) {
        setState(() {
          _generatedHtml = html;
          _thumbnailBytes ??= futures[1] as Uint8List?;
          _isLoading = false;
          _spinController.stop();
          _loadingTimer?.cancel();
        });
      }
    } catch (e) {
      debugPrint("Error generating content: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _spinController.stop();
          _loadingTimer?.cancel();
          _showError(e);
        });
      }
    }
  }

  void _showError(dynamic e) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: KidErrorWidget(
          emoji: (e is SocketException) ? "🌐" : "🙈",
          message: (e is SocketException)
              ? "We need WiFi magic! Check your connection!"
              : "Oops! The magic hiccuped! Try again!",
          onRetry: () {
            Navigator.pop(context);
            _startGeneration();
          },
        ),
      ),
    );
  }

  void _addFollowUp() {
    final text = _promptController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _followUps.add(text);
        _promptController.clear();
      });
      _startGeneration();
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _promptController.text = val.recognizedWords;
            if (val.finalResult) _isListening = false;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, isTablet),
      body: isTablet ? _buildTabletLayout(context) : _buildMobileLayout(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isTablet) {
    final topPad = Responsive.topInset(context);
    final barHeight = topPad + (isTablet ? 48.0 : 56.0);

    return PreferredSize(
      preferredSize: Size.fromHeight(barHeight),
      child: Container(
        padding: EdgeInsets.only(
          top: topPad,
          left: isTablet ? 24.0 : 20.0,
          right: isTablet ? 24.0 : 20.0,
          bottom: isTablet ? 10.0 : 12.0,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            bottom: BorderSide(color: AppColors.onBackground, width: 3),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.onBackground,
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/logo.png',
              height: isTablet ? 36.0 : 44.0,
            ),
            Row(
              children: [
                NeobrutalistButton(
                  size: isTablet ? 42.0 : 52.0,
                  backgroundColor: AppColors.surface,
                  child: Icon(Icons.star,
                      color: AppColors.primary,
                      size: isTablet ? 20.0 : 26.0),
                  onTap: () {},
                ),
                SizedBox(width: isTablet ? 10.0 : 12.0),
                NeobrutalistButton(
                  size: isTablet ? 42.0 : 52.0,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.auto_awesome,
                      color: AppColors.onPrimaryContainer,
                      size: isTablet ? 20.0 : 26.0),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 240,
            child: _buildSidebar(isTablet: true),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: _buildMainArea(context, isTablet: true),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebar(isTablet: false),
          const SizedBox(height: 28),
          _buildMainArea(context, isTablet: false),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool isTablet}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Ingredients",
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTablet ? 18.0 : 26.0,
            fontWeight: FontWeight.w800,
            color: AppColors.onBackground,
          ),
        ),
        SizedBox(height: isTablet ? 14.0 : 20.0),
        ...widget.wizardState.answers.entries.map((entry) {
          final colors = [
            AppColors.tertiary,
            AppColors.secondary,
            AppColors.primary,
            AppColors.error
          ];
          final icons = [
            Icons.pets,
            Icons.public,
            Icons.emoji_events,
            Icons.flash_on
          ];
          final idx = entry.key % colors.length;

          return Padding(
            padding: EdgeInsets.only(bottom: isTablet ? 10.0 : 14.0),
            child: NeobrutalistCard(
              backgroundColor: AppColors.surface,
              padding: EdgeInsets.all(isTablet ? 12.0 : 16.0),
              borderRadius: isTablet ? 12.0 : 16.0,
              borderWidth: isTablet ? 3.0 : 4.0,
              shadowOffset: isTablet ? 3.0 : 4.0,
              child: Row(
                children: [
                  Container(
                    width: isTablet ? 40.0 : 52.0,
                    height: isTablet ? 40.0 : 52.0,
                    decoration: BoxDecoration(
                      color: colors[idx],
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.onBackground,
                          width: isTablet ? 2.0 : 3.0),
                    ),
                    child: Icon(icons[idx],
                        color: Colors.white, size: isTablet ? 18.0 : 24.0),
                  ),
                  SizedBox(width: isTablet ? 10.0 : 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Step ${entry.key + 1}",
                          style: GoogleFonts.lexend(
                            fontSize: isTablet ? 10.0 : 12.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          entry.value,
                          style: GoogleFonts.lexend(
                            fontSize: isTablet ? 13.0 : 16.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMainArea(BuildContext context, {required bool isTablet}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Look what you made! ✨",
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTablet ? 20.0 : 28.0,
            fontWeight: FontWeight.w800,
            color: AppColors.onBackground,
          ),
        ),
        SizedBox(height: isTablet ? 16.0 : 20.0),

        // Preview area
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(isTablet ? 18.0 : 22.0),
              border: Border.all(
                  color: AppColors.onBackground,
                  width: isTablet ? 3.5 : 5.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onBackground,
                  offset: Offset(isTablet ? 5.0 : 7.0, isTablet ? 5.0 : 7.0),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(isTablet ? 14.0 : 17.0),
                  child: _thumbnailBytes != null
                      ? Image.memory(_thumbnailBytes!, fit: BoxFit.cover)
                      : Container(color: AppColors.surfaceVariant),
                ),
                if (_isLoading)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.8),
                      borderRadius:
                          BorderRadius.circular(isTablet ? 14.0 : 17.0),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RotationTransition(
                            turns: _spinController,
                            child: Text("🪄",
                                style: TextStyle(
                                    fontSize: isTablet ? 48.0 : 60.0)),
                          ),
                          SizedBox(height: isTablet ? 12.0 : 16.0),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              _loadingMessages[_loadingMessageIndex],
                              key: ValueKey(_loadingMessageIndex),
                              style: GoogleFonts.lexend(
                                fontSize: isTablet ? 14.0 : 18.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onBackground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        SizedBox(height: isTablet ? 20.0 : 28.0),

        // Follow-up chips
        if (_followUps.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: isTablet ? 12.0 : 16.0),
            child: Wrap(
              spacing: isTablet ? 6.0 : 8.0,
              runSpacing: isTablet ? 6.0 : 8.0,
              children: _followUps.reversed.take(3).map((text) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12.0 : 16.0,
                    vertical: isTablet ? 5.0 : 7.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppColors.onBackground,
                        width: isTablet ? 1.5 : 2.0),
                  ),
                  child: Text(
                    "🪄 $text",
                    style: GoogleFonts.lexend(
                      fontSize: isTablet ? 11.0 : 13.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // Magic Wand Input
        Container(
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
                  controller: _promptController,
                  decoration: InputDecoration(
                    hintText: "Make the cat dance!...",
                    hintStyle: GoogleFonts.lexend(
                      fontSize: isTablet ? 13.0 : 16.0,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.lexend(
                    fontSize: isTablet ? 13.0 : 16.0,
                    color: AppColors.onBackground,
                  ),
                  onSubmitted: (_) => _addFollowUp(),
                ),
              ),
              NeobrutalistButton(
                size: isTablet ? 48.0 : 58.0,
                backgroundColor: AppColors.tertiaryContainer,
                onTap: _addFollowUp,
                child: Icon(
                  Icons.send,
                  color: AppColors.onTertiaryContainer,
                  size: isTablet ? 22.0 : 28.0,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isTablet ? 28.0 : 40.0),

        // Finish & Play button
        Center(
          child: SizedBox(
            width: isTablet ? 360.0 : double.infinity,
            height: isTablet ? 72.0 : 90.0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                    left: -8,
                    top: -16,
                    child: Text("🎉", style: TextStyle(fontSize: 26))),
                const Positioned(
                    right: -8,
                    top: -12,
                    child: Text("🚀", style: TextStyle(fontSize: 32))),
                const Positioned(
                    left: 32,
                    top: -22,
                    child: Text("⭐", style: TextStyle(fontSize: 22))),
                Positioned.fill(
                  child: NeobrutalistButton(
                    isCircle: false,
                    backgroundColor: AppColors.secondaryContainer,
                    onTap: _isLoading
                        ? null
                        : () async {
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PlayScreen(
                                  htmlContent: _generatedHtml,
                                  creationType: widget.wizardState.creationType,
                                ),
                              ),
                            );
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle,
                            size: isTablet ? 34.0 : 44.0,
                            color: AppColors.onSecondaryContainer),
                        SizedBox(width: isTablet ? 10.0 : 14.0),
                        Text(
                          "Finish & Play!",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isTablet ? 20.0 : 26.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: isTablet ? 32.0 : 56.0),
      ],
    );
  }
}
