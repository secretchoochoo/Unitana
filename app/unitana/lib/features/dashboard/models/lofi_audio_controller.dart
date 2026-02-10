class LofiAudioController {
  bool _isPlaying = false;
  double _volume = 0.35;

  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  void apply({required bool enabled, required double volume}) {
    _isPlaying = enabled;
    _volume = volume.isNaN || volume.isInfinite
        ? 0.35
        : volume.clamp(0.0, 1.0).toDouble();
  }

  void stop() {
    _isPlaying = false;
  }

  void dispose() {}
}
