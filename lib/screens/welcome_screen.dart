import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/seamless_route.dart';
import 'home_screen.dart';

/// Opening shot of the demo: a breathing orb, the brand and a single
/// glowing CTA that drifts into the home hub seamlessly.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();
  late final AnimationController _cta = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _intro.dispose();
    _cta.dispose();
    super.dispose();
  }

  /// Staggered fade-up curve for the intro sequence.
  Animation<double> _stagger(double from, double to) {
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(from, to, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                // Orb flies into the home header on tap.
                FadeTransition(
                  opacity: _stagger(0, 0.45),
                  child: ScaleTransition(
                    scale: _stagger(0, 0.55),
                    child: const Hero(
                      tag: 'orb',
                      child: BreathingOrb(size: 210),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _stagger(0.25, 0.6),
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(_stagger(0.25, 0.65)),
                    child: Column(
                      children: [
                        Text(
                          'MEDITATION',
                          style: TextStyle(
                            fontFamily: 'Quicksand',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: 7,
                            color: AppTheme.textMuted.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '& Frequency',
                          style: TextStyle(
                            fontFamily: 'CormorantGaramond',
                            fontWeight: FontWeight.w600,
                            fontSize: 52,
                            height: 1,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Tune in. Drift away. Feel the shift.',
                          textAlign: TextAlign.center,
                          style: mutedStyle.copyWith(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _stagger(0.55, 0.9),
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(_stagger(0.55, 1)),
                    child: _BeginButton(cta: _cta),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BeginButton extends StatelessWidget {
  const _BeginButton({required this.cta});

  final AnimationController cta;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cta,
      builder: (context, _) {
        final glow = Curves.easeInOut.transform(cta.value);
        return Semantics(
          button: true,
          label: 'Begin',
          child: GestureDetector(
            key: const Key('begin'),
            onTap: () => pushSeamless(context, const HomeScreen()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: const LinearGradient(
                  colors: [AppTheme.violet, AppTheme.pink],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.violet.withValues(alpha: 0.35 + 0.25 * glow),
                    blurRadius: 28 + 14 * glow,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Begin',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
