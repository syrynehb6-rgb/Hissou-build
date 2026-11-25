import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../navigation/adaptive_scaffold.dart';
import 'auth_screen.dart';
import 'privacy_consent_screen.dart';

class SplashScreen extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;

  const SplashScreen({super.key, required this.onLocaleChanged});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    _navigationTimer = Timer(const Duration(milliseconds: 2600), () {
      _checkNextScreen();
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkNextScreen() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final privacyAccepted = prefs.getBool('hissou_privacy_accepted') ?? false;
    final userLoggedIn = prefs.getBool('hissou_user_logged_in') ?? false;

    Widget target;
    if (!privacyAccepted) {
      target = PrivacyConsentScreen(onLocaleChanged: widget.onLocaleChanged);
    } else if (!userLoggedIn) {
      target = AuthScreen(onLocaleChanged: widget.onLocaleChanged);
    } else {
      target = AdaptiveScaffold(onLocaleChanged: widget.onLocaleChanged);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HissouColors.primaryNavyDark,
      body: GestureDetector(
        onTap: _checkNextScreen,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Ambient glowing gradient orbs
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HissouColors.accentAmber.withAlpha(35),
                  boxShadow: [
                    BoxShadow(
                      color: HissouColors.accentAmber.withAlpha(60),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HissouColors.softRose.withAlpha(30),
                  boxShadow: [
                    BoxShadow(
                      color: HissouColors.softRose.withAlpha(50),
                      blurRadius: 90,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Center Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Logo Container
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              HissouColors.accentAmber,
                              HissouColors.softRose,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: HissouColors.accentAmber.withAlpha(80),
                              blurRadius: 36,
                              spreadRadius: 4,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Container(
                            width: 120,
                            height: 120,
                            color: HissouColors.primaryNavy,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Brand Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Hissou',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: HissouColors.accentAmber.withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: HissouColors.accentAmber.withAlpha(80),
                                ),
                              ),
                              child: const Text(
                                'AI PRO',
                                style: TextStyle(
                                  color: HissouColors.accentAmber,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Compagnon Félin & Traducteur Intelligent',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom loading indicator
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: HissouColors.accentAmber,
                      strokeWidth: 2.5,
                    ),
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
