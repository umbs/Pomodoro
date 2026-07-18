import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/timer_provider.dart';

/// Keeps a macOS/desktop menu-bar (status bar) item in sync with the timer and
/// intercepts the window close button so the app keeps running in the
/// background instead of quitting.
///
/// The [TimerProvider]'s periodic timer keeps ticking regardless of window
/// visibility, so all this needs to do is reflect its state into the tray and
/// route tray/window events back into it.
class MenuBarService with TrayListener, WindowListener {
  MenuBarService(this._provider);

  final TimerProvider _provider;
  bool? _lastIsRunning;

  Future<void> init() async {
    trayManager.addListener(this);
    windowManager.addListener(this);

    // Ask window_manager to route the close button to us instead of quitting.
    await windowManager.setPreventClose(true);

    await _updateTitle();
    await _updateMenu();

    _provider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    _updateTitle();
    // Only rebuild the menu when the run/pause label actually changes, to avoid
    // churning (and closing) the menu every single second.
    if (_provider.isRunning != _lastIsRunning) {
      _updateMenu();
    }
  }

  Future<void> _updateTitle() async {
    // The tomato acts as the icon; the title carries the live countdown.
    await trayManager.setTitle('🍅 ${_provider.timeDisplay}');
  }

  Future<void> _updateMenu() async {
    _lastIsRunning = _provider.isRunning;
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show', label: 'Show Timer'),
          MenuItem.separator(),
          MenuItem(
            key: 'toggle',
            label: _provider.isRunning ? 'Pause' : 'Start',
          ),
          MenuItem(key: 'reset', label: 'Reset'),
          MenuItem(key: 'skip', label: 'Skip'),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: 'Quit Pomodoro'),
        ],
      ),
    );
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  // --- TrayListener -------------------------------------------------------

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        _showWindow();
        break;
      case 'toggle':
        _provider.isRunning ? _provider.pause() : _provider.start();
        break;
      case 'reset':
        _provider.reset();
        break;
      case 'skip':
        _provider.skipPhase();
        break;
      case 'quit':
        _quit();
        break;
    }
  }

  Future<void> _quit() async {
    await trayManager.destroy();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  // --- WindowListener -----------------------------------------------------

  @override
  void onWindowClose() async {
    // Keep running in the background; just hide the window.
    if (await windowManager.isPreventClose()) {
      await windowManager.hide();
    }
  }

  void dispose() {
    _provider.removeListener(_onProviderChanged);
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }
}
