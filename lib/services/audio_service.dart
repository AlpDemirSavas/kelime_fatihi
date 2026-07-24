import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _selectPlayer = AudioPlayer();
  final AudioPlayer _feedbackPlayer = AudioPlayer();
  final AudioPlayer _celebrationPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool enabled = true;
  int? _musicRegion;

  void select() => _play(_selectPlayer, 'audio/select.wav', volume: .28);
  void target() => _play(_feedbackPlayer, 'audio/target.wav', volume: .55);
  void bonus() => _play(_feedbackPlayer, 'audio/bonus.wav', volume: .48);
  void invalid() => _play(_feedbackPlayer, 'audio/error.wav', volume: .42);
  void combo() => _play(_celebrationPlayer, 'audio/combo.wav', volume: .52);
  void victory() => _play(_celebrationPlayer, 'audio/victory.wav', volume: .64);
  void chest() => _play(_celebrationPlayer, 'audio/chest.wav', volume: .62);

  void playRegionTheme(int regionIndex) {
    if (!enabled || _musicRegion == regionIndex) return;
    _musicRegion = regionIndex;
    final theme = regionIndex % 5;
    unawaited(
      _musicPlayer.stop().then((_) async {
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        await _musicPlayer.play(
          AssetSource('audio/region_$theme.wav'),
          volume: .075,
        );
      }),
    );
  }

  void stopRegionTheme() {
    _musicRegion = null;
    unawaited(_musicPlayer.stop());
  }

  void setEnabled(bool value) {
    enabled = value;
    if (!value) stopRegionTheme();
  }

  void _play(AudioPlayer player, String asset, {required double volume}) {
    if (!enabled) return;
    unawaited(
      player.stop().then(
        (_) => player.play(AssetSource(asset), volume: volume),
      ),
    );
  }

  Future<void> dispose() async {
    await Future.wait([
      _selectPlayer.dispose(),
      _feedbackPlayer.dispose(),
      _celebrationPlayer.dispose(),
      _musicPlayer.dispose(),
    ]);
  }
}
