import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/models/timer_state.dart';
import 'package:pomodoro/providers/timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // audioplayers has no plugin implementation under `flutter test`; stub its
  // channels so phase-completion sound calls are harmless no-ops.
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in const [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (call) async => null,
      );
    }
  });

  group('SessionRecord', () {
    test('round-trips through JSON', () {
      final record = SessionRecord(
        title: 'Write the report',
        completedAt: DateTime(2026, 7, 20, 9, 30),
        durationMinutes: 25,
      );

      final restored = SessionRecord.fromJson(record.toJson());

      expect(restored.title, record.title);
      expect(restored.completedAt, record.completedAt);
      expect(restored.durationMinutes, record.durationMinutes);
    });
  });

  group('TimerProvider session title', () {
    test('clamps to 90 chars and persists across restarts', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TimerProvider();
      await provider.init();

      provider.setSessionTitle('x' * 200);
      expect(provider.sessionTitle.length, kMaxSessionTitleLength);

      // A fresh provider should read the saved title back.
      final reopened = TimerProvider();
      await reopened.init();
      expect(reopened.sessionTitle.length, kMaxSessionTitleLength);
    });
  });

  group('TimerProvider history', () {
    test('records a session that finishes naturally', () async {
      SharedPreferences.setMockInitialValues({'workMinutes': 1});
      final provider = TimerProvider();
      await provider.init();
      provider.setSessionTitle('deep work');

      expect(provider.history, isEmpty);

      fakeAsync((async) {
        provider.start();
        // 1 min work = 60 ticks to reach 0, +1 tick to complete.
        async.elapse(const Duration(seconds: 65));
      });

      expect(provider.history.length, 1);
      expect(provider.history.first.title, 'deep work');
      expect(provider.history.first.durationMinutes, 1);
      expect(provider.completedSessions, 1);
    });

    test('does not record a skipped work session', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TimerProvider();
      await provider.init();
      provider.setSessionTitle('skipped task');

      provider.skipPhase();

      expect(provider.completedSessions, 1); // still counts toward the cycle
      expect(provider.history, isEmpty); // but is not logged to history
    });
  });
}
