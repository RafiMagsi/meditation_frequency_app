import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meditation.dart';
import '../providers/providers.dart';
import '../services/practice_store.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/glow_card.dart';
import '../widgets/medallion.dart';
import '../widgets/seamless_route.dart';
import 'inner_lake_screen.dart';
import 'player_screen.dart';

/// Guided meditations: today's pick, an interactive practice, then every
/// session as a rich row. Each session's artwork becomes the player's
/// jewel, and the player reads its script as timed captions.
class GuidedMeditationsScreen extends ConsumerStatefulWidget {
  const GuidedMeditationsScreen({super.key});

  @override
  ConsumerState<GuidedMeditationsScreen> createState() => _GuidedMeditationsScreenState();
}

class _GuidedMeditationsScreenState extends ConsumerState<GuidedMeditationsScreen> {
  String _category = meditationCategories.first;

  /// What a teacher would suggest at this hour.
  static ({String id, String when}) _pick(int hour) => hour < 11
      ? (id: 'morning-clarity', when: 'THIS MORNING')
      : hour < 15
          ? (id: 'focus-flow', when: 'THIS AFTERNOON')
          : hour < 19
              ? (id: 'anxiety-relief', when: 'THIS EVENING')
              : hour < 22
                  ? (id: 'deep-calm', when: 'TONIGHT')
                  : (id: 'night-drift', when: 'BEFORE SLEEP');

  @override
  Widget build(BuildContext context) {
    final meditations = ref.watch(meditationProvider);
    final completed = ref.watch(practiceProvider.select((s) => s.completed));
    final pick = _pick(DateTime.now().hour);
    final today = meditations.firstWhere((m) => m.id == pick.id, orElse: () => meditations.first);
    final shown = _category == 'All' ? meditations : meditations.where((m) => m.category == _category).toList();

    return FeatureScaffold(
      accent: AppTheme.teal,
      header: const FeatureHeader(
        heroTag: 'card-guided',
        style: CardStyles.guided,
        eyebrow: '7 SESSIONS',
        title: 'Guided Sessions',
        subtitle: 'Timed guidance on healing tones',
      ),
      children: [
        _CategoryChips(
          selected: _category,
          counts: {
            for (final c in meditationCategories)
              c: c == 'All' ? meditations.length : meditations.where((m) => m.category == c).length,
          },
          onSelect: (c) {
            HapticFeedback.selectionClick();
            setState(() => _category = c);
          },
        ),
        // "All" is the curated view; a category shows just its sessions.
        if (_category == 'All') ...[
          _TodaysPick(meditation: today, when: pick.when, done: completed.contains(today.id)),
          const _InnerLakeCard(),
          const SectionLabel('ALL SESSIONS'),
        ],
        for (final m in shown)
          _FadeIn(
            key: ValueKey('$_category-${m.id}'),
            child: _SessionRow(meditation: m, done: completed.contains(m.id)),
          ),
      ],
    );
  }
}

/// Fades and lifts a row in when the filter changes.
class _FadeIn extends StatelessWidget {
  const _FadeIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

class _TodaysPick extends StatelessWidget {
  const _TodaysPick({required this.meditation, required this.when, required this.done});

  final Meditation meditation;
  final String when;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final m = meditation;
    final style = CardStyles.session(m.scene);
    final metal = Color.lerp(style.glow, Colors.white, 0.3)!;
    final tag = 'med-pick-${m.id}';
    return GlowCard(
      style: style,
      height: 236,
      borderRadius: 26,
      semanticLabel: "Today's pick: ${m.title}",
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
      onTap: () => pushSeamless(context, PlayerScreen.session(meditation: m, heroTag: tag)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: _Chip(icon: Icons.auto_awesome_rounded, text: "TODAY'S PICK · $when", color: style.glow)),
              if (done) ...[
                const SizedBox(width: 8),
                _Chip(icon: Icons.check_rounded, text: 'DONE', color: style.glow),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(m.category.toUpperCase(), style: capsStyle(color: metal, size: 9.5)),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          m.title,
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: 'InterDisplay',
                            fontWeight: FontWeight.w600,
                            fontSize: 25.5,
                            height: 1,
                            color: AppTheme.ivory,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: mutedStyle.copyWith(fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Medallion(style: style, size: 108, heroTag: tag),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      _Meta(icon: Icons.schedule_rounded, text: '${m.minutes} min'),
                      const SizedBox(width: 14),
                      _Meta(icon: Icons.graphic_eq_rounded, text: '${m.hz} Hz'),
                      const SizedBox(width: 14),
                      _Meta(icon: Icons.format_list_bulleted_rounded, text: '${m.chapters.length} chapters'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _PlayButton(color: style.glow, size: 44),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hairline play circle in the card's metal, as on the money cards.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.color, this.size = 38});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Icon(Icons.play_arrow_rounded, color: Color.lerp(color, Colors.white, 0.45), size: size * 0.55),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final metal = Color.lerp(color, Colors.white, 0.35)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: metal),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: capsStyle(color: metal, size: 8.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 11.5, color: c),
          ),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.counts, required this.onSelect});

  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final c in meditationCategories) ...[
            Semantics(
              button: true,
              selected: c == selected,
              label: c,
              child: GestureDetector(
                onTap: () => onSelect(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: c == selected ? CardStyles.guided.glow.withValues(alpha: 0.14) : Colors.transparent,
                    border: Border.all(
                      color: c == selected
                          ? CardStyles.guided.glow.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.12),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: c == selected ? AppTheme.ivory : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${counts[c] ?? 0}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: c == selected
                              ? Color.lerp(CardStyles.guided.glow, Colors.white, 0.3)
                              : AppTheme.textMuted.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// A session as a rich row: artwork (the hero), category and tone, title,
/// a one-line promise, and length, chapters and level.
class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.meditation, required this.done});

  final Meditation meditation;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final m = meditation;
    final style = CardStyles.session(m.scene);
    final tag = 'med-${m.id}';
    final metal = Color.lerp(style.glow, Colors.white, 0.3)!;
    return GlowCard(
      style: CardStyles.glass(style.glow),
      height: 124,
      borderRadius: 24,
      semanticLabel: m.title,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      contentAlignment: Alignment.centerLeft,
      onTap: () => pushSeamless(context, PlayerScreen.session(meditation: m, heroTag: tag)),
      child: Row(
        children: [
          Medallion(style: style, size: 92, heroTag: tag),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${m.category.toUpperCase()} · ${m.minutes} MIN · ${m.hz} HZ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: capsStyle(color: metal, size: 8.5),
                ),
                const SizedBox(height: 6),
                Text(
                  m.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'InterDisplay',
                    fontWeight: FontWeight.w600,
                    fontSize: 18.5,
                    height: 1,
                    color: AppTheme.ivory,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  m.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle.copyWith(fontSize: 11.5, height: 1.3),
                ),
                if (done) ...[
                  const SizedBox(height: 5),
                  _Meta(icon: Icons.check_circle_rounded, text: 'Completed', color: metal),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PlayButton(color: style.glow),
        ],
      ),
    );
  }
}

/// The interactive meditation; its medallion opens into the whole lake.
class _InnerLakeCard extends StatelessWidget {
  const _InnerLakeCard();

  @override
  Widget build(BuildContext context) {
    const style = CardStyles.innerLake;
    final metal = Color.lerp(style.glow, Colors.white, 0.3)!;
    return GlowCard(
      style: style,
      height: 132,
      borderRadius: 24,
      semanticLabel: 'Inner Lake',
      padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
      contentAlignment: Alignment.centerLeft,
      onTap: () => pushSeamless(context, const InnerLakeScreen()),
      child: Row(
        children: [
          const Medallion(style: style, size: 100, heroTag: 'lake-card'),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Chip(icon: Icons.touch_app_rounded, text: 'INTERACTIVE', color: style.glow),
                const SizedBox(height: 10),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Inner Lake',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'InterDisplay',
                      fontWeight: FontWeight.w600,
                      fontSize: 21.5,
                      height: 1,
                      color: AppTheme.ivory,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Hold to breathe. Still the water, see to the bottom.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle.copyWith(fontSize: 11.5, height: 1.3, color: metal.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
