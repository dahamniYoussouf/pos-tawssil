import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> playOrderAlert() async {
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/soundOrder.mp3'));
    } catch (e) {
      _isPlaying = false;
      // Handle error quietly or log it
    }
  }

  Future<void> stopOrderAlert() async {
    if (!_isPlaying) return;
    try {
      await _player.stop();
    } finally {
      _isPlaying = false;
    }
  }

  void dispose() {
    _player.dispose();
  }
}
