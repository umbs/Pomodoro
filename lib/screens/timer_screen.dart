import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/timer_state.dart';
import '../providers/timer_provider.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  bool _showSettings = false;
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: context.read<TimerProvider>().sessionTitle,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _phaseLabel(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.work:
        return 'Work';
      case TimerPhase.shortBreak:
        return 'Short Break';
      case TimerPhase.longBreak:
        return 'Long Break';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Consumer<TimerProvider>(
          builder: (context, timer, _) {
            return Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(height: 16),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: AnimatedOpacity(
                                opacity: _showSettings ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: SizedBox(
                                  height: _showSettings ? null : 0,
                                  child: _PhaseIndicator(phase: timer.phase),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _SessionTitleField(
                              controller: _titleController,
                              onChanged: timer.setSessionTitle,
                            ),
                            const SizedBox(height: 24),
                            _TimerDisplay(
                              timeDisplay: timer.timeDisplay,
                              progress: timer.progress,
                              phase: timer.phase,
                            ),
                            const SizedBox(height: 24),
                            _Controls(timer: timer),
                            const SizedBox(height: 16),
                            _SessionCounter(
                              count: timer.completedSessions,
                              phaseLabel: _phaseLabel(timer.phase),
                            ),
                            const SizedBox(height: 16),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: AnimatedOpacity(
                                opacity: _showSettings ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: SizedBox(
                                  height: _showSettings ? null : 0,
                                  child: _SettingsBar(timer: timer),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedRotation(
                    turns: _showSettings ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: () =>
                          setState(() => _showSettings = !_showSettings),
                      icon: Icon(
                        Icons.settings,
                        color: _showSettings ? Colors.white70 : Colors.white24,
                        size: 22,
                      ),
                      tooltip: 'Settings',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  final TimerPhase phase;
  const _PhaseIndicator({required this.phase});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: TimerPhase.values.map((p) {
        final isActive = p == phase;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _label(p),
            style: TextStyle(
              fontFamily: 'Poppins',
              color: isActive ? Colors.white : Colors.white38,
              fontSize: 16,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _label(TimerPhase p) {
    switch (p) {
      case TimerPhase.work:
        return 'Work';
      case TimerPhase.shortBreak:
        return 'Short Break';
      case TimerPhase.longBreak:
        return 'Long Break';
    }
  }
}

class _SessionTitleField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SessionTitleField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        cursorColor: const Color(0xFFE94560),
        inputFormatters: [
          LengthLimitingTextInputFormatter(kMaxSessionTitleLength),
        ],
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'What are you working on?',
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white38,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final String timeDisplay;
  final double progress;
  final TimerPhase phase;
  const _TimerDisplay({
    required this.timeDisplay,
    required this.progress,
    required this.phase,
  });

  Color get _phaseColor {
    switch (phase) {
      case TimerPhase.work:
        return const Color(0xFFE94560);
      case TimerPhase.shortBreak:
        return const Color(0xFF0F3460);
      case TimerPhase.longBreak:
        return const Color(0xFF533483);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 260,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(_phaseColor),
            ),
          ),
          Text(
            timeDisplay,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final TimerProvider timer;
  const _Controls({required this.timer});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: timer.reset,
          icon: const Icon(Icons.refresh, color: Colors.white54, size: 32),
          tooltip: 'Reset',
        ),
        const SizedBox(width: 16),
        _PlayPauseButton(
          isRunning: timer.isRunning,
          onPressed: timer.isRunning ? timer.pause : timer.start,
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: timer.skipPhase,
          icon: const Icon(
            Icons.skip_next,
            color: Colors.white54,
            size: 32,
          ),
          tooltip: 'Skip',
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onPressed;
  const _PlayPauseButton({required this.isRunning, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE94560),
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          isRunning ? Icons.pause : Icons.play_arrow,
          size: 36,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SessionCounter extends StatelessWidget {
  final int count;
  final String phaseLabel;
  const _SessionCounter({required this.count, required this.phaseLabel});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$phaseLabel · $count sessions',
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white54,
        fontSize: 14,
      ),
    );
  }
}

class _SettingsBar extends StatelessWidget {
  final TimerProvider timer;
  const _SettingsBar({required this.timer});

  @override
  Widget build(BuildContext context) {
    final settings = timer.settings;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SettingChip(
            label: 'Work',
            value: settings.workMinutes,
            onChanged: (v) =>
                timer.updateSettings(settings.copyWith(workMinutes: v)),
          ),
          _SettingChip(
            label: 'Break',
            value: settings.shortBreakMinutes,
            onChanged: (v) =>
                timer.updateSettings(settings.copyWith(shortBreakMinutes: v)),
          ),
          _SettingChip(
            label: 'Long',
            value: settings.longBreakMinutes,
            onChanged: (v) =>
                timer.updateSettings(settings.copyWith(longBreakMinutes: v)),
          ),
          _SettingChip(
            label: 'Rounds',
            value: settings.sessionsBeforeLongBreak,
            onChanged: (v) => timer.updateSettings(
                settings.copyWith(sessionsBeforeLongBreak: v)),
            min: 1,
            max: 10,
          ),
        ],
      ),
    );
  }
}

class _SettingChip extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const _SettingChip({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TinyButton(
              icon: Icons.remove,
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'JetBrainsMono', color: Colors.white, fontSize: 16),
              ),
            ),
            _TinyButton(
              icon: Icons.add,
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _TinyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _TinyButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        color: Colors.white54,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
