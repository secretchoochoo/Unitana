# PACK W Lo-Fi Audio Spike (XL-M)

## Scope of this spike
- Add a safe, optional lo-fi audio settings scaffold.
- Keep feature disabled by default.
- Persist enable/volume preferences across restarts.
- Avoid adding non-deterministic runtime playback behavior in this slice.

## Shipped in XL-M
- App/storage state:
  - `lofi_audio_enabled_v1` (bool, default `false`)
  - `lofi_audio_volume_v1` (double, default `0.35`, clamped `0.0..1.0`)
- App-state API:
  - `lofiAudioEnabled`
  - `lofiAudioVolume`
  - `setLofiAudioEnabled(...)`
  - `setLofiAudioVolume(...)`
- Dashboard settings controls:
  - toggle: `settings_option_lofi_audio`
  - slider: `settings_lofi_volume_slider` (disabled until toggle enabled)
- Runtime seam:
  - added no-op `LofiAudioController` for future playback integration.

## Safety contracts
- No auto-play on startup.
- Toggle remains off by default on fresh installs.
- Volume remains persisted/clamped and never blocks app flows.

## Test coverage
- `dashboard_language_settings_test.dart` now verifies:
  - default OFF + disabled slider
  - toggle persistence
  - volume persistence
  - reload behavior from persisted values

## Next follow-up (post-spike)
1. Integrate an actual royalty-free playback backend behind `LofiAudioController`.
2. Add explicit playback-state indicators (if active) with background/foreground handling.
3. Expand settings copy localization keys for lo-fi controls in non-English seeds.
