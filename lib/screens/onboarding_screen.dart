import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/widgets/neobrutalist_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      emoji: "🪄",
      title: "Hi! I'm Kapoof! 🪄",
      description: "You talk, I build! Say it. Kapoof. It's real. ✨",
      color: AppColors.primaryContainer,
    ),
    OnboardingSlide(
      emoji: "🎮",
      title: "Pick a game, story or drawing",
      description: "Then answer a few fun questions to help me understand your idea.",
      color: AppColors.secondaryContainer,
      emoji2: "📖",
      emoji3: "🎨",
    ),
    OnboardingSlide(
      emoji: "✨",
      title: "Your idea comes to life!",
      description: "Show it to your friends and play together! It's pure magic.",
      color: AppColors.tertiaryContainer,
    ),
  ];

  void _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _buildSlide(_slides[index], isTablet);
            },
          ),

          // Skip Button
          if (_currentPage < _slides.length - 1)
            Positioned(
              top: Responsive.topInset(context) + 8,
              right: 20,
              child: TextButton(
                onPressed: _onFinish,
                child: Text(
                  "Skip",
                  style: GoogleFonts.lexend(
                    fontSize: isTablet ? 14.0 : 17.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
            ),

          // Indicators + CTA button
          Positioned(
            bottom: isTablet ? 36.0 : 48.0,
            left: isTablet ? 48.0 : 24.0,
            right: isTablet ? 48.0 : 24.0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => _buildIndicator(index == _currentPage, isTablet),
                  ),
                ),
                SizedBox(height: isTablet ? 24.0 : 32.0),
                if (_currentPage == _slides.length - 1)
                  NeobrutalistButton(
                    isCircle: false,
                    backgroundColor: AppColors.secondaryContainer,
                    onTap: _onFinish,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32.0 : 40.0,
                        vertical: isTablet ? 12.0 : 16.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Let's Kapoof! 🚀",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isTablet ? 18.0 : 22.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  NeobrutalistButton(
                    isCircle: false,
                    backgroundColor: AppColors.primaryContainer,
                    onTap: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32.0 : 40.0,
                        vertical: isTablet ? 12.0 : 16.0,
                      ),
                      child: Text(
                        "Next ➡️",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isTablet ? 16.0 : 20.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide, bool isTablet) {
    final imageSize = isTablet ? 180.0 : 230.0;
    final bigEmojiSize = isTablet ? 80.0 : 110.0;
    final smallEmojiSize = isTablet ? 46.0 : 64.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 56.0 : 36.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              color: slide.color,
              borderRadius: BorderRadius.circular(isTablet ? 28.0 : 36.0),
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (slide.emoji2 == null)
                  Text(
                    slide.emoji,
                    style: TextStyle(fontSize: bigEmojiSize),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(slide.emoji,
                              style: TextStyle(fontSize: smallEmojiSize)),
                          SizedBox(width: isTablet ? 6.0 : 10.0),
                          Text(slide.emoji2!,
                              style: TextStyle(fontSize: smallEmojiSize)),
                        ],
                      ),
                      Text(slide.emoji3!,
                          style: TextStyle(fontSize: smallEmojiSize)),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 36.0 : 48.0),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isTablet ? 24.0 : 30.0,
              fontWeight: FontWeight.w800,
              color: AppColors.onBackground,
              height: 1.15,
            ),
          ),
          SizedBox(height: isTablet ? 14.0 : 20.0),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: isTablet ? 14.0 : 17.0,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          SizedBox(height: isTablet ? 80.0 : 100.0),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive, bool isTablet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 4.0 : 5.0),
      height: isTablet ? 9.0 : 11.0,
      width: isActive ? (isTablet ? 30.0 : 38.0) : (isTablet ? 9.0 : 11.0),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.onBackground
            : AppColors.onBackground.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
            color: AppColors.onBackground, width: isTablet ? 1.5 : 2.0),
      ),
    );
  }
}

class OnboardingSlide {
  final String emoji;
  final String? emoji2;
  final String? emoji3;
  final String title;
  final String description;
  final Color color;

  OnboardingSlide({
    required this.emoji,
    this.emoji2,
    this.emoji3,
    required this.title,
    required this.description,
    required this.color,
  });
}
