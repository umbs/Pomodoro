import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/timer_provider.dart';
import 'screens/timer_screen.dart';
import 'services/menu_bar_service.dart';

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_isDesktop) {
    await windowManager.ensureInitialized();
    // Configure and show the window directly rather than via
    // waitUntilReadyToShow: its ready callback does not fire reliably under
    // Flutter's merged UI/platform-thread mode on macOS, which would leave the
    // window hidden at launch.
    await windowManager.setTitle('Pomodoro');
    await windowManager.setSize(const Size(400, 720));
    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();
  }

  final timerProvider = TimerProvider();
  await timerProvider.init();

  if (_isDesktop) {
    await MenuBarService(timerProvider).init();
  }

  runApp(PomodoroApp(timerProvider: timerProvider));
}

class PomodoroApp extends StatelessWidget {
  final TimerProvider timerProvider;
  const PomodoroApp({super.key, required this.timerProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: timerProvider,
      child: MaterialApp(
        title: 'Pomodoro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const TimerScreen(),
      ),
    );
  }
}
