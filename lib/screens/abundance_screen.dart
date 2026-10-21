import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/money_frequency.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/card_face.dart';
import '../widgets/feature_scaffold.dart';
import '../widgets/glow_card.dart';
import '../widgets/luxury.dart';
import '../widgets/seamless_route.dart';
import 'money_player_screen.dart';

/// Money manifestation: the black card opens into today's intention,
/// the wealth frequencies and a short manifestation ritual.
class AbundanceScreen extends ConsumerWidget {
  const AbundanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tones = ref.watch(moneyFrequencyProvider);
    final affirmation = ref.watch(affirmationsProvider).first;
    return FeatureScaffold(
      accent: AppTheme.goldMid,
      background: const [Color(0xFF15110A), AppTheme.onyx, Color(0xFF0B0A08)],
      header: const FeatureHeader(
        heroTag: 'card-abundance',
        style: CardStyles.abundance,
        title: 'Abundance',
        subtitle: 'Money manifestation',
        height: 206,
        child: _BlackCardFace(),
      ),
      children: [
        _IntentionCard(affirmation: affirmation),
        const SectionLabel('WEALTH FREQUENCIES · HEADPHONES ON', color: AppTheme.taupe),
        for (final tone in tones) _MoneyToneCard(frequency: tone),
        const _RitualCard(),
      ],
    );
  }
}

class _BlackCardFace extends StatelessWidget {
  const _BlackCardFace();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const GoldChip(width: 44),
            const SizedBox(width: 14),
            Icon(Icons.contactless_outlined, color: AppTheme.goldMid.withValues(alpha: 0.8), size: 24),
            const Spacer(),
            GoldText('PRIVATE', style: capsStyle(size: 10)),
          ],
        ),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: GoldText(
            '8888  8888  8888  0888',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: 2.2,
              shadows: [
                Shadow(color: Colors.black.withValues(alpha: 0.6), offset: const Offset(0, 1.5), blurRadius: 2)
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: GoldText(
                  'Abundance',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 36,
                    height: 1,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('MEMBER SINCE', style: capsStyle(color: AppTheme.taupe, size: 8)),
                const SizedBox(height: 3),
                Text('TODAY', style: capsStyle(color: AppTheme.ivory, size: 10)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _IntentionCard extends StatelessWidget {
  const _IntentionCard({required this.affirmation});

  final String affirmation;

  @override
  Widget build(BuildContext context) {
    return CardFace(
      style: CardStyles.onyx,
      borderRadius: 24,
      elevation: 0.6,
      scrim: 0,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 15, color: AppTheme.goldMid),
              const SizedBox(width: 8),
              Text("TODAY'S INTENTION", style: capsStyle(color: AppTheme.taupe, size: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '“$affirmation”',
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w500,
              fontSize: 26,
              height: 1.15,
              color: AppTheme.ivory,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Say it three times, slowly — feel it as already true.',
            style: mutedStyle.copyWith(fontSize: 12, color: AppTheme.taupe),
          ),
        ],
      ),
    );
  }
}

class _MoneyToneCard extends StatelessWidget {
  const _MoneyToneCard({required this.frequency});

  final MoneyFrequency frequency;

  @override
  Widget build(BuildContext context) {
    final f = frequency;
    return GlowCard(
      style: CardStyles.money,
      borderRadius: 22,
      height: 98,
      semanticLabel: '${f.hz} Hz ${f.name}',
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      contentAlignment: Alignment.centerLeft,
      onTap: () => pushSeamless(context, MoneyPlayerScreen(frequency: f)),
      child: Row(
        children: [
          Hero(tag: 'coin-${f.hz}', child: GoldCoin(size: 62, emblem: f.emblem)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GoldText(
                  '${f.hz} Hz',
                  style: const TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  f.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.ivory,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  f.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mutedStyle.copyWith(fontSize: 11, color: AppTheme.taupe),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.goldMid.withValues(alpha: 0.6), width: 0.8),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: AppTheme.champagne, size: 20),
              ),
              const SizedBox(height: 6),
              Text('${f.minutes} MIN', style: capsStyle(color: AppTheme.taupe, size: 8.5)),
            ],
          ),
        ],
      ),
    );
  }
}

/// A short manifestation ritual to pair with the tones.
class _RitualCard extends StatelessWidget {
  const _RitualCard();

  static const _steps = [
    ('Gratitude', 'Name three things you already have and love.'),
    ('Visualise', 'See the exact number in your account. Feel it as done.'),
    ('Receive', 'Breathe in for five, out for five. Whisper: thank you.'),
  ];

  @override
  Widget build(BuildContext context) {
    return CardFace(
      style: CardStyles.onyx,
      borderRadius: 24,
      elevation: 0.6,
      scrim: 0,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THE THREE-STEP RITUAL', style: capsStyle(color: AppTheme.taupe, size: 10)),
          const SizedBox(height: 14),
          for (var i = 0; i < _steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.goldMid.withValues(alpha: 0.7), width: 0.8),
                  ),
                  child: GoldText(
                    '${i + 1}',
                    style: const TextStyle(fontFamily: 'CormorantGaramond', fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _steps[i].$1,
                        style: const TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontWeight: FontWeight.w600,
                          fontSize: 19,
                          color: AppTheme.ivory,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(_steps[i].$2, style: mutedStyle.copyWith(fontSize: 12, color: AppTheme.taupe, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
            if (i < _steps.length - 1) const SizedBox(height: 14),
          ],
          const SizedBox(height: 16),
          Text(
            'Best at sunrise or just before sleep, when the mind is most receptive.',
            style: mutedStyle.copyWith(fontSize: 11.5, color: AppTheme.goldMid.withValues(alpha: 0.85), height: 1.35),
          ),
        ],
      ),
    );
  }
}
