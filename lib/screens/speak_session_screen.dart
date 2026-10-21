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
import '../widgets/cosmic_video.dart';
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
/// Contractions are expanded and numbers become digits, so "I'm making ten
/// thousand dollars" matches "I am making \$10,000".
List<String> spokenTokens(String text) => _digits(text
    .toLowerCase()
    .replaceAll('’', "'")
    .replaceAll(RegExp(r'(?<=\d),(?=\d)'), '')
    .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
    .split(RegExp(r'\s+'))
    .expand((w) => _contractions[w] ?? [w.replaceAll("'", '')])
    .where((w) => w.isNotEmpty)
    .toList());

const _contractions = {
  "i'm": ['i', 'am'],
  "i've": ['i', 'have'],
  "i'll": ['i', 'will'],
  "i'd": ['i', 'would'],
  "you're": ['you', 'are'],
  "you've": ['you', 'have'],
  "you'll": ['you', 'will'],
  "we're": ['we', 'are'],
  "we've": ['we', 'have'],
  "they're": ['they', 'are'],
  "it's": ['it', 'is'],
  "that's": ['that', 'is'],
  "don't": ['do', 'not'],
  "can't": ['can', 'not'],
  'cannot': ['can', 'not'],
  "won't": ['will', 'not'],
  "isn't": ['is', 'not'],
  "aren't": ['are', 'not'],
};

const _numberWords = {
  'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8,
  'nine': 9, 'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
  'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19, 'twenty': 20, 'thirty': 30,
  'forty': 40, 'fifty': 50, 'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
};
const _scales = {'thousand': 1000, 'million': 1000000, 'billion': 1000000000};

/// Folds spoken numbers ("ten thousand", "10 thousand", "10k") into digits.
List<String> _digits(List<String> words) {
  final out = <String>[];
  int? total; // finished thousands, millions…
  int? group; // the part below a thousand being built
  void flush() {
    if (total != null || group != null) out.add('${(total ?? 0) + (group ?? 0)}');
    total = null;
    group = null;
  }

  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    final k = RegExp(r'^(\d+)k$').firstMatch(w);
    final n = k != null ? int.parse(k[1]!) * 1000 : int.tryParse(w) ?? _numberWords[w];
    final g = group;
    if (n != null) {
      // Spelled "twenty five", "hundred five" and "thousand five" carry a
      // number on; "one two" (or "10000 50") is two numbers.
      final carries = _numberWords.containsKey(w) &&
          (g == null
              ? total != null && n < 1000
              : (g >= 100 && g % 100 == 0 && n < 100) || (g % 100 >= 20 && g % 10 == 0 && n < 10));
      if (!carries) flush();
      group = (carries ? group ?? 0 : 0) + n;
    } else if (w == 'hundred' && (g == null || g < 100)) {
      group = (g ?? 1) * 100;
    } else if (_scales[w] case final scale? when g != null || total == null) {
      total = (total ?? 0) + (g ?? 1) * scale;
      group = null;
    } else if (w == 'and' && g != null && i + 1 < words.length && _numberWords.containsKey(words[i + 1])) {
      continue; // "a hundred and five"
    } else {
      flush();
      out.add(w);
    }
  }
  flush();
  return out;
}

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
  bool _listening = false; // a session is open, or opening
  bool _live = false; // the microphone is actually open
  bool _holding = false; // hold-to-talk: letting go ends it
  bool _handsFree = true; // after each one, listen again by itself
  bool _pressStarted = false; // this press opened the session
  int _session = 0;
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
    _session++; // nothing from the last session reaches a disposed screen
    _speech.stop();
    _burst.dispose();
    _level.dispose();
    _typed.dispose();
    super.dispose();
  }

  /// Finger down: listen at once, or stop if already listening.
  void _micDown() {
    _pressStarted = false;
    if (_justDone) return; // the next one is on its way
    if (_listening) {
      _stopListening();
    } else {
      _pressStarted = _listen();
    }
  }

  /// Still pressing: hold to talk, and let go when you're done.
  void _micHold() {
    // Pressed during the "affirmed" moment: the next one starts held.
    if (_justDone) {
      setState(() => _holding = true);
      return;
    }
    if (!_pressStarted || !_listening) return;
    _speech.holdOpen();
    setState(() {
      _holding = true;
      _handsFree = false;
    });
  }

  /// Finger up: a tap keeps listening hands-free; a hold ends here.
  void _micUp() {
    final held = _holding;
    if (_pressStarted && !held) _handsFree = true;
    _pressStarted = false;
    if (!held) return;
    setState(() => _holding = false);
    if (_listening) _stopListening();
  }

  void _stopListening() {
    setState(() {
      _listening = false;
      _live = false;
    });
    _level.value = 0;
    _speech.stop();
  }

  /// Starts listening; [held] carries a hold-to-talk on into it.
  bool _listen({bool held = false}) {
    if (_finished || _available != true) return false;
    final session = ++_session;
    setState(() {
      _listening = true;
      _live = false;
      _heard = '';
      _hint = null;
      _justDone = false;
    });
    _speech.listen(
      onHeard: (h) {
        if (session == _session) _onHeard(h);
      },
      onLevel: (l) {
        if (session == _session) _level.value = l;
      },
      onLive: () {
        if (mounted && session == _session) setState(() => _live = true);
      },
      onDone: () {
        if (mounted && session == _session) _onEnded();
      },
    );
    if (held) {
      _pressStarted = true;
      _speech.holdOpen();
    }
    return true;
  }

  void _onEnded() {
    // Still marked listening: it ended by itself, not by your tap or release.
    final byItself = _listening;
    _level.value = 0;
    if (!_justDone && !_finished && !_affirm && spokenTokens(_heard).length >= 3) {
      // The pause is the end of the answer.
      _complete(spoken: _heard);
      return;
    }
    setState(() {
      _listening = false;
      _live = false;
      if (_justDone || _finished) return;
      if (_heard.isNotEmpty) {
        // Stopped short: say so, don't just reset.
        _hint = _affirm ? 'ALMOST — SAY IT ONCE MORE' : 'SAY A LITTLE MORE…';
      } else if (byItself) {
        _hint = "DIDN'T CATCH THAT — TRY AGAIN";
      }
    });
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
        setState(() => _hint = 'SAY A LITTLE MORE…');
      }
    }
  }

  void _complete({String? spoken}) {
    _session++; // whatever this session still says is past
    _speech.stop();
    _level.value = 0;
    HapticFeedback.heavyImpact();
    _burst.forward(from: 0);
    setState(() {
      _listening = false;
      _live = false;
      _hint = null;
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
      } else if (_available == true && (_handsFree || _holding)) {
        // Still holding: carry on listening for the next one.
        _listen(held: _holding);
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
      _handsFree = true;
    });
    if (_available == true) _listen();
  }

  String get _status {
    if (_available == null) return 'PREPARING THE MICROPHONE…';
    if (_available == false) {
      return _affirm ? 'SAY IT ALOUD, THEN CONFIRM' : 'SPEAK IT, OR TYPE IT BELOW';
    }
    if (_justDone) return _affirm ? 'AFFIRMED' : 'RECEIVED';
    if (_listening && !_live) return 'ONE MOMENT…';
    if (_listening && _holding) return 'LISTENING · LET GO WHEN DONE';
    if (_listening) return 'LISTENING…';
    return 'TAP OR HOLD THE MICROPHONE TO SPEAK';
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
        video: Cosmos.stars,
        videoOpacity: 0.6,
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
                      onPress: _micDown,
                      onHold: _micHold,
                      onRelease: _micUp,
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
                    fontFamily: 'InterDisplay',
                    fontWeight: FontWeight.w600,
                    fontSize: 25.5,
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
            fontFamily: 'InterDisplay',
            fontWeight: FontWeight.w600,
            fontSize: 24,
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
              fontFamily: 'InterDisplay',
              fontWeight: FontWeight.w500,
              fontSize: 17,
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
              style: const TextStyle(fontFamily: 'InterDisplay', fontSize: 15, color: AppTheme.ivory),
              decoration: InputDecoration(
                hintText: 'Or type it here…',
                hintStyle: TextStyle(
                    fontFamily: 'InterDisplay', fontSize: 14.5, color: AppTheme.textMuted.withValues(alpha: 0.7)),
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
