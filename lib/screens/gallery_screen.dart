import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/widgets/neobrutalist_widgets.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, isTablet),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 36.0 : 44.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🚧', style: TextStyle(fontSize: isTablet ? 72.0 : 88.0)),
              SizedBox(height: isTablet ? 18.0 : 22.0),
              Text(
                "Coming Soon!",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isTablet ? 24.0 : 30.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: isTablet ? 12.0 : 16.0),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 400.0 : 340.0),
                child: Text(
                  "Your gallery of magic creations is being built by our smartest wizards. Check back soon! ✨",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: isTablet ? 14.0 : 17.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 28.0 : 36.0),
              NeobrutalistButton(
                isCircle: false,
                size: isTablet ? 56.0 : 68.0,
                backgroundColor: AppColors.primaryContainer,
                borderRadius: isTablet ? 14.0 : 18.0,
                onTap: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 18.0 : 24.0,
                    vertical: isTablet ? 8.0 : 10.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home,
                          color: AppColors.onPrimaryContainer,
                          size: isTablet ? 18.0 : 22.0),
                      SizedBox(width: isTablet ? 6.0 : 8.0),
                      Text(
                        'Go back home',
                        style: GoogleFonts.lexend(
                          fontSize: isTablet ? 14.0 : 17.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimaryContainer,
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
          children: [
            Text(
              'My Creations ✨',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isTablet ? 22.0 : 28.0,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
