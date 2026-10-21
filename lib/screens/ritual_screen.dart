import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice.dart';
import '../services/practice_store.dart';
import '../theme/app_theme.dart';
import '../theme/card_styles.dart';
import '../widgets/ambient_background.dart';
import '../widgets/card_face.dart';
import '../widgets/deck.dart';
import '../widgets/glass_button.dart';

/// A guided daily ritual: one interactive card per step, dealt in from
/// the right. Finishing saves the journal and extends the streak.
class RitualScreen extends ConsumerStatefulWidget {
  const RitualScreen({super.key, required this.ritual});

  final Ritual ritual;

  @override
  ConsumerState<RitualScreen> createState() => _RitualScreenState();
}

class _RitualScreenState extends ConsumerState<RitualScreen> {
  int _step = 0;
  final Map<int, List<TextEditingController>> _fields = {};
  final Set<int> _ready = {};

  List<RitualStep> get _steps => widget.ritual.steps;
  bool get _complete => _step >= _steps.length;

  List<TextEditingController> _controllers(int index, int count) => _fields.putIfAbsent(
        index,
        () => List.generate(count, (_) => TextEditingController()..addListener(() => setState(() {}))),
      );

  bool _canContinue() {
    final step = _steps[_step];
    return switch (step) {
      BreatheStep() || IntentionStep() => true,
      JournalStep() => _controllers(_step, step.hints.length).any((c) => c.text.trim().isNotEmpty),
      _ => _ready.contains(_step),
    };
  }

  void _next() {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    if (_step == _steps.length - 1) {
      final store = ref.read(practiceProvider.notifier);
      for (var i = 0; i < _steps.length; i++) {
        final step = _steps[i];
        if (step is JournalStep) store.addJournal(step.kind, _controllers(i, step.hints.length).map((c) => c.text));
      }
      store.recordPractice('ritual');
      HapticFeedback.heavyImpact();
    }
    setState(() => _step++);
  }

  @override
  void dispose() {
    for (final list in _fields.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Widget _body(int index) {
    final step = _steps[index];
    final glow = widget.ritual.style.glow;
    void ready() {
      if (mounted) setState(() => _ready.add(index));
    }

    return switch (step) {
      BreatheStep() => _BreatheBody(seconds: step.seconds, glow: glow),
      JournalStep() => _JournalBody(hints: step.hints, controllers: _controllers(index, step.hints.length)),
      IntentionStep() => const _IntentionBody(),
      AffirmStep() => _AffirmBody(step: step, glow: glow, onDone: ready),
      VisualizeStep() => _VisualizeBody(step: step, glow: glow, onDone: ready),
      ReleaseStep() => _ReleaseBody(glow: glow, onDone: ready),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ritual = widget.ritual;
    final glow = ritual.style.glow;
    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: AmbientBackground(
        colors: [Color.lerp(AppTheme.bgTop, glow, 0.16)!, AppTheme.bgTop, const Color(0xFF0B0920)],
        accents: [glow, Color.lerp(glow, AppTheme.violet, 0.5)!],
        particleCount: 12,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                DeckItem(
                  index: 0,
                  child: Row(
                    children: [
                      const BackGlassButton(icon: Icons.close_rounded),
                      const Spacer(),
                      Text(
                        _complete ? 'COMPLETE' : 'STEP ${_step + 1} OF ${_steps.length}',
                        style: capsStyle(color: AppTheme.textPrimary.withValues(alpha: 0.8), size: 10.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 96,
                  child: CardHero(
                    tag: 'card-ritual',
                    face: CardFace(
                      style: ritual.style,
                      borderRadius: 26,
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      contentAlignment: Alignment.centerLeft,
                      child: _RitualHeader(ritual: ritual),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _Segments(count: _steps.length, current: _step, glow: glow),
                const SizedBox(height: 14),
                Expanded(
                  child: DeckItem(
                    index: 1,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 560),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        children: [...previous, if (current != null) current],
                      ),
                      // Step cards follow the deck motion: the old one leaves
                      // left, the new one is dealt in from the right.
                      transitionBuilder: (child, anim) {
                        final incoming = child.key == ValueKey(_step);
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(begin: Offset(incoming ? 0.6 : -0.6, 0), end: Offset.zero).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_step),
                        child: _complete
                            ? _CompletionCard(ritual: ritual, fields: _fields)
                            : _StepCard(
                                step: _steps[_step],
                                index: _step,
                                style: ritual.style,
                                child: _body(_step),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (!_complete)
                  Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Skip step',
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _ready.add(_step);
                            _next();
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text('Skip', style: mutedStyle.copyWith(fontSize: 14)),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _ContinueButton(
                        key: const Key('continue'),
                        label: _step == _steps.length - 1 ? 'Complete ritual' : 'Continue',
                        enabled: _canContinue(),
                        glow: glow,
                        onTap: _next,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RitualHeader extends ConsumerWidget {
  const _RitualHeader({required this.ritual});

  final Ritual ritual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(practiceProvider.select((s) => s.streak));
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(ritual.eyebrow, maxLines: 1, style: capsStyle(color: ritual.style.muted, size: 10)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  ritual.name,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 28,
                    height: 1,
                    color: ritual.style.foreground,
                    shadows: textOnArt,
                  ),
                ),
              ),
            ],
          ),
        ),
        StreakChip(days: streak),
      ],
    );
  }
}

/// 🔥 6 — the streak pill used on ritual cards.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, size: 14, color: AppTheme.amber),
          const SizedBox(width: 4),
          Text('$days', style: capsStyle(color: Colors.white, size: 11)),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.count, required this.current, required this.glow});

  final int count;
  final int current;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i < current
                    ? glow
                    : i == current
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.index, required this.style, required this.child});

  final RitualStep step;
  final int index;
  final CardStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CardFace(
      style: CardStyles.glass(style.glow),
      borderRadius: 28,
      elevation: 0.6,
      scrim: 0,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.title,
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontWeight: FontWeight.w600,
                fontSize: 34,
                height: 1,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(step.guidance, style: mutedStyle.copyWith(fontSize: 13.5, height: 1.45)),
            const SizedBox(height: 22),
            child,
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.glow,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final Color glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: enabled ? LinearGradient(colors: [Color.lerp(glow, Colors.white, 0.25)!, glow]) : null,
            color: enabled ? null : Colors.white.withValues(alpha: 0.08),
            boxShadow: enabled
                ? [BoxShadow(color: glow.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: enabled ? AppTheme.bgTop : AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 18, color: enabled ? AppTheme.bgTop : AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step bodies ─────────────────────────────────────────────────────────

/// A paced orb (5 s in, 5 s out) with a countdown.
class _BreatheBody extends StatefulWidget {
  const _BreatheBody({required this.seconds, required this.glow});

  final int seconds;
  final Color glow;

  @override
  State<_BreatheBody> createState() => _BreatheBodyState();
}

class _BreatheBodyState extends State<_BreatheBody> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);
  late int _left = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      setState(() => _left = math.max(0, _left - 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, _) {
          final b = Curves.easeInOut.transform(_breath.value);
          final inhaling = _breath.status == AnimationStatus.forward;
          return Column(
            children: [
              SizedBox.square(
                dimension: 190,
                child: Center(
                  child: Container(
                    width: 90 + 90 * b,
                    height: 90 + 90 * b,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.35),
                        colors: [Colors.white.withValues(alpha: 0.85), widget.glow, widget.glow.withValues(alpha: 0.5)],
                        stops: const [0, 0.45, 1],
                      ),
                      boxShadow: [BoxShadow(color: widget.glow.withValues(alpha: 0.5), blurRadius: 40 + 20 * b)],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _left == 0 ? 'Settled' : (inhaling ? 'Breathe in' : 'Breathe out'),
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontWeight: FontWeight.w500,
                  fontSize: 26,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '0:${_left.toString().padLeft(2, '0')}',
                style: capsStyle(size: 12).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JournalBody extends StatelessWidget {
  const _JournalBody({required this.hints, required this.controllers});

  final List<String> hints;
  final List<TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    final filled = controllers.where((c) => c.text.trim().isNotEmpty).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < hints.length; i++) ...[
          _GlassField(
            controller: controllers[i],
            hint: hints[i],
            number: hints.length > 1 ? i + 1 : null,
          ),
          const SizedBox(height: 12),
        ],
        if (hints.length > 1) Text('$filled of ${hints.length}', style: capsStyle(color: AppTheme.textMuted, size: 10)),
      ],
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({required this.controller, required this.hint, this.number, this.maxLines = 2});

  final TextEditingController controller;
  final String hint;
  final int? number;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          if (number != null) ...[
            Text('$number', style: capsStyle(color: AppTheme.gold, size: 12)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: maxLines,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: AppTheme.gold,
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontWeight: FontWeight.w500,
                fontSize: 20,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 19,
                  color: AppTheme.textMuted.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pick the intention to focus on and sharpen its wording.
class _IntentionBody extends ConsumerWidget {
  const _IntentionBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceProvider);
    final store = ref.read(practiceProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < state.intentions.length; i++) ...[
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              store.focusOn(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: i == state.focus ? AppTheme.gold.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: i == state.focus ? AppTheme.gold.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    i == state.focus ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    size: 18,
                    color: i == state.focus ? AppTheme.gold : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: state.intentions[i],
                      onChanged: (v) => store.setIntention(i, v),
                      onTap: () => store.focusOn(i),
                      minLines: 1,
                      maxLines: 3,
                      cursorColor: AppTheme.gold,
                      style: const TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        height: 1.2,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: () => store.setIntention(state.intentions.length, 'I am '),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.add_rounded, size: 18, color: AppTheme.gold),
                const SizedBox(width: 6),
                Text('ADD INTENTION', style: capsStyle(color: AppTheme.gold, size: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Speak it in the present tense, as already true — "I am", not "I want".',
          style: mutedStyle.copyWith(fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

/// Tap to affirm each statement out loud; a ring counts the repetitions.
class _AffirmBody extends ConsumerStatefulWidget {
  const _AffirmBody({required this.step, required this.glow, required this.onDone});

  final AffirmStep step;
  final Color glow;
  final VoidCallback onDone;

  @override
  ConsumerState<_AffirmBody> createState() => _AffirmBodyState();
}

class _AffirmBodyState extends ConsumerState<_AffirmBody> with SingleTickerProviderStateMixin {
  int _index = 0;
  int _count = 0;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  bool get _finished => _index >= widget.step.affirmations.length;

  void _affirm() {
    if (_finished) return;
    HapticFeedback.mediumImpact();
    _pulse.forward(from: 0);
    setState(() => _count++);
    if (_count >= widget.step.reps) {
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        setState(() {
          _index++;
          _count = 0;
        });
        if (_finished) widget.onDone();
      });
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intention = ref.watch(practiceProvider.select((s) => s.focusIntention));
    final list = [for (final a in widget.step.affirmations) a ?? intention];
    final text = _finished ? 'Affirmed. Feel it as done.' : list[_index];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < list.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _index ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i < _index ? widget.glow : (i == _index ? Colors.white : Colors.white.withValues(alpha: 0.18)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 96,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Center(
              key: ValueKey(text),
              child: Text(
                '“$text”',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontWeight: FontWeight.w600,
                  fontSize: 25,
                  height: 1.2,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Semantics(
          button: true,
          label: 'Affirm',
          child: GestureDetector(
            key: const Key('affirm'),
            onTap: _affirm,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final p = Curves.easeOut.transform(_pulse.value);
                return SizedBox.square(
                  dimension: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple on each affirmation.
                      if (_pulse.isAnimating)
                        Container(
                          width: 110 + 60 * p,
                          height: 110 + 60 * p,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: widget.glow.withValues(alpha: 0.6 * (1 - p)), width: 2),
                          ),
                        ),
                      SizedBox.square(
                        dimension: 118,
                        child: CircularProgressIndicator(
                          value: _finished ? 1 : _count / widget.step.reps,
                          strokeWidth: 3,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(widget.glow),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.glow.withValues(alpha: 0.5 + 0.3 * (1 - p)),
                              widget.glow.withValues(alpha: 0.12)
                            ],
                          ),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_finished ? Icons.check_rounded : Icons.auto_awesome_rounded,
                                color: Colors.white, size: 26),
                            const SizedBox(height: 4),
                            Text(
                              _finished ? 'DONE' : '$_count / ${widget.step.reps}',
                              style: capsStyle(color: Colors.white, size: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(_finished ? '' : 'Say it aloud, then tap', style: mutedStyle.copyWith(fontSize: 12)),
      ],
    );
  }
}

/// Five senses, one at a time, each on a countdown ring.
class _VisualizeBody extends ConsumerStatefulWidget {
  const _VisualizeBody({required this.step, required this.glow, required this.onDone});

  final VisualizeStep step;
  final Color glow;
  final VoidCallback onDone;

  @override
  ConsumerState<_VisualizeBody> createState() => _VisualizeBodyState();
}

class _VisualizeBodyState extends ConsumerState<_VisualizeBody> with SingleTickerProviderStateMixin {
  static const _icons = {
    'See': Icons.visibility_rounded,
    'Hear': Icons.hearing_rounded,
    'Feel': Icons.favorite_rounded,
    'Smell': Icons.local_florist_rounded,
    'Taste': Icons.local_cafe_rounded,
  };

  int _index = 0;
  late final AnimationController _timer = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.step.secondsEach),
  )
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _advance();
    })
    ..forward();

  bool get _finished => _index >= widget.step.senses.length;

  void _advance() {
    if (_finished) return;
    HapticFeedback.lightImpact();
    setState(() => _index++);
    if (_finished) {
      widget.onDone();
    } else {
      _timer.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intention = ref.watch(practiceProvider.select((s) => s.focusIntention));
    final senses = widget.step.senses;
    final sense = _finished ? null : senses[_index];
    return Column(
      children: [
        Text(
          '“$intention”',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontWeight: FontWeight.w500,
            fontSize: 17,
            color: AppTheme.gold.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: _timer,
          builder: (context, _) => SizedBox.square(
            dimension: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: 140,
                  child: CircularProgressIndicator(
                    value: _finished ? 1 : 1 - _timer.value,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(widget.glow),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  child: Column(
                    key: ValueKey(_index),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sense == null ? Icons.check_rounded : _icons[sense.sense], color: Colors.white, size: 30),
                      const SizedBox(height: 6),
                      Text(
                        sense?.sense ?? 'Done',
                        style: const TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontWeight: FontWeight.w600,
                          fontSize: 30,
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                      if (sense != null)
                        Text(
                          '${(widget.step.secondsEach * (1 - _timer.value)).ceil()}s',
                          style: capsStyle(color: AppTheme.textMuted, size: 10),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 64,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: Text(
              sense?.prompt ?? 'Hold the feeling. It is already done.',
              key: ValueKey(_index),
              textAlign: TextAlign.center,
              style:
                  mutedStyle.copyWith(fontSize: 14, height: 1.45, color: AppTheme.textPrimary.withValues(alpha: 0.88)),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < senses.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _index ? widget.glow : (i == _index ? Colors.white : Colors.white.withValues(alpha: 0.18)),
                ),
              ),
          ],
        ),
        if (!_finished) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _advance,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text('NEXT SENSE', style: capsStyle(color: AppTheme.textMuted, size: 10)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Write the doubt, then watch it blur, rise and dissolve.
class _ReleaseBody extends StatefulWidget {
  const _ReleaseBody({required this.glow, required this.onDone});

  final Color glow;
  final VoidCallback onDone;

  @override
  State<_ReleaseBody> createState() => _ReleaseBodyState();
}

class _ReleaseBodyState extends State<_ReleaseBody> with SingleTickerProviderStateMixin {
  final _text = TextEditingController();
  late final AnimationController _dissolve = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _dissolve.dispose();
    super.dispose();
  }

  void _release() {
    FocusScope.of(context).unfocus();
    HapticFeedback.heavyImpact();
    _dissolve.forward();
  }

  @override
  Widget build(BuildContext context) {
    final started = _dissolve.value > 0 || _dissolve.isAnimating;
    return AnimatedBuilder(
      animation: _dissolve,
      builder: (context, _) {
        final t = Curves.easeIn.transform(_dissolve.value);
        if (!started) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GlassField(controller: _text, hint: 'I am afraid that…', maxLines: 3),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: _ContinueButton(
                  key: const Key('release'),
                  label: 'Let it go',
                  enabled: _text.text.trim().isNotEmpty,
                  glow: widget.glow,
                  onTap: _release,
                ),
              ),
            ],
          );
        }
        return SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: CustomPaint(painter: _EmbersPainter(t: _dissolve.value, glow: widget.glow))),
              Transform.translate(
                offset: Offset(0, -70 * t),
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 14 * t),
                    child: Text(
                      _text.text.trim(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontWeight: FontWeight.w600,
                        fontSize: 26,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              if (_dissolve.value > 0.75)
                Opacity(
                  opacity: ((_dissolve.value - 0.75) / 0.25).clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.air_rounded, color: widget.glow, size: 30),
                      const SizedBox(height: 8),
                      const Text(
                        'Released. Forgiven. Gone.',
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontWeight: FontWeight.w600,
                          fontSize: 26,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Sparks rising from the dissolving words.
class _EmbersPainter extends CustomPainter {
  const _EmbersPainter({required this.t, required this.glow});

  final double t;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(17);
    final paint = Paint();
    for (var i = 0; i < 46; i++) {
      final x = size.width * (0.15 + 0.7 * rng.nextDouble());
      final start = size.height * (0.4 + 0.2 * rng.nextDouble());
      final rise = size.height * (0.3 + 0.6 * rng.nextDouble());
      final delay = rng.nextDouble() * 0.4;
      final local = ((t - delay) / 0.6).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final y = start - rise * Curves.easeOut.transform(local);
      final drift = 18 * math.sin(local * math.pi * 2 + i);
      paint.color =
          Color.lerp(glow, Colors.white, rng.nextDouble())!.withValues(alpha: math.sin(math.pi * local) * 0.9);
      canvas.drawCircle(Offset(x + drift, y), 1 + 2 * rng.nextDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(_EmbersPainter old) => old.t != t;
}

/// The finish: streak, the intention and a line to carry into the day.
class _CompletionCard extends ConsumerWidget {
  const _CompletionCard({required this.ritual, required this.fields});

  final Ritual ritual;
  final Map<int, List<TextEditingController>> fields;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceProvider);
    String? answer(String kind) {
      for (var i = 0; i < ritual.steps.length; i++) {
        final step = ritual.steps[i];
        if (step is JournalStep && step.kind == kind) {
          for (final c in fields[i] ?? const <TextEditingController>[]) {
            if (c.text.trim().isNotEmpty) return c.text.trim();
          }
        }
      }
      return null;
    }

    final rows = [
      ('INTENTION', state.focusIntention),
      if (answer('gratitude') case final g?) ('GRATEFUL FOR', g),
      if (answer('action') case final a?) ('TODAY I WILL', a),
      if (answer('reflection') case final r?) ('TODAY', r),
    ];
    return CardFace(
      style: ritual.style,
      borderRadius: 28,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: AppTheme.amber, size: 20),
                const SizedBox(width: 6),
                Text('DAY ${state.streak}', style: capsStyle(color: Colors.white, size: 11)),
                const Spacer(),
                Text('${state.rituals} RITUALS',
                    style: capsStyle(color: Colors.white.withValues(alpha: 0.75), size: 10)),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Ritual complete.',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontWeight: FontWeight.w600,
                fontSize: 38,
                height: 1,
                color: Colors.white,
                shadows: textOnArt,
              ),
            ),
            const SizedBox(height: 18),
            for (final (label, text) in rows) ...[
              Text(label, style: capsStyle(color: Colors.white.withValues(alpha: 0.7), size: 9.5)),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontWeight: FontWeight.w600,
                  fontSize: 21,
                  height: 1.2,
                  color: Colors.white,
                  shadows: textOnArt,
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              "You don't chase miracles. You become one.",
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
                shadows: textOnArt,
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: 'Done',
              child: GestureDetector(
                key: const Key('done'),
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), color: Colors.white),
                  child: Text(
                    'Carry it into the day',
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: ritual.style.colors.first,
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
