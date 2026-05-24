import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/services/app_settings.dart';
import 'package:kapoof/widgets/neobrutalist_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: Text(
              'Settings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.onBackground,
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: NeobrutalistButton(
                size: 44,
                backgroundColor: AppColors.surface,
                onTap: () => Navigator.pop(context),
                child:
                    const Icon(Icons.close, color: AppColors.onBackground),
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
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _sectionTitle('How old are you?'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ageCard(
                      mode: AgeMode.little,
                      emoji: '🧒',
                      title: 'Little',
                      subtitle: 'Ages 5–7',
                      selected: s.ageMode == AgeMode.little,
                      onTap: () => s.setAgeMode(AgeMode.little),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ageCard(
                      mode: AgeMode.big,
                      emoji: '🧑',
                      title: 'Big',
                      subtitle: 'Ages 8–10',
                      selected: s.ageMode == AgeMode.big,
                      onTap: () => s.setAgeMode(AgeMode.big),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _sectionTitle('Builder Mode 🔧'),
              const SizedBox(height: 4),
              Text(
                s.ageMode == AgeMode.big
                    ? 'On by default for Big kids — see what the AI understood and peek inside the code.'
                    : 'Turn on to see how the AI thinks and peek at the code.',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _toggleRow(
                title: 'Show me how it works',
                value: s.builderMode,
                forced: s.ageMode == AgeMode.big,
                onChanged: (v) => s.setBuilderMode(v),
              ),
              const SizedBox(height: 32),
              _sectionTitle('About'),
              const SizedBox(height: 8),
              Text(
                'Kapoof — say it, kapoof, it\'s real. ✨\nMade with Gemini.',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.onBackground,
      ),
    );
  }

  Widget _ageCard({
    required AgeMode mode,
    required String emoji,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return NeobrutalistCard(
      backgroundColor:
          selected ? AppColors.primaryContainer : AppColors.surface,
      padding: const EdgeInsets.all(16),
      borderRadius: 22,
      borderWidth: 3,
      shadowOffset: selected ? 3 : 5,
      onTap: onTap,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.onBackground,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: AppColors.onBackground.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required bool value,
    required bool forced,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.onBackground, width: 3),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackground,
              ),
            ),
          ),
          if (forced)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'always on',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          Switch(
            value: value,
            onChanged: forced ? null : onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
