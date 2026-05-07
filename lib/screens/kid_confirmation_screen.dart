import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/models/parsed_kid_input.dart';
import 'package:kapoof/widgets/neobrutalist_widgets.dart';

class KidConfirmationScreen extends StatefulWidget {
  final ParsedKidInput parsedInput;
  final String creationType;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;

  const KidConfirmationScreen({
    super.key,
    required this.parsedInput,
    required this.creationType,
    required this.onConfirm,
    required this.onRetry,
  });

  @override
  State<KidConfirmationScreen> createState() => _KidConfirmationScreenState();
}

class _KidConfirmationScreenState extends State<KidConfirmationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _confettiController;
  late final Animation<double> _bounceAnimation;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );
    _bounceController.forward();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final rng = math.Random();
    for (int i = 0; i < 28; i++) {
      _particles.add(_ConfettiParticle(
        x: rng.nextDouble(),
        startY: -0.1 - rng.nextDouble() * 0.4,
        speed: 0.15 + rng.nextDouble() * 0.25,
        size: 8 + rng.nextDouble() * 14,
        color: _confettiColors[rng.nextInt(_confettiColors.length)],
        phase: rng.nextDouble(),
        rotSpeed: (rng.nextDouble() - 0.5) * 4,
      ));
    }
  }

  static const _confettiColors = [
    Color(0xFFFFD700),
    Color(0xFFFC7EBD),
    Color(0xFFB4E0FF),
    Color(0xFF00CC88),
    Color(0xFFFF6B6B),
    Color(0xFFFFE16D),
    Color(0xFFA13470),
  ];

  @override
  void dispose() {
    _bounceController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final screenSize = MediaQuery.of(context).size;
    final parsed = widget.parsedInput;

    return Scaffold(
      backgroundColor: AppColors.primaryContainer,
      body: Stack(
        children: [
          // Confetti Layer
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) {
              return CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _confettiController.value,
                  screenSize: screenSize,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),

          // Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                // On tablet, constrain width for a centred card feel
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 520.0 : double.infinity,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32.0 : 28.0,
                    vertical: isTablet ? 20.0 : 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Big mood emoji
                      ScaleTransition(
                        scale: _bounceAnimation,
                        child: Text(
                          parsed.moodEmoji,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 80.0 : 110.0,
                            height: 1.0,
                          ),
                        ),
                      ),

                      SizedBox(height: isTablet ? 20.0 : 28.0),

                      // Summary card
                      NeobrutalistCard(
                        backgroundColor: Colors.white,
                        borderRadius: isTablet ? 24.0 : 30.0,
                        borderWidth: isTablet ? 3.0 : 4.0,
                        shadowOffset: isTablet ? 5.0 : 8.0,
                        padding: EdgeInsets.all(isTablet ? 22.0 : 28.0),
                        child: Column(
                          children: [
                            Text(
                              'Got it! 🎉',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isTablet ? 16.0 : 20.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                              ),
                            ),
                            SizedBox(height: isTablet ? 10.0 : 14.0),
                            Text(
                              parsed.summaryForKid,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isTablet ? 18.0 : 24.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onBackground,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isTablet ? 24.0 : 36.0),

                      // YES button
                      NeobrutalistButton(
                        isCircle: false,
                        size: isTablet ? 72.0 : 92.0,
                        backgroundColor: AppColors.secondaryContainer,
                        onTap: widget.onConfirm,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16.0 : 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🚀',
                                  style: TextStyle(
                                      fontSize: isTablet ? 28.0 : 36.0)),
                              SizedBox(width: isTablet ? 10.0 : 14.0),
                              Text(
                                'YES! Make it!',
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

                      SizedBox(height: isTablet ? 14.0 : 18.0),

                      // RETRY button
                      NeobrutalistButton(
                        isCircle: false,
                        size: isTablet ? 58.0 : 70.0,
                        backgroundColor: AppColors.surface,
                        onTap: widget.onRetry,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12.0 : 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🔄',
                                  style: TextStyle(
                                      fontSize: isTablet ? 20.0 : 26.0)),
                              SizedBox(width: isTablet ? 8.0 : 12.0),
                              Text(
                                'Hmm, change it',
                                style: GoogleFonts.lexend(
                                  fontSize: isTablet ? 14.0 : 18.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onBackground,
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
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confetti helpers ──────────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double phase;
  final double rotSpeed;

  _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.color,
    required this.phase,
    required this.rotSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  final Size screenSize;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final t = ((progress + p.phase) % 1.0);
      final y = p.startY + t * (1.2 + p.speed);
      final x = p.x + math.sin(t * math.pi * 3 + p.phase) * 0.04;

      if (y < 0 || y > 1.1) continue;

      final px = x * size.width;
      final py = y * size.height;
      final rotation = t * p.rotSpeed * math.pi * 2;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rotation);
      paint.color = p.color.withAlpha(200);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
