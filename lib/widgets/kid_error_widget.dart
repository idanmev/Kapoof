import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/widgets/neobrutalist_widgets.dart';

class KidErrorWidget extends StatelessWidget {
  final String emoji;
  final String message;
  final VoidCallback onRetry;

  const KidErrorWidget({
    super.key,
    required this.emoji,
    required this.message,
    required this.onRetry,
  });

  factory KidErrorWidget.magicHiccup({required VoidCallback onRetry}) {
    return KidErrorWidget(
      emoji: "🙈",
      message: "Oops! The magic hiccuped! Try again!",
      onRetry: onRetry,
    );
  }

  factory KidErrorWidget.noWifi({required VoidCallback onRetry}) {
    return KidErrorWidget(
      emoji: "🌐",
      message: "We need WiFi magic! Check your connection!",
      onRetry: onRetry,
    );
  }

  factory KidErrorWidget.voiceFailed({required VoidCallback onRetry}) {
    return KidErrorWidget(
      emoji: "🎤",
      message: "I didn't catch that! Try saying it again, louder!",
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 40),
            NeobrutalistButton(
              isCircle: false,
              backgroundColor: AppColors.primaryContainer,
              onTap: onRetry,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Text(
                  "Try Again! ✨",
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
