import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice.dart';
import '../providers/providers.dart';
import '../services/practice_store.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/card_face.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/glow_card.dart';
import '../widgets/luxury.dart';
import '../widgets/medallion.dart';
import '../widgets/seamless_route.dart';
import 'chant_session_screen.dart';
import 'speak_session_screen.dart';

/// Voice: practices you complete by speaking — the app listens.
class VoiceScreen extends ConsumerWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practices = ref.watch(voicePracticesProvider);
    return FeatureScaffold(
      accent: CardStyles.voice.glow,
      header: const FeatureHeader(
        heroTag: 'card-voice',
        style: CardStyles.voice,
        eyebrow: '4 SPEAKING PRACTICES',
        title: 'Voice',
        subtitle: 'Practices you complete by speaking',
      ),
      children: [
        for (final p in practices) _VoiceCard(practice: p),
        GlassPanel(
          accent: CardStyles.voice.glow,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: CardStyles.voice.glow),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The app listens only while a practice is open. Chanting is measured on your phone and never '
                  'recorded; spoken words are only kept when you say them into your gratitude journal.',
                  style: mutedStyle.copyWith(fontSize: 12, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VoiceCard extends StatelessWidget {
  const _VoiceCard({required this.practice});

  final VoicePractice practice;

  @override
  Widget build(BuildContext context) {
    final p = practice;
    final style = CardStyles.breathPattern(p.color);
    final metal = Color.lerp(p.color, Colors.white, 0.3)!;
    final tag = 'voice-${p.id}';
    final listens = p.kind == VoiceKind.affirm || p.kind == VoiceKind.gratitude ? 'SPEAK' : 'CHANT';
    return GlowCard(
      style: style,
      heroTag: tag,
      height: 124,
      semanticLabel: p.name,
      padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
      contentAlignment: Alignment.centerLeft,
      onTap: () => pushSeamless(
        context,
        p.kind == VoiceKind.affirm || p.kind == VoiceKind.gratitude
            ? SpeakSessionScreen(practice: p, heroTag: tag)
            : ChantSessionScreen(practice: p, heroTag: tag),
      ),
      child: Row(
        children: [
          EmblemMedallion(color: p.color, icon: p.icon, text: p.emblem, size: 76),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$listens · ${p.minutes} MIN', style: capsStyle(color: metal, size: 9)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    p.name,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'InterDisplay',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      height: 1,
                      color: AppTheme.ivory,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  p.benefit,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle.copyWith(fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.color.withValues(alpha: 0.1),
              border: Border.all(color: p.color.withValues(alpha: 0.6), width: 0.8),
            ),
            child: Icon(Icons.mic_rounded, color: metal, size: 18),
          ),
        ],
      ),
    );
  }
}

/// The compact header a voice card morphs into.
class VoiceHeader extends StatelessWidget {
  const VoiceHeader({super.key, required this.practice, required this.heroTag, required this.trailing});

  final VoicePractice practice;
  final String heroTag;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final p = practice;
    return SizedBox(
      width: double.infinity,
      height: 88,
      child: CardHero(
        tag: heroTag,
        face: CardFace(
          style: CardStyles.breathPattern(p.color),
          borderRadius: 24,
          padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
          contentAlignment: Alignment.centerLeft,
          child: Row(
            children: [
              EmblemMedallion(color: p.color, icon: p.icon, text: p.emblem, size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    p.name,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'InterDisplay',
                      fontWeight: FontWeight.w600,
                      fontSize: 21,
                      height: 1,
                      color: AppTheme.ivory,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(trailing, style: capsStyle(color: Color.lerp(p.color, Colors.white, 0.3)!, size: 9.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The finish of a voice practice: what you did, the streak, and again.
class VoiceCompletion extends ConsumerWidget {
  const VoiceCompletion({super.key, required this.practice, required this.detail, required this.onAgain});

  final VoicePractice practice;
  final String detail;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = practice;
    final streak = ref.watch(practiceProvider.select((s) => s.streak));
    return CardFace(
      style: CardStyles.breathPattern(p.color),
      borderRadius: 26,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmblemMedallion(color: p.color, icon: p.icon, text: p.emblem, size: 72),
          const SizedBox(height: 14),
          const Text(
            'Beautifully done.',
            style: TextStyle(
              fontFamily: 'InterDisplay',
              fontWeight: FontWeight.w600,
              fontSize: 24,
              height: 1,
              color: AppTheme.ivory,
            ),
          ),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center, style: mutedStyle.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          Text('DAY $streak STREAK', style: capsStyle(color: Color.lerp(p.color, Colors.white, 0.35)!, size: 9.5)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ActionPill(
                    label: 'Again', icon: Icons.replay_rounded, color: p.color, expand: true, onTap: onAgain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionPill(
                  key: const Key('voice-done'),
                  label: 'Done',
                  icon: Icons.check_rounded,
                  color: p.color,
                  expand: true,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
