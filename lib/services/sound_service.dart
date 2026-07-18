import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playWorkComplete() async {
    await _player.play(AssetSource('sounds/work_complete.wav'));
  }

  Future<void> playBreakComplete() async {
    await _player.play(AssetSource('sounds/break_complete.wav'));
  }

  void dispose() {
    _player.dispose();
  }
}
