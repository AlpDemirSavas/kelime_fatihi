import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService({this.enabled = true});

  AudioPlayer? _selectPlayerInstance;
  AudioPlayer? _feedbackPlayerInstance;
  AudioPlayer? _celebrationPlayerInstance;
  AudioPlayer? _musicPlayerInstance;

  bool enabled;
  int? _musicRegion;

  AudioPlayer get _selectPlayer =>
      _selectPlayerInstance ??= AudioPlayer();
  AudioPlayer get _feedbackPlayer =>
      _feedbackPlayerInstance ??= AudioPlayer();
  AudioPlayer get _celebrationPlayer =>
      _celebrationPlayerInstance ??= AudioPlayer();
  AudioPlayer get _musicPlayer =>
      _musicPlayerInstance ??= AudioPlayer();

  void select() {
    if (!enabled) return;
    _play(_selectPlayer, 'audio/select.wav', volume: .28);
  }

  void target() {
    if (!enabled) return;
    _play(_feedbackPlayer, 'audio/target.wav', volume: .55);
  }

  void bonus() {
    if (!enabled) return;
    _play(_feedbackPlayer, 'audio/bonus.wav', volume: .48);
  }

  void invalid() {
    if (!enabled) return;
    _play(_feedbackPlayer, 'audio/error.wav', volume: .42);
  }

  void combo() {
    if (!enabled) return;
    _play(_celebrationPlayer, 'audio/combo.wav', volume: .52);
  }

  void victory() {
    if (!enabled) return;
    _play(_celebrationPlayer, 'audio/victory.wav', volume: .64);
  }

  void chest() {
    if (!enabled) return;
    _play(_celebrationPlayer, 'audio/chest.wav', volume: .62);
  }

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
    final player = _musicPlayerInstance;
    if (player != null) {
      unawaited(player.stop());
    }
  }

  void setEnabled(bool value) {
    enabled = value;
    if (!value) stopRegionTheme();
  }

  void _play(AudioPlayer player, String asset, {required double volume}) {
    unawaited(
      player.stop().then(
        (_) => player.play(AssetSource(asset), volume: volume),
      ),
    );
  }

  Future<void> dispose() async {
    final players = <AudioPlayer?>[
      _selectPlayerInstance,
      _feedbackPlayerInstance,
      _celebrationPlayerInstance,
      _musicPlayerInstance,
    ].whereType<AudioPlayer>().toList(growable: false);

    if (players.isNotEmpty) {
      await Future.wait(players.map((player) => player.dispose()));
    }

    _selectPlayerInstance = null;
    _feedbackPlayerInstance = null;
    _celebrationPlayerInstance = null;
    _musicPlayerInstance = null;
  }
}
