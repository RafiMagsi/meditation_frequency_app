import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/practice.dart';
import '../providers/providers.dart';
import '../services/practice_store.dart';
import '../services/voice.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/deck.dart';
import '../widgets/glass_button.dart';
import '../widgets/luxury.dart';
import '../widgets/voice_kit.dart';
import 'voice_screen.dart';

/// Spoken Affirmations and Gratitude Aloud: the app listens, and the
/// practice only moves on when you have actually said it.
class SpeakSessionScreen extends ConsumerStatefulWidget {
  const SpeakSessionScreen({super.key, required this.practice, required this.heroTag});

  final VoicePractice practice;
  final String heroTag;

  @override
  ConsumerState<SpeakSessionScreen> createState() => _SpeakSessionScreenState();
}

/// Lower-case words without punctuation, for matching speech to text.
List<String> spokenTokens(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
    .split(RegExp(r'\s+'))
    .map((w) => w.replaceAll("'", ''))
    .where((w) => w.isNotEmpty)
    .toList();

class _SpeakSessionScreenState extends ConsumerState<SpeakSessionScreen> with SingleTickerProviderStateMixin {
  static const _reps = 3;

  /// Share of an affirmation's words that must be heard (speech engines
  /// mishear the odd word; the intention is what counts).
  static const _enough = 0.75;
  static const _prompts = [
    'Something small that made you smile today.',
    'Someone you are grateful for — and why.',
    'Something about yourself you appreciate.',
  ];

  // Resolved up front: `ref` can't be used from dispose().
  late final SpeechInput _speech;
  final ValueNotifier<double> _level = ValueNotifier(0);
  // Created in initState (not lazily) so dispose never creates it.
  late final AnimationController _burst;
  final TextEditingController _typed = TextEditingController();

  late final List<String> _items = _affirm
      ? [ref.read(practiceProvider).focusIntention, ...ref.read(miracleAffirmationsProvider).take(2)]
      : _prompts;

  bool? _available;
  bool _listening = false;
  String _heard = '';
  String? _hint;
  int _index = 0;
  int _rep = 0;
  bool _justDone = false;
  bool _finished = false;
  final List<String> _answers = [];
  Timer? _next;

  bool get _affirm => widget.practice.kind == VoiceKind.affirm;
  Color get _color => widget.practice.color;

  @override
  void initState() {
    super.initState();
    _speech = ref.read(speechProvider);
    _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _speech.init().then((ok) {
      if (mounted) setState(() => _available = ok);
    });
  }

  @override
  void dispose() {
    _next?.cancel();
    _speech.stop();
    _burst.dispose();
    _level.dispose();
    _typed.dispose();
    super.dispose();
  }

  void _toggleListening() {
    if (_listening) {
      _speech.stop();
      setState(() => _listening = false);
      _level.value = 0;
    } else {
      _listen();
    }
  }

  void _listen() {
    if (_finished || _available != true) return;
    setState(() {
      _listening = true;
      _heard = '';
      _hint = null;
      _justDone = false;
    });
    _speech.listen(
      onHeard: _onHeard,
      onLevel: (l) => _level.value = l,
      onDone: () {
        if (!mounted) return;
        setState(() => _listening = false);
        _level.value = 0;
      },
    );
  }

  Set<int> _matched(String target, String heard) {
    final words = spokenTokens(target);
    final said = spokenTokens(heard).toSet();
    return {
      for (var i = 0; i < words.length; i++)
        if (said.contains(words[i])) i,
    };
  }

  void _onHeard(Heard h) {
    if (!mounted || _finished || _justDone) return;
    setState(() => _heard = h.words);
    if (_affirm) {
      final target = spokenTokens(_items[_index]);
      if (_matched(_items[_index], h.words).length >= (target.length * _enough).ceil()) _complete();
    } else if (h.done) {
      if (spokenTokens(h.words).length >= 3) {
        _complete(spoken: h.words);
      } else {
        setState(() => _hint = 'Say a little more…');
      }
    }
  }

  void _complete({String? spoken}) {
    _speech.stop();
    _level.value = 0;
    HapticFeedback.heavyImpact();
    _burst.forward(from: 0);
    setState(() {
      _listening = false;
      _justDone = true;
      if (_affirm) {
        _rep++;
      } else {
        _answers.add(spoken!.trim());
      }
    });
    // Let the moment land, then move on — hands-free while recognition works.
    _next = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _justDone = false;
        _heard = '';
        if (_affirm && _rep >= _reps) {
          _rep = 0;
          _index++;
        } else if (!_affirm) {
          _index++;
        }
      });
      if (_index >= _items.length) {
        _finish();
      } else if (_available == true) {
        _listen();
      }
    });
  }

  void _finish() {
    final store = ref.read(practiceProvider.notifier);
    if (!_affirm) store.addJournal('gratitude', _answers);
    store.recordPractice('voice');
    setState(() => _finished = true);
  }

  void _restart() {
    setState(() {
      _finished = false;
      _index = 0;
      _rep = 0;
      _answers.clear();
      _heard = '';
    });
    if (_available == true) _listen();
  }

  String get _status {
    if (_available == null) return 'PREPARING THE MICROPHONE…';
    if (_available == false) {
      return _affirm ? 'SAY IT ALOUD, THEN CONFIRM' : 'SPEAK IT, OR TYPE IT BELOW';
    }
    if (_justDone) return _affirm ? 'AFFIRMED' : 'RECEIVED';
    if (_listening) return 'LISTENING…';
    return 'TAP THE MICROPHONE AND SPEAK';
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.length;
    final shown = _index.clamp(0, total - 1);
    return Scaffold(
      backgroundColor: AppTheme.bgTop,
      body: AmbientBackground(
        colors: [Color.lerp(AppTheme.bgTop, _color, 0.12)!, AppTheme.bgTop, const Color(0xFF09080D)],
        accents: [_color, Color.lerp(_color, AppTheme.violet, 0.5)!],
        particleCount: 12,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                const DeckItem(index: 0, child: Row(children: [BackGlassButton(), Spacer()])),
                const SizedBox(height: 14),
                VoiceHeader(
                  practice: widget.practice,
                  heroTag: widget.heroTag,
                  trailing: _finished ? 'DONE' : '${shown + 1} / $total',
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _finished
                      ? VoiceCompletion(
                          key: const ValueKey('done'),
                          practice: widget.practice,
                          detail: _affirm
                              ? '$total affirmations · $_reps times each, out loud'
                              : '${_answers.length} thanks spoken into your journal',
                          onAgain: _restart,
                        )
                      : DeckItem(
                          key: ValueKey('item-$shown'),
                          index: 1,
                          child: _affirm ? _affirmation(_items[shown]) : _gratitude(_prompts[shown], shown),
                        ),
                ),
                const Spacer(),
                if (!_finished) ...[
                  Text(_hint ?? _status, style: capsStyle(color: Color.lerp(_color, Colors.white, 0.35)!, size: 10)),
                  const SizedBox(height: 6),
                  if (_available == false)
                    _fallback()
                  else
                    MicButton(
                      key: const Key('mic'),
                      listening: _listening,
                      level: _level,
                      color: _color,
                      onTap: _toggleListening,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Karaoke: each word lights as it is heard; all of it glows once affirmed.
  Widget _affirmation(String text) {
    final display = text.split(RegExp(r'\s+'));
    final heard = spokenTokens(_heard).toSet();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _reps; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i < _rep ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i < _rep ? _color : Colors.white.withValues(alpha: 0.18),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final word in display)
              Builder(builder: (context) {
                final tokens = spokenTokens(word);
                final lit = _justDone || (tokens.isNotEmpty && tokens.every(heard.contains));
                return AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 260),
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontWeight: FontWeight.w600,
                    fontSize: 32,
                    height: 1.15,
                    color: lit ? AppTheme.ivory : AppTheme.ivory.withValues(alpha: 0.32),
                    shadows: lit ? [Shadow(color: _color.withValues(alpha: 0.8), blurRadius: 18)] : const [],
                  ),
                  child: Text(word),
                );
              }),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: _burst,
          builder: (context, _) {
            final t = _burst.value;
            if (!_burst.isAnimating && !_justDone) return const SizedBox(height: 22);
            return Opacity(
              opacity: 1 - (t - 0.7).clamp(0.0, 0.3) / 0.3,
              child: Transform.scale(
                scale: 0.85 + 0.15 * Curves.easeOutBack.transform(t.clamp(0.0, 1.0)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 18, color: _color),
                    const SizedBox(width: 6),
                    Text(
                      'AFFIRMED · ${_rep.clamp(1, _reps)} OF $_reps',
                      style: capsStyle(color: Color.lerp(_color, Colors.white, 0.4)!, size: 10),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _gratitude(String prompt, int index) {
    return Column(
      children: [
        Text('PROMPT ${index + 1} OF ${_prompts.length}', style: capsStyle(color: AppTheme.textMuted, size: 10)),
        const SizedBox(height: 12),
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'CormorantGaramond',
            fontWeight: FontWeight.w600,
            fontSize: 30,
            height: 1.15,
            color: AppTheme.ivory,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _color.withValues(alpha: 0.06),
            border: Border.all(color: _color.withValues(alpha: _listening ? 0.6 : 0.2), width: 0.8),
          ),
          child: Text(
            _heard.isEmpty ? (_listening ? '…' : 'Your words will appear here.') : '“$_heard”',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w500,
              fontSize: 21,
              height: 1.25,
              color: _heard.isEmpty ? AppTheme.textMuted : AppTheme.ivory,
            ),
          ),
        ),
      ],
    );
  }

  /// When speech recognition isn't available, you can still complete it.
  Widget _fallback() {
    if (_affirm) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: ActionPill(
          key: const Key('said-it'),
          label: 'I said it aloud',
          icon: Icons.check_rounded,
          color: _color,
          onTap: _justDone ? () {} : _complete,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _typed,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: _color,
              style: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 19, color: AppTheme.ivory),
              decoration: InputDecoration(
                hintText: 'Or type it here…',
                hintStyle: TextStyle(
                    fontFamily: 'CormorantGaramond', fontSize: 18, color: AppTheme.textMuted.withValues(alpha: 0.7)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _color.withValues(alpha: 0.3))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _color)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ActionPill(
            label: 'Add',
            color: _color,
            onTap: () {
              if (_typed.text.trim().isEmpty || _justDone) return;
              final text = _typed.text;
              _typed.clear();
              FocusScope.of(context).unfocus();
              _complete(spoken: text);
            },
          ),
        ],
      ),
    );
  }
}
