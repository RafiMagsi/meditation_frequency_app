import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import 'ambient_background.dart';
import 'card_face.dart';
import 'cosmic_video.dart';
import 'deck.dart';
import 'glass_button.dart';
import 'medallion.dart';

/// The card a hub card morphs into: same style and artwork, larger, with
/// the screen's title. Kept out of the deck so the hero lands cleanly.
class FeatureHeader extends StatelessWidget {
  const FeatureHeader({
    super.key,
    required this.heroTag,
    required this.style,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.height = 156,
    this.child,
  });

  final Object heroTag;
  final CardStyle style;
  final String title;
  final String subtitle;
  final String? eyebrow;
  final double height;

  /// Replaces the default title block (e.g. the black-card header).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final metal = Color.lerp(style.glow, Colors.white, 0.35)!;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CardHero(
        tag: heroTag,
        face: CardFace(
          style: style,
          borderRadius: 28,
          padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
          contentAlignment: Alignment.centerLeft,
          child: child ??
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (eyebrow != null) ...[
                          Text(eyebrow!, maxLines: 1, style: capsStyle(color: metal, size: 10)),
                          const SizedBox(height: 8),
                        ],
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            maxLines: 1,
                            style: const TextStyle(
                              fontFamily: 'InterDisplay',
                              fontWeight: FontWeight.w600,
                              fontSize: 29,
                              height: 1,
                              color: AppTheme.ivory,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: mutedStyle.copyWith(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Medallion(style: style, size: math.min(96, height - 44)),
                ],
              ),
        ),
      ),
    );
  }
}

/// Shared layout for feature screens: glass top bar, hero header, then a
/// deck of cards dealt in one after another.
class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({
    super.key,
    required this.header,
    required this.accent,
    this.children = const [],
    this.actions = const [],
    this.body,
    this.background,
  });

  final Widget header;
  final Color accent;

  /// Scrolling deck of cards (each one becomes a [DeckItem]).
  final List<Widget> children;

  /// Fixed (non-scrolling) body below the header, used instead of [children].
  final Widget? body;
  final List<Widget> actions;
  final List<Color>? background;

  @override
  Widget build(BuildContext context) {
    final topBar = DeckItem(
      index: 0,
      child: Row(
        children: [
          const BackGlassButton(),
          const Spacer(),
          ...actions,
        ],
      ),
    );
    final colors = background ??
        [
          Color.lerp(AppTheme.bgTop, accent, 0.1)!,
          AppTheme.bgTop,
          const Color(0xFF09080D),
        ];

    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: AmbientBackground(
        colors: colors,
        accents: [accent, Color.lerp(accent, AppTheme.pink, 0.5)!],
        video: Cosmos.stars,
        videoOpacity: 0.6,
        child: SafeArea(
          bottom: false,
          child: body == null
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    topBar,
                    const SizedBox(height: 16),
                    header,
                    for (var i = 0; i < children.length; i++) ...[
                      const SizedBox(height: 14),
                      DeckItem(index: i + 1, child: children[i]),
                    ],
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      topBar,
                      const SizedBox(height: 16),
                      header,
                      Expanded(child: DeckItem(index: 1, child: body!)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Small caps section label between deck cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = AppTheme.textMuted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 6),
      child: Text(text, style: capsStyle(color: color, size: 10.5)),
    );
  }
}

/// A static (non-pressable) glass card for content panels.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.accent = AppTheme.violet,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CardFace(
      style: CardStyles.glass(accent),
      borderRadius: 24,
      elevation: 0.5,
      scrim: 0,
      padding: padding,
      child: child,
    );
  }
}
