import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/services/ai_service.dart';
import 'package:kapoof/utils/html_renderer.dart' as html_renderer;
import 'package:kapoof/widgets/neobrutalist_widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebsiteModeScreen extends StatefulWidget {
  const WebsiteModeScreen({super.key});

  @override
  State<WebsiteModeScreen> createState() => _WebsiteModeScreenState();
}

class _WebsiteModeScreenState extends State<WebsiteModeScreen>
    with SingleTickerProviderStateMixin {
  final AIService _aiService = AIService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _hobbyController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<String> _hobbies = [];
  String _vibe = '🌌 Galaxy';
  String? _photoBase64;
  String _generatedHtml = '';
  WebViewController? _previewController;
  bool _isLoading = false;
  late AnimationController _spinController;

  static const _vibes = [
    '🌌 Galaxy',
    '🌳 Forest',
    '🌊 Underwater',
    '🍭 Candy',
    '🦄 Rainbow',
    '🤖 Robot',
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
    _nameController.dispose();
    _ageController.dispose();
    _hobbyController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 60,
        maxWidth: 600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _photoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't get photo: $e")),
      );
    }
  }

  void _addHobby() {
    final hobby = _hobbyController.text.trim();
    if (hobby.isEmpty) return;
    setState(() {
      _hobbies.add(hobby);
      _hobbyController.clear();
    });
  }

  Future<void> _build() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type your name first!')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _spinController.repeat();
    });
    try {
      final html = await _aiService.generatePersonalSite(
        name: name,
        age: int.tryParse(_ageController.text.trim()),
        hobbies: _hobbies,
        vibe: _vibe,
        photoBase64: _photoBase64,
      );
      if (!mounted) return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Build failed: $e')),
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
              child: const Text('🌐', style: TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 16),
            Text(
              'Building your website...',
              style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }
    if (_generatedHtml.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌐', style: TextStyle(fontSize: 96)),
              const SizedBox(height: 12),
              Text(
                'Your website will appear here!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onBackground,
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
        'kapoof-site-${_generatedHtml.hashCode}',
      );
    }
    if (_previewController == null) {
      return Container(color: AppColors.surfaceVariant);
    }
    return WebViewWidget(controller: _previewController!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Text('🌐', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Text(
              'Website Mode',
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
        actions: [
          if (kIsWeb && _generatedHtml.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: NeobrutalistButton(
                size: 44,
                backgroundColor: AppColors.tertiaryContainer,
                onTap: () => html_renderer.downloadBytes(
                  utf8.encode(_generatedHtml),
                  'my-website.html',
                  'text/html',
                ),
                child: const Icon(Icons.download,
                    color: AppColors.onBackground, size: 22),
              ),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(3),
          child: SizedBox(
            height: 3,
            child: ColoredBox(color: AppColors.onBackground),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Photo + name row
            Row(
              children: [
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.onBackground, width: 3),
                      image: _photoBase64 != null
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(
                                  _photoBase64!.split(',').last)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _photoBase64 == null
                        ? const Icon(Icons.add_a_photo,
                            color: AppColors.onBackground, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kidField(
                        controller: _nameController,
                        label: 'Your name',
                        emoji: '👋',
                      ),
                      const SizedBox(height: 8),
                      _kidField(
                        controller: _ageController,
                        label: 'Age',
                        emoji: '🎂',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Hobbies
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My hobbies',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onBackground,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _kidField(
                    controller: _hobbyController,
                    label: 'add a hobby',
                    emoji: '🎨',
                    onSubmitted: (_) => _addHobby(),
                  ),
                ),
                const SizedBox(width: 10),
                NeobrutalistButton(
                  size: 50,
                  backgroundColor: AppColors.tertiaryContainer,
                  onTap: _addHobby,
                  child: const Icon(Icons.add,
                      color: AppColors.onBackground, size: 26),
                ),
              ],
            ),
            if (_hobbies.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _hobbies
                    .map((h) => Chip(
                          label: Text(h),
                          backgroundColor: AppColors.secondaryContainer,
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () =>
                              setState(() => _hobbies.remove(h)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 18),

            // Vibe
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pick a vibe',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onBackground,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _vibes.map((v) {
                final selected = _vibe == v;
                return GestureDetector(
                  onTap: () => setState(() => _vibe = v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryContainer
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: AppColors.onBackground, width: 2.5),
                    ),
                    child: Text(
                      v,
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // Build button
            NeobrutalistButton(
              isCircle: false,
              size: 64,
              backgroundColor: AppColors.primaryContainer,
              onTap: _isLoading ? null : _build,
              child: Center(
                child: Text(
                  _isLoading ? 'Building... 🛠️' : '✨ Build my website! ✨',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Preview
            Container(
              height: 500,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.onBackground, width: 4),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _kidField({
    required TextEditingController controller,
    required String label,
    required String emoji,
    TextInputType? keyboardType,
    void Function(String)? onSubmitted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.onBackground, width: 2.5),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: label,
                hintStyle: GoogleFonts.lexend(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
              ),
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: AppColors.onBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
