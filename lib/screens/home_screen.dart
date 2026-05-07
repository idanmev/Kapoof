import 'package:flutter/material.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/widgets/neobrutalist_widgets.dart';
import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:kapoof/screens/wizard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildFloatingDecor(isTablet),
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32.0 : 28.0,
              vertical: isTablet ? 32.0 : 48.0,
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: isTablet ? 90.0 : 120.0,
                ),
                SizedBox(height: isTablet ? 16.0 : 20.0),
                Text(
                  'What will you make today?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isTablet ? 30.0 : 42.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackground,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: isTablet ? 32.0 : 48.0),

                GridView.count(
                  crossAxisCount: isTablet ? 3 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: isTablet ? 20.0 : 32.0,
                  crossAxisSpacing: isTablet ? 20.0 : 32.0,
                  childAspectRatio: isTablet ? 1.2 : 1.15,
                  children: [
                    _buildPortalCard(
                      context: context,
                      isTablet: isTablet,
                      emoji: '🎮',
                      label: 'Make a Game',
                      color: AppColors.tertiaryContainer,
                      textColor: AppColors.onTertiaryContainer,
                      icon: Icons.sports_esports,
                      iconColor: AppColors.tertiary,
                    ),
                    _buildPortalCard(
                      context: context,
                      isTablet: isTablet,
                      emoji: '📖',
                      label: 'Tell a Story',
                      color: AppColors.primaryContainer,
                      textColor: AppColors.onPrimaryContainer,
                      icon: Icons.menu_book,
                      iconColor: AppColors.primary,
                    ),
                    _buildPortalCard(
                      context: context,
                      isTablet: isTablet,
                      emoji: '🎨',
                      label: 'Draw a Picture',
                      color: AppColors.secondaryContainer,
                      textColor: AppColors.onSecondaryContainer,
                      icon: Icons.palette,
                      iconColor: AppColors.secondary,
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 32.0 : 100.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
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
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.star,
                      color: AppColors.primary,
                      size: isTablet ? 20.0 : 26.0),
                  onTap: () {},
                ),
                SizedBox(width: isTablet ? 10.0 : 12.0),
                NeobrutalistButton(
                  size: isTablet ? 42.0 : 52.0,
                  backgroundColor: AppColors.tertiaryContainer,
                  child: Icon(Icons.auto_awesome,
                      color: AppColors.onTertiaryContainer,
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

  Widget _buildFloatingDecor(bool isTablet) {
    final s = isTablet ? 0.65 : 1.0;
    return Stack(
      children: [
        Positioned(
          top: 32,
          left: 32,
          child: _decorShape(96 * s, 96 * s, AppColors.secondaryContainer, isCircle: true),
        ),
        Positioned(
          bottom: 140,
          right: 32,
          child: Transform.rotate(
            angle: 12 * math.pi / 180,
            child: _decorShape(128 * s, 128 * s, AppColors.primaryContainer, isCircle: false),
          ),
        ),
        Positioned(
          top: 240,
          right: 32,
          child: _decorShape(56 * s, 56 * s, AppColors.tertiaryContainer, isCircle: true),
        ),
        Positioned(
          bottom: 80,
          left: 64,
          child: _decorShape(72 * s, 72 * s, AppColors.errorContainer, isCircle: true),
        ),
      ],
    );
  }

  Widget _decorShape(double w, double h, Color color, {required bool isCircle}) {
    return Opacity(
      opacity: 0.45,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(14),
          border: Border.all(color: AppColors.onBackground, width: 2.5),
        ),
      ),
    );
  }

  Widget _buildPortalCard({
    required BuildContext context,
    required bool isTablet,
    required String emoji,
    required String label,
    required Color color,
    required Color textColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return NeobrutalistCard(
      backgroundColor: color,
      borderRadius: isTablet ? 28.0 : 40.0,
      borderWidth: isTablet ? 3.5 : 5.0,
      shadowOffset: isTablet ? 5.0 : 8.0,
      padding: EdgeInsets.all(isTablet ? 16.0 : 20.0),
      onTap: () {
        String type = 'dartgame';
        if (label.contains('Story')) type = 'story';
        if (label.contains('Draw')) type = 'drawing';

        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => WizardScreen(creationType: type)),
        );
      },
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: isTablet ? 64.0 : 96.0),
                ),
                SizedBox(height: isTablet ? 6.0 : 8.0),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isTablet ? 20.0 : 28.0,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(isTablet ? 6.0 : 8.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.onBackground,
                    width: isTablet ? 2.0 : 3.0),
              ),
              child: Icon(icon,
                  color: iconColor, size: isTablet ? 18.0 : 24.0),
            ),
          ),
        ],
      ),
    );
  }
}
