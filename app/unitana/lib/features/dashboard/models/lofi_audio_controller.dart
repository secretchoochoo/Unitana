import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class LofiAudioController {
  static const String _kLofiAssetPath = 'audio/soft_static_sundays.mp3';

  AudioPlayer? _player;
  bool _assetLoaded = false;
  bool _isPlaying = false;
  double _volume = 0.25;

  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  void apply({required bool enabled, required double volume}) {
    _isPlaying = enabled;
    _volume = volume.isNaN || volume.isInfinite
        ? 0.25
        : volume.clamp(0.0, 1.0).toDouble();
    unawaited(_applyAsync());
  }

  Future<void> _ensurePlayer() async {
    if (_player != null) return;
    final player = AudioPlayer(playerId: 'unitana_lofi');
    await player.setReleaseMode(ReleaseMode.loop);
    _player = player;
  }

  Future<void> _applyAsync() async {
    try {
      await _ensurePlayer();
      final player = _player;
      if (player == null) return;

      await player.setVolume(_volume);
      if (_isPlaying) {
        if (!_assetLoaded) {
          await player.setSource(AssetSource(_kLofiAssetPath));
          _assetLoaded = true;
        }
        await player.resume();
      } else {
        await player.pause();
      }
    } catch (_) {
      // Keep settings responsive even when audio backends are unavailable.
    }
  }

  void stop() {
    _isPlaying = false;
    unawaited(_player?.pause());
  }

  void dispose() {
    final player = _player;
    _player = null;
    if (player != null) {
      unawaited(player.dispose());
    }
  }
}
