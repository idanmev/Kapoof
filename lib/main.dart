// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kapoof/core/theme.dart';
import 'package:kapoof/screens/home_screen.dart';
import 'package:kapoof/screens/gallery_screen.dart';
import 'package:kapoof/screens/onboarding_screen.dart';
import 'package:kapoof/services/app_settings.dart';
// import 'package:kapoof/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // await Firebase.initializeApp();
  // await FirebaseService().ensureAnonymousAuth();

  await AppSettings.instance.load();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(MagicAIBuilderApp(onboardingComplete: onboardingComplete));
}

class MagicAIBuilderApp extends StatelessWidget {
  final bool onboardingComplete;
  const MagicAIBuilderApp({super.key, required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kapoof',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: onboardingComplete ? '/' : '/onboarding',
      routes: {
        '/': (context) => const MainShell(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const GalleryScreen(),
    const Center(child: Text("Help Screen Placeholder")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final navHeight = isTablet ? 68.0 : 90.0;
    final itemSize = isTablet ? 52.0 : 70.0;
    final iconSize = isTablet ? 22.0 : 28.0;
    final fontSize = isTablet ? 11.0 : 13.0;

    return Container(
      height: navHeight,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        border: const Border(
          top: BorderSide(color: AppColors.onBackground, width: 3),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.onBackground,
            offset: Offset(0, -3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, 0, 'Home', Icons.home_filled, itemSize, iconSize, fontSize),
          _navItem(context, 1, 'Creations', Icons.palette_outlined, itemSize, iconSize, fontSize),
          _navItem(context, 2, 'Help', Icons.help_outline, itemSize, iconSize, fontSize),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int index,
    String label,
    IconData icon,
    double itemSize,
    double iconSize,
    double fontSize,
  ) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        width: itemSize,
        height: itemSize,
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: AppTheme.radiusMD,
                border: Border.all(color: AppColors.onBackground, width: 2.5),
                boxShadow: AppTheme.shadow(offset: 3),
              )
            : null,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: isActive
                    ? AppColors.onSecondaryContainer
                    : AppColors.onPrimaryContainer,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? AppColors.onSecondaryContainer
                      : AppColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
