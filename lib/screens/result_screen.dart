import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:google_fonts/google_fonts.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/models/parsed_kid_input.dart';
import 'package:kapoof/models/wizard_model.dart';
import 'package:kapoof/screens/play_screen.dart';
import 'package:kapoof/services/ai_service.dart';
import 'package:kapoof/services/app_settings.dart';
import 'package:kapoof/utils/html_renderer.dart' as html_renderer;
import 'package:kapoof/widgets/kid_error_widget.dart';
import 'package:kapoof/widgets/neobrutalist_widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'dart:io';


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
    with TickerProviderStateMixin {
  final AIService _aiService = AIService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _promptController = TextEditingController();

  bool _isLoading = true;
  bool _isListening = false;
  String _generatedHtml = '';
  Uint8List? _generatedImage;
  WebViewController? _previewController;
  final List<String> _followUps = [];
  final List<_Version> _history = [];
  int _historyIndex = -1;

  bool get _isImageMode =>
      widget.wizardState.format == OutputFormat.picture ||
      widget.wizardState.format == OutputFormat.coloring;

  late AnimationController _spinController;
  late AnimationController _kapoofController;

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
    _kapoofController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _startGeneration();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _kapoofController.dispose();
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
      if (_isImageMode) {
        final bytes = widget.wizardState.format == OutputFormat.coloring
            ? await _aiService.generateColoringPage(widget.wizardState,
                parsedInput: widget.parsedInput)
            : await _aiService.generateImage(widget.wizardState,
                parsedInput: widget.parsedInput);
        if (mounted) {
          setState(() {
            _generatedImage = bytes;
            _pushHistory('image:${bytes.length}');
            _cachedSuggestions = null;
            _isLoading = false;
            _spinController.stop();
            _loadingTimer?.cancel();
          });
          _kapoofController.forward(from: 0);
        }
        return;
      }

      final html = widget.wizardState.format == OutputFormat.webpage
          ? await _aiService.generateWebpage(widget.wizardState,
              parsedInput: widget.parsedInput)
          : await _aiService.generateContent(
              widget.wizardState,
              followUps: _followUps,
              parsedInput: widget.parsedInput,
            );

      if (html.trim().isEmpty) {
        throw Exception('Model returned empty content');
      }

      if (mounted) {
        setState(() {
          _generatedHtml = html;
          if (!kIsWeb) {
            _previewController = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadHtmlString(html);
          }
          _pushHistory(html);
          _cachedSuggestions = null;
          _isLoading = false;
          _spinController.stop();
          _loadingTimer?.cancel();
        });
        _kapoofController.forward(from: 0);
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

  static const Map<String, List<String>> _remixPool = {
    'story': [
      '🐉 Add a dragon', '😂 Make it funnier', '✨ Add more magic',
      '🌈 Change the colors', '🎵 Add a song', '👻 Add a spooky surprise',
      '🦄 Add a unicorn friend', '🌙 Make it night time', '☀️ Make it sunny',
      '🎂 Add a birthday', '🐱 Add a talking cat', '🚀 Add a rocket trip',
      '🍕 Add yummy food', '👑 Add a king or queen', '🌊 Add the ocean',
      '⛄ Make it snowy', '🎪 Add a circus', '🦖 Add a dinosaur',
      '🧙 Add a wizard', '🎈 Add lots of balloons', '💖 Make it sweeter',
      '🌟 Bigger ending',
    ],
    'dartgame': [
      '⚡ Make it faster', '🎯 Harder enemies', '🏆 Bigger rewards',
      '🌟 New super power', '🎨 Change the look', '🚀 Add a rocket',
      '💣 Add bombs', '🛡️ Add a shield', '👻 Spooky enemies',
      '🦖 Dinosaur enemies', '🍎 Add fruit to collect', '⏱️ Add a timer',
      '🏰 Add a boss fight', '🎁 Surprise gift drops', '🌈 Rainbow mode',
      '🔥 Fire trail', '❄️ Freeze enemies', '⚔️ Add a sword',
      '🎵 Add music', '🌙 Night level', '🎪 Carnival theme',
      '🎉 Easier mode',
    ],
    'drawing': [
      '🌈 More colors', '✨ More sparkles', '🎵 Add sounds',
      '🦄 Add a unicorn', '🎉 Make it party!', '🐉 Add a dragon',
      '🌊 Add bubbles', '⭐ Add stars', '🌸 Add flowers',
      '🌙 Make it night', '☀️ Make it sunny', '⛄ Make it snowy',
      '🎈 Add balloons', '❤️ Add hearts', '🎆 Add fireworks',
      '🐠 Add fish', '🦋 Add butterflies', '🍭 Add candy',
      '👻 Add a ghost', '🤖 Add a robot', '🎂 Add a cake',
      '🌀 Make it spin', '💥 Make it explode',
    ],
  };

  List<String>? _cachedSuggestions;
  List<String> _remixSuggestions() {
    if (_cachedSuggestions != null) return _cachedSuggestions!;
    final type = widget.wizardState.creationType;
    final pool = List<String>.from(_remixPool[type] ?? _remixPool['drawing']!);
    pool.shuffle();
    _cachedSuggestions = pool.take(8).toList();
    return _cachedSuggestions!;
  }

  void _pushHistory(String html) {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(_Version(html, List.from(_followUps)));
    if (_history.length > 5) _history.removeAt(0);
    _historyIndex = _history.length - 1;
  }

  void _restoreVersion(int index) {
    final v = _history[index];
    setState(() {
      _historyIndex = index;
      _generatedHtml = v.html;
      _followUps
        ..clear()
        ..addAll(v.followUps);
      if (!kIsWeb) {
        _previewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadHtmlString(v.html);
      }
    });
  }

  bool get _canUndo => _historyIndex > 0;
  bool get _canRedo => _historyIndex < _history.length - 1;

  Widget _historyButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: NeobrutalistButton(
        size: isTablet ? 36.0 : 44.0,
        backgroundColor: AppColors.surface,
        onTap: enabled ? onTap : () {},
        child: Icon(icon,
            size: isTablet ? 18.0 : 22.0, color: AppColors.onBackground),
      ),
    );
  }

  Future<void> _surpriseMe() async {
    final remix = await _aiService.generateSurpriseRemix(
      widget.wizardState.creationType,
      _generatedHtml,
    );
    if (!mounted) return;
    setState(() => _followUps.add(remix));
    _startGeneration();
  }

  Widget _surpriseChip(bool isTablet) {
    return GestureDetector(
      onTap: _isLoading ? null : _surpriseMe,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 12.0 : 16.0,
          vertical: isTablet ? 6.0 : 8.0,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(isTablet ? 18.0 : 22.0),
          border: Border.all(
              color: AppColors.onBackground, width: isTablet ? 2.0 : 3.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.onBackground,
              offset: Offset(isTablet ? 2.0 : 3.0, isTablet ? 2.0 : 3.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          '🎲 Surprise Me!',
          style: GoogleFonts.lexend(
            fontSize: isTablet ? 12.0 : 14.0,
            fontWeight: FontWeight.w800,
            color: AppColors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _remixChip(String label, bool isTablet) {
    return GestureDetector(
      onTap: _isLoading ? null : () {
        setState(() => _followUps.add(label));
        _startGeneration();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 12.0 : 16.0,
          vertical: isTablet ? 6.0 : 8.0,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(isTablet ? 18.0 : 22.0),
          border: Border.all(
              color: AppColors.onBackground, width: isTablet ? 2.0 : 3.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.onBackground,
              offset: Offset(isTablet ? 2.0 : 3.0, isTablet ? 2.0 : 3.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: isTablet ? 12.0 : 14.0,
            fontWeight: FontWeight.w700,
            color: AppColors.onBackground,
          ),
        ),
      ),
    );
  }

  String _summarizeWhatIBuilt() {
    final p = widget.parsedInput;
    final a = widget.wizardState.answers;
    final hero = p?.hero ?? a[0] ?? '';
    final world = p?.world ?? a[1] ?? '';
    final mood = p?.mood ?? a[2] ?? '';
    final extras = (p != null && p.extras.isNotEmpty)
        ? p.extras.join(', ')
        : (a[3] ?? '');

    final parts = <String>[];
    if (hero.isNotEmpty) parts.add(hero);
    if (world.isNotEmpty) parts.add('in $world');
    if (mood.isNotEmpty) parts.add('($mood)');
    final base = parts.join(' ');

    final extra = extras.isNotEmpty ? ' + $extras' : '';
    final follow = _followUps.isNotEmpty
        ? ' → ${_followUps.last}'
        : '';
    return base + extra + follow;
  }

  Widget _whatIBuiltBubble(bool isTablet) {
    final summary = _summarizeWhatIBuilt();
    if (summary.trim().isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final builderOn = AppSettings.instance.builderMode;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 14.0 : 16.0,
            vertical: isTablet ? 10.0 : 12.0,
          ),
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer,
            borderRadius: BorderRadius.circular(isTablet ? 14.0 : 18.0),
            border: Border.all(
                color: AppColors.onBackground, width: isTablet ? 2.0 : 2.5),
          ),
          child: Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 22)),
              SizedBox(width: isTablet ? 8.0 : 10.0),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.lexend(
                      fontSize: isTablet ? 12.0 : 14.0,
                      color: AppColors.onBackground,
                    ),
                    children: [
                      TextSpan(
                        text: 'I built: ',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w800,
                          fontSize: isTablet ? 12.0 : 14.0,
                          color: AppColors.onBackground,
                        ),
                      ),
                      TextSpan(text: summary),
                    ],
                  ),
                ),
              ),
              if (builderOn && _generatedHtml.isNotEmpty)
                GestureDetector(
                  onTap: _showPeekInside,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.onBackground, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.code,
                            size: 14, color: AppColors.onBackground),
                        const SizedBox(width: 4),
                        Text(
                          'Peek',
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPeekInside() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.background,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.onBackground, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🔧', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'How I built it',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'This is the actual code that runs your creation. Real websites are built like this!',
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.onBackground, width: 2.5),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: SelectableText(
                    _generatedHtml,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: Color(0xFFE0E0E0),
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '${_generatedHtml.length} characters',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: _generatedHtml));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Copied! Paste it anywhere ✨'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_isImageMode) {
      if (_generatedImage == null) {
        return Container(color: AppColors.surfaceVariant);
      }
      final isColoring = widget.wizardState.format == OutputFormat.coloring;
      return Container(
        color: isColoring ? Colors.white : AppColors.surfaceVariant,
        child: Image.memory(_generatedImage!, fit: BoxFit.contain),
      );
    }
    if (_generatedHtml.isEmpty) {
      return Container(color: AppColors.surfaceVariant);
    }
    if (kIsWeb) {
      return html_renderer.buildHtmlView(
        _generatedHtml,
        'kapoof-preview-${_generatedHtml.hashCode}',
      );
    }
    if (_previewController == null) {
      return Container(color: AppColors.surfaceVariant);
    }
    return WebViewWidget(controller: _previewController!);
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
        Row(
          children: [
            Expanded(
              child: Text(
                "Look what you made! ✨",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isTablet ? 20.0 : 28.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onBackground,
                ),
              ),
            ),
            _historyButton(
              icon: Icons.undo,
              enabled: _canUndo,
              onTap: () => _restoreVersion(_historyIndex - 1),
              isTablet: isTablet,
            ),
            SizedBox(width: isTablet ? 6.0 : 8.0),
            _historyButton(
              icon: Icons.redo,
              enabled: _canRedo,
              onTap: () => _restoreVersion(_historyIndex + 1),
              isTablet: isTablet,
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12.0 : 14.0),

        if (_generatedHtml.isNotEmpty || _generatedImage != null)
          _whatIBuiltBubble(isTablet),

        SizedBox(height: isTablet ? 12.0 : 14.0),

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
                  child: _buildPreview(),
                ),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _kapoofController,
                    builder: (context, _) {
                      final v = _kapoofController.value;
                      if (v == 0 || v == 1) return const SizedBox.shrink();
                      final scale = 0.6 + v * 1.8;
                      final opacity = (1 - v).clamp(0.0, 1.0);
                      return Center(
                        child: Opacity(
                          opacity: opacity,
                          child: Transform.scale(
                            scale: scale,
                            child: Text(
                              'KAPOOF! ✨',
                              style: GoogleFonts.fredoka(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary,
                                shadows: const [
                                  Shadow(
                                      blurRadius: 20,
                                      color: Colors.white,
                                      offset: Offset(0, 0)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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

        // Quick Remix chips
        if (!_isLoading && _generatedHtml.isNotEmpty) ...[
          SizedBox(
            height: isTablet ? 40.0 : 44.0,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: isTablet ? 6.0 : 8.0),
                  child: _surpriseChip(isTablet),
                ),
                ..._remixSuggestions().map((s) {
                  return Padding(
                    padding: EdgeInsets.only(right: isTablet ? 6.0 : 8.0),
                    child: _remixChip(s, isTablet),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 8.0 : 10.0),
        ],

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
                                  imageBytes: _generatedImage,
                                  format: widget.wizardState.format,
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

class _Version {
  final String html;
  final List<String> followUps;
  _Version(this.html, this.followUps);
}
