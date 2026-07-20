enum TimerPhase { work, shortBreak, longBreak }

/// Maximum length of a session title.
const int kMaxSessionTitleLength = 90;

/// A completed work session, saved to history for the (future) analytics view.
class SessionRecord {
  final String title;
  final DateTime completedAt;
  final int durationMinutes;

  const SessionRecord({
    required this.title,
    required this.completedAt,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'completedAt': completedAt.toIso8601String(),
        'durationMinutes': durationMinutes,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        title: (json['title'] as String?) ?? '',
        completedAt:
            DateTime.parse(json['completedAt'] as String).toLocal(),
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      );
}

class TimerSettings {
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;

  const TimerSettings({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 10,
    this.sessionsBeforeLongBreak = 4,
  });

  TimerSettings copyWith({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
  }) {
    return TimerSettings(
      workMinutes: workMinutes ?? this.workMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
    );
  }
}
