import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/models/wizard_model.dart';
import 'package:kapoof/services/ai_service.dart';
import 'package:kapoof/utils/html_renderer.dart' as html_renderer;
import 'package:kapoof/widgets/neobrutalist_widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TeacherModeScreen extends StatefulWidget {
  const TeacherModeScreen({super.key});

  @override
  State<TeacherModeScreen> createState() => _TeacherModeScreenState();
}

class _TeacherModeScreenState extends State<TeacherModeScreen>
    with TickerProviderStateMixin {
  final AIService _aiService = AIService();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _remixController = TextEditingController();

  String _creationType = 'story';
  String _generatedHtml = '';
  WebViewController? _webController;
  bool _isLoading = false;

  final Map<String, int> _votes = {'😂': 0, '❤️': 0, '🤯': 0, '✨': 0};
  final List<_FloatingReaction> _floaters = [];
  final Random _rng = Random();
  Timer? _floaterCleanup;

  @override
  void dispose() {
    _topicController.dispose();
    _remixController.dispose();
    _floaterCleanup?.cancel();
    super.dispose();
  }

  Future<void> _generate({String? remix}) async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty && remix == null) return;
    setState(() => _isLoading = true);
    try {
      final state = WizardState(
        creationType: _creationType,
        answers: {0: topic, 1: 'Classroom', 2: 'Fun', 3: 'Magic', 4: 'Wonder'},
      );
      final html = await _aiService.generateContent(
        state,
        followUps: remix != null ? [remix] : [],
      );
      if (!mounted) return;
      setState(() {
        _generatedHtml = html;
        if (!kIsWeb) {
          _webController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadHtmlString(html);
        }
        if (remix == null) _votes.updateAll((k, v) => 0);
        _isLoading = false;
        _remixController.clear();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
      }
    }
  }

  void _addReaction(String emoji) {
    setState(() {
      _votes[emoji] = (_votes[emoji] ?? 0) + 1;
      _floaters.add(_FloatingReaction(
        emoji: emoji,
        startX: _rng.nextDouble(),
        id: DateTime.now().microsecondsSinceEpoch,
      ));
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _floaters.removeWhere((f) =>
          DateTime.now().microsecondsSinceEpoch - f.id > 3000000));
    });
  }

  Widget _buildPreview() {
    if (_generatedHtml.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎓', style: TextStyle(fontSize: 96)),
              const SizedBox(height: 12),
              Text(
                'Teacher Mode',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type a topic above and press Generate.\nThe class can react with emoji while you remix together.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 16,
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
        'kapoof-teacher-${_generatedHtml.hashCode}',
      );
    }
    if (_webController == null) {
      return Container(color: AppColors.surfaceVariant);
    }
    return WebViewWidget(controller: _webController!);
  }

  Widget _typePill(String label, String value, String emoji) {
    final selected = _creationType == value;
    return GestureDetector(
      onTap: () => setState(() => _creationType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.onBackground, width: 2.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voteButton(String emoji) {
    final count = _votes[emoji] ?? 0;
    return GestureDetector(
      onTap: () => _addReaction(emoji),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.onBackground, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppColors.onBackground,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Text('🎓', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Text(
              'Teacher Mode',
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
          // Topic input row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: AppColors.onBackground, width: 3),
                        ),
                        child: TextField(
                          controller: _topicController,
                          decoration: InputDecoration(
                            hintText: 'Topic for the class — e.g. "ocean animals"',
                            hintStyle: GoogleFonts.lexend(fontSize: 14),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _generate(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    NeobrutalistButton(
                      size: 56,
                      backgroundColor: AppColors.primaryContainer,
                      onTap: _isLoading ? () {} : () => _generate(),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : const Icon(Icons.auto_awesome,
                              color: AppColors.onBackground, size: 26),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _typePill('Story', 'story', '📖'),
                    const SizedBox(width: 8),
                    _typePill('Drawing', 'drawing', '🎨'),
                    const SizedBox(width: 8),
                    _typePill('Game', 'dartgame', '🎮'),
                  ],
                ),
              ],
            ),
          ),

          // Big projector preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.onBackground, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.onBackground,
                      offset: Offset(6, 6),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      _buildPreview(),
                      ..._floaters.map((f) => _FloatingReactionWidget(
                            key: ValueKey(f.id),
                            emoji: f.emoji,
                            startX: f.startX,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Remix bar
          if (_generatedHtml.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: AppColors.onBackground, width: 3),
                      ),
                      child: TextField(
                        controller: _remixController,
                        decoration: InputDecoration(
                          hintText: 'Class suggestion — "make it bigger!"',
                          hintStyle: GoogleFonts.lexend(fontSize: 14),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (text) => _generate(remix: text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeobrutalistButton(
                    size: 56,
                    backgroundColor: AppColors.tertiaryContainer,
                    onTap: _isLoading
                        ? () {}
                        : () => _generate(remix: _remixController.text.trim()),
                    child: const Icon(Icons.send,
                        color: AppColors.onBackground, size: 24),
                  ),
                ],
              ),
            ),

          // Voting bar
          if (_generatedHtml.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.onBackground, width: 3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _votes.keys.map(_voteButton).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingReaction {
  final String emoji;
  final double startX;
  final int id;
  _FloatingReaction({
    required this.emoji,
    required this.startX,
    required this.id,
  });
}

class _FloatingReactionWidget extends StatefulWidget {
  final String emoji;
  final double startX;
  const _FloatingReactionWidget({
    super.key,
    required this.emoji,
    required this.startX,
  });

  @override
  State<_FloatingReactionWidget> createState() =>
      _FloatingReactionWidgetState();
}

class _FloatingReactionWidgetState extends State<_FloatingReactionWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return LayoutBuilder(
          builder: (context, constraints) {
            return Positioned(
              left: widget.startX * (constraints.maxWidth - 60),
              bottom: t * (constraints.maxHeight - 80),
              child: Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1 + t * 0.5,
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
