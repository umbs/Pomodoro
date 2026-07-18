import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_state.dart';
import '../services/sound_service.dart';

class TimerProvider extends ChangeNotifier {
  TimerSettings _settings = const TimerSettings();
  TimerPhase _phase = TimerPhase.work;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  int _completedSessions = 0;
  Timer? _timer;
  final SoundService _soundService = SoundService();
  SharedPreferences? _prefs;

  TimerSettings get settings => _settings;
  TimerPhase get phase => _phase;
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  int get completedSessions => _completedSessions;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _completedSessions = _prefs?.getInt('completedSessions') ?? 0;
    _settings = TimerSettings(
      workMinutes: _prefs?.getInt('workMinutes') ?? 25,
      shortBreakMinutes: _prefs?.getInt('shortBreakMinutes') ?? 5,
      longBreakMinutes: _prefs?.getInt('longBreakMinutes') ?? 10,
      sessionsBeforeLongBreak: _prefs?.getInt('sessionsBeforeLongBreak') ?? 4,
    );
    _secondsRemaining = _totalSecondsForPhase(_phase);
    notifyListeners();
  }

  void _save() {
    _prefs?.setInt('completedSessions', _completedSessions);
    _prefs?.setInt('workMinutes', _settings.workMinutes);
    _prefs?.setInt('shortBreakMinutes', _settings.shortBreakMinutes);
    _prefs?.setInt('longBreakMinutes', _settings.longBreakMinutes);
    _prefs?.setInt('sessionsBeforeLongBreak', _settings.sessionsBeforeLongBreak);
  }

  String get phaseLabel {
    switch (_phase) {
      case TimerPhase.work:
        return 'Work';
      case TimerPhase.shortBreak:
        return 'Short Break';
      case TimerPhase.longBreak:
        return 'Long Break';
    }
  }

  String get timeDisplay {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    final total = _totalSecondsForPhase(_phase);
    if (total == 0) return 0;
    return 1.0 - (_secondsRemaining / total);
  }

  int _totalSecondsForPhase(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.work:
        return _settings.workMinutes * 60;
      case TimerPhase.shortBreak:
        return _settings.shortBreakMinutes * 60;
      case TimerPhase.longBreak:
        return _settings.longBreakMinutes * 60;
    }
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _secondsRemaining = _totalSecondsForPhase(_phase);
    notifyListeners();
  }

  void _tick() {
    if (_secondsRemaining > 0) {
      _secondsRemaining--;
      notifyListeners();
      return;
    }
    _onPhaseComplete();
  }

  void _onPhaseComplete() {
    _timer?.cancel();
    _isRunning = false;

    if (_phase == TimerPhase.work) {
      _soundService.playWorkComplete();
      _completedSessions++;
      _save();
      if (_completedSessions % _settings.sessionsBeforeLongBreak == 0) {
        _phase = TimerPhase.longBreak;
      } else {
        _phase = TimerPhase.shortBreak;
      }
    } else {
      _soundService.playBreakComplete();
      _phase = TimerPhase.work;
    }

    _secondsRemaining = _totalSecondsForPhase(_phase);
    notifyListeners();
  }

  void updateSettings(TimerSettings newSettings) {
    _settings = newSettings;
    if (!_isRunning) {
      _secondsRemaining = _totalSecondsForPhase(_phase);
    }
    _save();
    notifyListeners();
  }

  void skipPhase() {
    _onPhaseComplete();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _soundService.dispose();
    super.dispose();
  }
}
