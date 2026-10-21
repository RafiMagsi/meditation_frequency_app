import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

String dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

@immutable
class JournalEntry {
  const JournalEntry({required this.day, required this.kind, required this.text});

  final String day;

  /// 'gratitude', 'action', 'reflection' …
  final String kind;
  final String text;

  Map<String, dynamic> toJson() => {'day': day, 'kind': kind, 'text': text};

  static JournalEntry fromJson(Map<String, dynamic> j) =>
      JournalEntry(day: j['day'] as String, kind: j['kind'] as String, text: j['text'] as String);
}

/// Everything the practice remembers between launches: intentions, the
/// daily streak, totals and the journal.
@immutable
class PracticeState {
  const PracticeState({
    required this.intentions,
    required this.focus,
    required this.streak,
    required this.lastDay,
    required this.rituals,
    required this.breathSeconds,
    required this.stillness,
    required this.journal,
    this.completed = const [],
  });

  final List<String> intentions;
  final int focus;
  final int streak;
  final String? lastDay;
  final int rituals;
  final int breathSeconds;
  final int stillness;
  final List<JournalEntry> journal;

  /// Ids of guided sessions finished at least once.
  final List<String> completed;

  String get focusIntention =>
      intentions.isEmpty ? 'I am open to everything good.' : intentions[focus.clamp(0, intentions.length - 1)];

  bool get practisedToday => lastDay == dayKey(DateTime.now());

  /// First-launch profile: a lived-in demo history, seeded with the
  /// owner's own manifestations from docs/manifestation.md.
  factory PracticeState.seed() => PracticeState(
        intentions: const [
          r'I am making $10,000 a month with app development.',
          'My family is healthy and happy.',
        ],
        focus: 0,
        streak: 6,
        lastDay: dayKey(DateTime.now().subtract(const Duration(days: 1))),
        rituals: 11,
        breathSeconds: 41 * 60,
        stillness: 3,
        journal: const [],
      );

  PracticeState copyWith({
    List<String>? intentions,
    int? focus,
    int? streak,
    String? lastDay,
    int? rituals,
    int? breathSeconds,
    int? stillness,
    List<JournalEntry>? journal,
    List<String>? completed,
  }) =>
      PracticeState(
        intentions: intentions ?? this.intentions,
        focus: focus ?? this.focus,
        streak: streak ?? this.streak,
        lastDay: lastDay ?? this.lastDay,
        rituals: rituals ?? this.rituals,
        breathSeconds: breathSeconds ?? this.breathSeconds,
        stillness: stillness ?? this.stillness,
        journal: journal ?? this.journal,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toJson() => {
        'intentions': intentions,
        'focus': focus,
        'streak': streak,
        'lastDay': lastDay,
        'rituals': rituals,
        'breathSeconds': breathSeconds,
        'stillness': stillness,
        'journal': [for (final e in journal) e.toJson()],
        'completed': completed,
      };

  static PracticeState fromJson(Map<String, dynamic> j) => PracticeState(
        intentions: [for (final i in j['intentions'] as List) i as String],
        focus: j['focus'] as int,
        streak: j['streak'] as int,
        lastDay: j['lastDay'] as String?,
        rituals: j['rituals'] as int,
        breathSeconds: j['breathSeconds'] as int,
        stillness: j['stillness'] as int,
        journal: [for (final e in j['journal'] as List) JournalEntry.fromJson(e as Map<String, dynamic>)],
        completed: [for (final c in (j['completed'] as List?) ?? const []) c as String],
      );
}

class PracticeNotifier extends StateNotifier<PracticeState> {
  PracticeNotifier() : super(PracticeState.seed()) {
    _load();
  }

  static const _key = 'practice.v1';

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null && mounted) {
        state = PracticeState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      // Unreadable or missing storage: keep the seed.
    }
  }

  Future<void> _save() async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(state.toJson()));
    } catch (_) {
      // Storage unavailable (e.g. tests); the session still works.
    }
  }

  void setIntention(int index, String text) {
    final list = [...state.intentions];
    if (index < list.length) {
      list[index] = text;
    } else {
      list.add(text);
    }
    state = state.copyWith(intentions: list);
    _save();
  }

  void focusOn(int index) {
    state = state.copyWith(focus: index);
    _save();
  }

  /// Logs a finished practice and keeps the daily streak honest: the
  /// first practice of a day extends a streak from yesterday, or starts
  /// a new one after a gap.
  void recordPractice(String kind, {int seconds = 0}) {
    final now = DateTime.now();
    final today = dayKey(now);
    var streak = state.streak;
    if (state.lastDay != today) {
      final yesterday = dayKey(now.subtract(const Duration(days: 1)));
      streak = state.lastDay == yesterday ? streak + 1 : 1;
    }
    state = state.copyWith(
      streak: streak,
      lastDay: today,
      rituals: state.rituals + (kind == 'ritual' ? 1 : 0),
      stillness: state.stillness + (kind == 'stillness' ? 1 : 0),
      breathSeconds: state.breathSeconds + seconds,
    );
    _save();
  }

  /// A guided session listened to the end.
  void completeSession(String id) {
    recordPractice('meditation');
    if (!state.completed.contains(id)) {
      state = state.copyWith(completed: [...state.completed, id]);
      _save();
    }
  }

  void addJournal(String kind, Iterable<String> texts) {
    final today = dayKey(DateTime.now());
    final entries = [
      for (final t in texts)
        if (t.trim().isNotEmpty) JournalEntry(day: today, kind: kind, text: t.trim()),
    ];
    if (entries.isEmpty) return;
    final journal = [...entries, ...state.journal];
    state = state.copyWith(journal: journal.length > 60 ? journal.sublist(0, 60) : journal);
    _save();
  }
}

final practiceProvider = StateNotifierProvider<PracticeNotifier, PracticeState>((_) => PracticeNotifier());
