import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A durable record of what the alarm system actually did.
///
/// WHY THIS EXISTS
///
/// Every alarm failure so far has been diagnosed by inference: a symptom is
/// described, a cause is guessed, a fix is shipped, and the next failure shows
/// the guess was wrong. That loop is expensive and it has run too many times.
///
/// The problem is that an alarm failure produces no evidence. "Nothing
/// happened" looks identical whether the schedule was never armed, was armed
/// and wiped, fired into a dead channel, or the polling service was frozen by
/// the OS. Those need completely different fixes and cannot be told apart from
/// the outside.
///
/// This writes a timestamped line for every meaningful event — armed, ticked,
/// fired, repaired, failed — to disk, survives restarts, and can be read on
/// screen or copied out. When a prayer is missed, the log says which of those
/// four things happened.
///
/// Kept deliberately small: a bounded ring buffer in SharedPreferences, no
/// database, no dependency. It has to work inside the background isolate too.
class AlarmEventLog {
  AlarmEventLog._();

  static const _key = 'alarm_event_log_v1';

  /// Enough to cover a couple of days of prayers plus service heartbeats,
  /// small enough that reading and rewriting it stays cheap.
  static const int _maxEntries = 300;

  static Future<void> add(String event, {String? detail}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Re-read every time rather than caching. The background isolate and the
      // UI isolate both write here, and a cached copy in one would silently
      // discard the other's entries.
      await prefs.reload();
      final List<String> lines = prefs.getStringList(_key) ?? <String>[];

      lines.add(json.encode(<String, dynamic>{
        't': DateTime.now().millisecondsSinceEpoch,
        'e': event,
        if (detail != null) 'd': detail,
      }));

      if (lines.length > _maxEntries) {
        lines.removeRange(0, lines.length - _maxEntries);
      }
      await prefs.setStringList(_key, lines);
    } catch (_) {
      // Logging must never be able to break the thing it is observing.
    }
  }

  static Future<List<AlarmLogEntry>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final List<String> lines = prefs.getStringList(_key) ?? <String>[];
      final out = <AlarmLogEntry>[];
      for (final String l in lines) {
        try {
          final m = json.decode(l) as Map<String, dynamic>;
          out.add(AlarmLogEntry(
            at: DateTime.fromMillisecondsSinceEpoch(m['t'] as int),
            event: m['e'] as String,
            detail: m['d'] as String?,
          ));
        } catch (_) {}
      }
      return out.reversed.toList(); // newest first
    } catch (_) {
      return <AlarmLogEntry>[];
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  /// Plain text, for pasting into a message.
  static Future<String> asText() async {
    final entries = await read();
    final b = StringBuffer('Masjid alarm log (newest first)\n');
    for (final e in entries) {
      b.writeln('${e.stamp}  ${e.event}${e.detail == null ? '' : '  ${e.detail}'}');
    }
    return b.toString();
  }
}

class AlarmLogEntry {
  const AlarmLogEntry({required this.at, required this.event, this.detail});

  final DateTime at;
  final String event;
  final String? detail;

  String get stamp {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(at.day)}/${two(at.month)} ${two(at.hour)}:${two(at.minute)}:${two(at.second)}';
  }

  /// Heartbeats are noise until something goes wrong, at which point their
  /// ABSENCE is the most important thing in the log.
  bool get isHeartbeat => event == 'service tick';
}
