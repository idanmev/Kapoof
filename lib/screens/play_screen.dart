import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/models/wizard_model.dart';
import 'package:kapoof/utils/html_renderer.dart' as html_renderer;
import 'package:kapoof/widgets/neobrutalist_widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PlayScreen extends StatefulWidget {
  final String htmlContent;
  final String creationType;
  final Uint8List? imageBytes;
  final OutputFormat format;

  const PlayScreen({
    super.key,
    required this.htmlContent,
    required this.creationType,
    this.imageBytes,
    this.format = OutputFormat.interactive,
  });

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  WebViewController? _controller;
  final FlutterTts _tts = FlutterTts();
  bool _isReading = false;

  bool get _isImageMode =>
      widget.format == OutputFormat.picture ||
      widget.format == OutputFormat.coloring;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && !_isImageMode) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadHtmlString(widget.htmlContent);
    }
    _tts.setSpeechRate(0.45);
    _tts.setPitch(1.15);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isReading = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  String _extractText(String html) {
    final noScript = html.replaceAll(
        RegExp(r'<(script|style)[^>]*>.*?</\1>', dotAll: true), ' ');
    final noTags = noScript.replaceAll(RegExp(r'<[^>]+>'), ' ');
    return noTags
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .trim();
  }

  Future<void> _toggleReadAloud() async {
    if (_isReading) {
      await _tts.stop();
      setState(() => _isReading = false);
    } else {
      final text = _extractText(widget.htmlContent);
      if (text.isEmpty) return;
      setState(() => _isReading = true);
      await _tts.speak(text);
    }
  }

  void _saveImage() {
    if (widget.imageBytes == null) return;
    final filename = widget.format == OutputFormat.coloring
        ? 'kapoof-coloring-${DateTime.now().millisecondsSinceEpoch}.png'
        : 'kapoof-picture-${DateTime.now().millisecondsSinceEpoch}.png';
    html_renderer.downloadBytes(widget.imageBytes!, filename, 'image/png');
  }

  void _printContent() {
    if (_isImageMode && widget.imageBytes != null) {
      html_renderer.printImage(widget.imageBytes!);
    } else if (widget.htmlContent.isNotEmpty) {
      html_renderer.printHtml(widget.htmlContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    final typeName = widget.format == OutputFormat.coloring
        ? 'Coloring Page'
        : widget.format == OutputFormat.picture
            ? 'Picture'
            : widget.format == OutputFormat.webpage
                ? 'Webpage'
                : widget.creationType == 'dartgame'
                    ? 'Game'
                    : widget.creationType == 'story'
                        ? 'Story'
                        : widget.creationType == 'website'
                            ? 'Website'
                            : widget.creationType == 'learning'
                                ? 'Lesson'
                                : 'Drawing';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Your Magic $typeName',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: isTablet ? 20.0 : 24.0,
            fontWeight: FontWeight.w800,
            color: AppColors.onBackground,
          ),
        ),
        backgroundColor: AppColors.surface,
        toolbarHeight: isTablet ? 56.0 : 64.0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: NeobrutalistButton(
            size: isTablet ? 40.0 : 48.0,
            onTap: () => Navigator.pop(context),
            backgroundColor: AppColors.surface,
            child: Icon(Icons.close,
                color: AppColors.onBackground, size: isTablet ? 18.0 : 22.0),
          ),
        ),
        actions: [
          if (kIsWeb && _isImageMode)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: NeobrutalistButton(
                size: isTablet ? 40.0 : 48.0,
                onTap: _saveImage,
                backgroundColor: AppColors.tertiaryContainer,
                child: Icon(Icons.download,
                    color: AppColors.onBackground,
                    size: isTablet ? 18.0 : 22.0),
              ),
            ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: NeobrutalistButton(
                size: isTablet ? 40.0 : 48.0,
                onTap: _printContent,
                backgroundColor: AppColors.primaryContainer,
                child: Icon(Icons.print,
                    color: AppColors.onBackground,
                    size: isTablet ? 18.0 : 22.0),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            color: AppColors.onBackground,
          ),
        ),
      ),
      body: _buildBody(isTablet),
      floatingActionButton:
          (widget.creationType == 'story' || widget.creationType == 'learning')
              ? FloatingActionButton.extended(
                  onPressed: _toggleReadAloud,
                  backgroundColor: _isReading
                      ? AppColors.errorContainer
                      : AppColors.primaryContainer,
                  icon: Icon(
                    _isReading ? Icons.stop : Icons.volume_up,
                    color: AppColors.onBackground,
                  ),
                  label: Text(
                    _isReading ? 'Stop' : 'Read Aloud',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w800,
                      color: AppColors.onBackground,
                    ),
                  ),
                )
              : null,
    );
  }

  Widget _buildBody(bool isTablet) {
    if (_isImageMode && widget.imageBytes != null) {
      return Container(
        color: widget.format == OutputFormat.coloring
            ? Colors.white
            : AppColors.background,
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: Center(
          child: Image.memory(widget.imageBytes!, fit: BoxFit.contain),
        ),
      );
    }
    if (kIsWeb) {
      return html_renderer.buildHtmlView(
        widget.htmlContent,
        'kapoof-play-${widget.hashCode}',
      );
    }
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.creationType == 'story' &&
        widget.format == OutputFormat.interactive) {
      return _buildStoryReader(isTablet);
    }
    return WebViewWidget(controller: _controller!);
  }

  Widget _buildStoryReader(bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 20.0 : 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 24.0 : 28.0),
        border: Border.all(
            color: AppColors.onBackground, width: isTablet ? 3.0 : 4.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.onBackground,
            offset: Offset(isTablet ? 5.0 : 7.0, isTablet ? 5.0 : 7.0),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 21.0 : 24.0),
        child: WebViewWidget(controller: _controller!),
      ),
    );
  }
}
