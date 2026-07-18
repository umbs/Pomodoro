import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/main.dart';
import 'package:pomodoro/providers/timer_provider.dart';

void main() {
  testWidgets('App renders timer screen', (WidgetTester tester) async {
    final provider = TimerProvider();
    await tester.pumpWidget(PomodoroApp(timerProvider: provider));
    expect(find.text('25:00'), findsOneWidget);
  });
}
