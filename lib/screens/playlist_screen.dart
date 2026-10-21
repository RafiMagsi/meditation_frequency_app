import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/card_face.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/luxury.dart';
import '../widgets/medallion.dart';

/// Playlists: each flow is a card with its session's artwork as cover.
class PlaylistScreen extends ConsumerStatefulWidget {
  const PlaylistScreen({super.key});

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  /// Rows present on open are dealt in by the deck; later ones fade in.
  late final int _initialCount = ref.read(playlistProvider).length;

  void _addFlow(List<String> playlist) {
    HapticFeedback.lightImpact();
    var n = 1;
    var name = 'New Flow';
    while (playlist.contains(name)) {
      name = 'New Flow ${++n}';
    }
    ref.read(playlistProvider.notifier).add(name);
  }

  @override
  Widget build(BuildContext context) {
    final playlist = ref.watch(playlistProvider);
    final sessions = {for (final m in ref.watch(meditationProvider)) m.title: m};
    return FeatureScaffold(
      accent: AppTheme.pink,
      header: FeatureHeader(
        heroTag: 'card-playlists',
        style: CardStyles.playlists,
        eyebrow: '${playlist.length} FLOWS',
        title: 'Your Playlists',
        subtitle: 'Flows for every moment',
      ),
      children: [
        for (var i = 0; i < playlist.length; i++)
          _AppearOnce(
            key: ValueKey(playlist[i]),
            animate: i >= _initialCount,
            child: _PlaylistRow(
              title: playlist[i],
              scene: sessions[playlist[i]]?.scene,
              minutes: sessions[playlist[i]]?.minutes,
              onRemove: () => ref.read(playlistProvider.notifier).remove(playlist[i]),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: ActionPill(
            label: 'Add flow',
            icon: Icons.add_rounded,
            color: CardStyles.playlists.glow,
            onTap: () => _addFlow(playlist),
          ),
        ),
      ],
    );
  }
}

class _AppearOnce extends StatelessWidget {
  const _AppearOnce({super.key, required this.animate, required this.child});

  final bool animate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(60 * (1 - t), 0), child: child),
      ),
      child: child,
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({
    required this.title,
    required this.onRemove,
    this.scene,
    this.minutes,
  });

  final String title;
  final Scene? scene;
  final int? minutes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cover = scene == null ? CardStyles.playlists : CardStyles.session(scene!);
    return CardFace(
      style: CardStyles.glass(cover.glow),
      borderRadius: 22,
      elevation: 0.5,
      scrim: 0,
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      child: Row(
        children: [
          Medallion(style: cover, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'InterDisplay',
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    height: 1.05,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  minutes == null ? 'Custom flow · tap to build' : '$minutes min · guided session',
                  style: mutedStyle.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Remove $title',
            child: GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, color: AppTheme.textMuted.withValues(alpha: 0.8), size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
