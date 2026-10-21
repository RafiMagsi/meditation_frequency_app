import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meditation.dart';
import '../providers/providers.dart';
import '../services/practice_store.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/card_face.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/glow_card.dart';
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
        eyebrow: '6 SESSIONS · 1 INTERACTIVE',
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
    final tag = 'med-pick-${m.id}';
    return GlowCard(
      style: CardStyles.session(m.scene),
      heroTag: tag,
      height: 248,
      borderRadius: 28,
      semanticLabel: "Today's pick: ${m.title}",
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      onTap: () => pushSeamless(context, PlayerScreen.session(meditation: m, heroTag: tag)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: _Chip(icon: Icons.auto_awesome_rounded, text: "TODAY'S PICK · $when")),
              if (done) ...[const SizedBox(width: 8), const _Chip(icon: Icons.check_rounded, text: 'DONE')],
            ],
          ),
          const Spacer(),
          Text(m.category.toUpperCase(), style: capsStyle(color: Colors.white.withValues(alpha: 0.85), size: 10)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              m.title,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontWeight: FontWeight.w600,
                fontSize: 36,
                height: 1,
                color: Colors.white,
                shadows: textOnArt,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            m.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.85),
              shadows: textOnArt,
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
                      const SizedBox(width: 12),
                      _Meta(icon: Icons.graphic_eq_rounded, text: '${m.hz} Hz'),
                      const SizedBox(width: 12),
                      _Meta(icon: Icons.format_list_bulleted_rounded, text: '${m.chapters.length} chapters'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: m.color.withValues(alpha: 0.55), blurRadius: 20)],
                ),
                child: Icon(Icons.play_arrow_rounded, size: 28, color: Color.lerp(m.color, Colors.black, 0.65)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: capsStyle(color: Colors.white, size: 8.5),
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
    final c = color ?? Colors.white.withValues(alpha: 0.85);
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
            style: TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.w700, fontSize: 11.5, color: c),
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
                    color: c == selected ? Colors.white : Colors.white.withValues(alpha: 0.06),
                    border: Border.all(
                      color: c == selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c,
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: c == selected ? AppTheme.bgTop : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${counts[c] ?? 0}',
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: c == selected ? AppTheme.bgTop.withValues(alpha: 0.55) : AppTheme.textMuted,
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
    final tag = 'med-${m.id}';
    final accent = Color.lerp(m.color, Colors.white, 0.25)!;
    return GlowCard(
      style: CardStyles.glass(m.color),
      height: 132,
      borderRadius: 24,
      semanticLabel: m.title,
      padding: const EdgeInsets.all(12),
      contentAlignment: Alignment.centerLeft,
      onTap: () => pushSeamless(context, PlayerScreen.session(meditation: m, heroTag: tag)),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 104,
            child: CardHero(
              tag: tag,
              face: CardFace(
                style: CardStyles.session(m.scene),
                borderRadius: 18,
                elevation: 0.6,
                scrim: 0.45,
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '${m.minutes} MIN',
                    style: capsStyle(color: Colors.white, size: 8.5).copyWith(shadows: textOnArt),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${m.category.toUpperCase()} · ${m.hz} HZ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: capsStyle(color: accent, size: 9),
                ),
                const SizedBox(height: 5),
                Text(
                  m.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 23,
                    height: 1,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle.copyWith(fontSize: 11.5, height: 1.3),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    _Meta(
                      icon: Icons.format_list_bulleted_rounded,
                      text: '${m.chapters.length} chapters',
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: done
                          ? const _Meta(icon: Icons.check_circle_rounded, text: 'Completed', color: AppTheme.teal)
                          : _Meta(icon: Icons.signal_cellular_alt_rounded, text: m.level, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: m.color.withValues(alpha: 0.16),
              border: Border.all(color: accent.withValues(alpha: 0.6), width: 0.8),
            ),
            child: Icon(Icons.play_arrow_rounded, color: accent, size: 22),
          ),
        ],
      ),
    );
  }
}

/// The interactive meditation; its card becomes the whole lake.
class _InnerLakeCard extends StatelessWidget {
  const _InnerLakeCard();

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      style: CardStyles.innerLake,
      heroTag: 'lake-card',
      height: 150,
      borderRadius: 24,
      semanticLabel: 'Inner Lake',
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      onTap: () => pushSeamless(context, const InnerLakeScreen()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Chip(icon: Icons.touch_app_rounded, text: 'INTERACTIVE · HOLD TO BREATHE'),
          const Spacer(),
          const Text(
            'Inner Lake',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w600,
              fontSize: 28,
              height: 1,
              color: Colors.white,
              shadows: textOnArt,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Still the water with your breath. See to the bottom.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              shadows: textOnArt,
            ),
          ),
        ],
      ),
    );
  }
}
