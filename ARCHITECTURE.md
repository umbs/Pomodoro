# Architecture

Technical design document for the Pomodoro Timer app.

## Overview

The app follows a simple three-layer architecture:

```
┌─────────────────────────────────────┐
│            UI Layer                 │
│       (timer_screen.dart)           │
│                                     │
│  Reads state from TimerProvider     │
│  via Consumer<TimerProvider>        │
└──────────────┬──────────────────────┘
               │ notifyListeners()
┌──────────────▼──────────────────────┐
│         State Layer                 │
│      (timer_provider.dart)          │
│                                     │
│  Owns all timer logic, phase        │
│  transitions, and persistence       │
├──────────────┬──────────────────────┤
│              │                      │
│  ┌───────────▼───┐  ┌────────────┐ │
│  │ SoundService  │  │ SharedPrefs│ │
│  │ (audio)       │  │ (storage)  │ │
│  └───────────────┘  └────────────┘ │
└─────────────────────────────────────┘
```

## Data Flow

### Timer Tick Cycle

```
User taps Play
  → TimerProvider.start()
    → sets _isRunning = true
    → notifyListeners() (UI updates immediately)
    → Timer.periodic fires every 1 second
      → _tick() decrements _secondsRemaining
      → notifyListeners() (UI redraws time display)
      → when _secondsRemaining == 0:
        → _onPhaseComplete()
          → plays sound via SoundService
          → increments _completedSessions (if work phase)
          → saves to SharedPreferences
          → transitions to next phase
          → resets _secondsRemaining for new phase
          → notifyListeners()
```

### Phase Transition Logic

```
Work → Short Break (default)
Work → Long Break  (every N sessions, where N = sessionsBeforeLongBreak)
Short Break → Work
Long Break  → Work
```

The transition decision is in `_onPhaseComplete()`:

```dart
if (_phase == TimerPhase.work) {
  _completedSessions++;
  if (_completedSessions % sessionsBeforeLongBreak == 0) {
    _phase = TimerPhase.longBreak;
  } else {
    _phase = TimerPhase.shortBreak;
  }
} else {
  _phase = TimerPhase.work;
}
```

## Classes and Responsibilities

### TimerPhase (enum)
**File:** `lib/models/timer_state.dart`

Three possible states: `work`, `shortBreak`, `longBreak`. Used to determine which duration to count down, which color to display, and which sound to play.

### TimerSettings (immutable data class)
**File:** `lib/models/timer_state.dart`

Holds the four user-adjustable values:

| Field | Default | Range |
|---|---|---|
| `workMinutes` | 25 | 1–60 |
| `shortBreakMinutes` | 5 | 1–60 |
| `longBreakMinutes` | 10 | 1–60 |
| `sessionsBeforeLongBreak` | 4 | 1–10 |

Uses `copyWith()` for immutable updates.

### TimerProvider (ChangeNotifier)
**File:** `lib/providers/timer_provider.dart`

The central state manager. Owns:

| State | Type | Description |
|---|---|---|
| `_settings` | `TimerSettings` | Current timer configuration |
| `_phase` | `TimerPhase` | Current phase (work/short break/long break) |
| `_secondsRemaining` | `int` | Countdown seconds for current phase |
| `_isRunning` | `bool` | Whether the timer is actively counting |
| `_completedSessions` | `int` | Total work sessions completed (persisted) |
| `_timer` | `Timer?` | The dart:async periodic timer |
| `_prefs` | `SharedPreferences?` | Handle to persistent storage |

**Computed properties:**
- `timeDisplay` → `"MM:SS"` formatted string
- `progress` → `0.0` to `1.0` for the circular progress indicator
- `phaseLabel` → Human-readable phase name

**Methods:**
- `init()` → Loads persisted data from SharedPreferences
- `start()` → Begins countdown, notifies UI immediately
- `pause()` → Stops countdown
- `reset()` → Resets countdown to full duration for current phase
- `skipPhase()` → Jumps to next phase as if timer completed
- `updateSettings()` → Updates settings and persists them
- `_tick()` → Called every second, decrements or completes phase
- `_onPhaseComplete()` → Handles phase transition, sound, persistence
- `_save()` → Writes session count + settings to SharedPreferences

### SoundService
**File:** `lib/services/sound_service.dart`

Thin wrapper around `audioplayers`. Two methods:
- `playWorkComplete()` → Plays `assets/sounds/work_complete.wav` (880Hz, 300ms)
- `playBreakComplete()` → Plays `assets/sounds/break_complete.wav` (523Hz, 400ms)

### TimerScreen (StatefulWidget)
**File:** `lib/screens/timer_screen.dart`

Single-screen UI. Local state: `_showSettings` (bool) to toggle visibility of phase indicator and settings bar.

**Widget tree:**

```
Scaffold (background: #1A1A2E)
└── SafeArea
    └── Stack
        ├── LayoutBuilder → SingleChildScrollView → ConstrainedBox → Column
        │   ├── _PhaseIndicator      (animated show/hide)
        │   ├── _TimerDisplay        (always visible)
        │   │   ├── CircularProgressIndicator
        │   │   └── Text (MM:SS, JetBrains Mono Light)
        │   ├── _Controls            (always visible)
        │   │   ├── Reset button
        │   │   ├── Play/Pause button
        │   │   └── Skip button
        │   ├── _SessionCounter      (always visible)
        │   └── _SettingsBar         (animated show/hide)
        │       ├── Work ±
        │       ├── Break ±
        │       ├── Long ±
        │       └── Rounds ±
        └── Positioned (top-right)
            └── Gear IconButton (toggles _showSettings)
```

**Animations:**
- `AnimatedSize` + `AnimatedOpacity` on `_PhaseIndicator` and `_SettingsBar`
- `AnimatedRotation` on the gear icon (180° turn when active)
- All animations: 200ms, `Curves.easeInOut`

**Responsive behavior:**
- `LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox` prevents overflow
- When window is large: content is spaced evenly via `MainAxisAlignment.spaceEvenly`
- When window is small: content scrolls instead of overflowing

## Persistence

### Storage Mechanism

`shared_preferences` (BSD license) — a key-value store backed by:
- **macOS/iOS:** `NSUserDefaults`
- **Android:** `SharedPreferences` (XML file)
- **Linux:** JSON file in `$XDG_DATA_HOME`
- **Windows:** JSON file in `%APPDATA%`
- **Web:** `localStorage`

No database, no migrations, no schema.

### Persisted Keys

| Key | Type | Description |
|---|---|---|
| `completedSessions` | `int` | Total work sessions completed |
| `workMinutes` | `int` | Work session duration |
| `shortBreakMinutes` | `int` | Short break duration |
| `longBreakMinutes` | `int` | Long break duration |
| `sessionsBeforeLongBreak` | `int` | Rounds before long break |

### When Data is Saved

- **Session count:** Saved immediately when a work phase completes (`_onPhaseComplete`)
- **Settings:** Saved immediately when any setting is changed (`updateSettings`)

### When Data is Loaded

Once, at app startup: `main()` calls `TimerProvider.init()` before `runApp()`.

## Startup Sequence

```
main()
  → WidgetsFlutterBinding.ensureInitialized()
  → TimerProvider()              (constructor, defaults only)
  → TimerProvider.init()         (loads SharedPreferences, applies saved values)
  → runApp(PomodoroApp)          (provider injected via ChangeNotifierProvider.value)
```

## Sound Assets

Both WAV files were programmatically generated using Python's `wave` module — pure sine waves with fade-in/fade-out envelopes (50ms each) to prevent clicks.

| File | Frequency | Duration | Purpose |
|---|---|---|---|
| `work_complete.wav` | 880Hz (A5) | 300ms | Work session ended |
| `break_complete.wav` | 523Hz (C5) | 400ms | Break ended |

Format: 16-bit PCM, 44.1kHz, mono. Public domain — no license restrictions.

## Fonts

| Font | Usage | License |
|---|---|---|
| JetBrains Mono Light (300) | Timer digits (MM:SS) | SIL OFL 1.1 |
| JetBrains Mono Regular | Settings numbers | SIL OFL 1.1 |
| Poppins Regular | Labels, session counter | SIL OFL 1.1 |
| Poppins SemiBold (600) | Active phase indicator | SIL OFL 1.1 |

Fonts are bundled as `.ttf` files in `assets/fonts/` — no network calls, no `google_fonts` package.

## Color Scheme

| Element | Color | Hex |
|---|---|---|
| Background | Dark navy | `#1A1A2E` |
| Work phase ring | Red | `#E94560` |
| Short break ring | Deep blue | `#0F3460` |
| Long break ring | Purple | `#533483` |
| Play/pause button | Red | `#E94560` |
| Primary text | White | `#FFFFFF` |
| Secondary text | White 54% | `rgba(255,255,255,0.54)` |
| Muted text | White 38% | `rgba(255,255,255,0.38)` |

## Dependencies

| Package | Version | License | Purpose |
|---|---|---|---|
| `provider` | ^6.1.2 | MIT | State management (ChangeNotifier) |
| `audioplayers` | ^6.4.0 | MIT | Play WAV notification sounds |
| `shared_preferences` | ^2.3.4 | BSD | Persist session count and settings |
| `cupertino_icons` | ^1.0.8 | MIT | iOS-style icons (Flutter default) |

All dependencies are open source with permissive licenses compatible with MIT.

## What's Not Implemented (by design)

- No database or migrations
- No user accounts or cloud sync
- No notification center / system notifications
- No task naming or history log
- No theming or dark/light mode toggle (it's always dark)
- No internationalization
- No analytics or telemetry
