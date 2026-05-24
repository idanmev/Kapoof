import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/models/wizard_model.dart';
import 'package:kapoof/screens/wizard_screen.dart';
import 'package:kapoof/widgets/neobrutalist_widgets.dart';

class FormatChooserScreen extends StatelessWidget {
  final String creationType;
  const FormatChooserScreen({super.key, required this.creationType});

  List<_FormatOption> get _options {
    if (creationType == 'drawing') {
      return [
        _FormatOption(
          format: OutputFormat.interactive,
          emoji: '🎮',
          title: 'Animated',
          subtitle: 'Tap to play with it!',
          color: AppColors.primaryContainer,
        ),
        _FormatOption(
          format: OutputFormat.picture,
          emoji: '🖼️',
          title: 'Picture',
          subtitle: 'Save as wallpaper or share',
          color: AppColors.tertiaryContainer,
        ),
        _FormatOption(
          format: OutputFormat.coloring,
          emoji: '✏️',
          title: 'Color page',
          subtitle: 'Print and color it in!',
          color: AppColors.secondaryContainer,
        ),
      ];
    }
    if (creationType == 'story') {
      return [
        _FormatOption(
          format: OutputFormat.interactive,
          emoji: '🎮',
          title: 'Animated',
          subtitle: 'Magical, animated, fun!',
          color: AppColors.primaryContainer,
        ),
        _FormatOption(
          format: OutputFormat.webpage,
          emoji: '📄',
          title: 'Webpage',
          subtitle: 'A real website you made!',
          color: AppColors.tertiaryContainer,
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  NeobrutalistButton(
                    size: isTablet ? 44.0 : 52.0,
                    onTap: () => Navigator.pop(context),
                    backgroundColor: AppColors.surface,
                    child: Icon(Icons.arrow_back,
                        color: AppColors.onBackground,
                        size: isTablet ? 20.0 : 26.0),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 18.0 : 24.0),
              Text(
                'How do you want it? ✨',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isTablet ? 28.0 : 36.0,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onBackground,
                  height: 1.1,
                ),
              ),
              SizedBox(height: isTablet ? 24.0 : 32.0),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: isTablet ? 14.0 : 18.0),
                  itemBuilder: (context, i) =>
                      _buildOptionCard(context, _options[i], isTablet),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, _FormatOption opt, bool isTablet) {
    return NeobrutalistCard(
      backgroundColor: opt.color,
      padding: EdgeInsets.all(isTablet ? 18.0 : 22.0),
      borderRadius: isTablet ? 22.0 : 28.0,
      borderWidth: isTablet ? 3.0 : 4.0,
      shadowOffset: isTablet ? 5.0 : 7.0,
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => WizardScreen(
              creationType: creationType,
              format: opt.format,
            ),
          ),
        );
      },
      child: Row(
        children: [
          Text(opt.emoji, style: TextStyle(fontSize: isTablet ? 56.0 : 72.0)),
          SizedBox(width: isTablet ? 16.0 : 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opt.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isTablet ? 22.0 : 28.0,
                    fontWeight: FontWeight.w900,
                    color: AppColors.onBackground,
                  ),
                ),
                SizedBox(height: isTablet ? 4.0 : 6.0),
                Text(
                  opt.subtitle,
                  style: GoogleFonts.lexend(
                    fontSize: isTablet ? 13.0 : 15.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackground.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios,
              color: AppColors.onBackground, size: isTablet ? 18.0 : 22.0),
        ],
      ),
    );
  }
}

class _FormatOption {
  final OutputFormat format;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  _FormatOption({
    required this.format,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
