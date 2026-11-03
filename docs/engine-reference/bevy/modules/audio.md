# Bevy Audio — Quick Reference

Last verified: 2026-11-02 | Engine: Bevy 0.20.1

`bevy_audio` plays sounds through rodio. It has no mixer buses, effects or DSP
graph; a game that needs them uses a crate (`bevy_kira_audio`, `PLUGINS.md`).

## What Changed Since ~0.15 (LLM Cutoff)

### 0.19 Changes
- rodio 0.22 (`bevy_audio-0.20.1/Cargo.toml:70-71`). The `audio` feature is
  `bevy_audio` + `vorbis` (`bevy-0.20.1/Cargo.toml:2765`); other formats are
  opt-in features: `wav`, `mp3`, `flac`, `aac`, or `audio-all-formats`
  (`:3034`, `:2942`, `:2918`, `:2754`, `:2769`)
- `2d`, `3d` and `ui` no longer imply `audio`: a `default-features = false`
  build lists `audio` itself
- Android audio needs API level 26 or later
- `bevy_settings` can persist volume settings (`modules/serialization.md`)

### 0.17 Changes
- `Volume` lost its `+` / `-` operators; use `increase_by_percentage`
  (`bevy_audio-0.20.1/src/volume.rs:175`)

## Current API Patterns

### One-shot and looping sounds
```rust
use bevy::{audio::Volume, prelude::*}; // `Volume` is not in the prelude

fn play_hit(mut commands: Commands, asset_server: Res<AssetServer>) {
    commands.spawn((
        AudioPlayer::new(asset_server.load("sounds/hit.ogg")),
        PlaybackSettings::DESPAWN, // despawn the entity when playback ends
    ));
}

fn start_music(mut commands: Commands, asset_server: Res<AssetServer>) {
    commands.spawn((
        AudioPlayer::new(asset_server.load("music/theme.ogg")),
        PlaybackSettings::LOOP.with_volume(Volume::Linear(0.5)),
        MusicTrack, // your own marker, to find the sink later
    ));
}
```
`AudioPlayer::new` at `bevy_audio-0.20.1/src/audio.rs:270`; `PlaybackSettings`
`:35` with `ONCE` `:87`, `LOOP` `:100`, `DESPAWN` `:106`, `REMOVE` `:112`;
`with_volume` `:130`; `Volume::Linear` / `Volume::Decibels` (`volume.rs:36`).

### Controlling a playing sound
Bevy inserts an `AudioSink` on the entity once playback starts
(`bevy_audio-0.20.1/src/sinks.rs:139`); its `AudioSinkPlayback` trait has
`play`, `pause`, `toggle_playback`, `is_paused` and `set_volume` (`sinks.rs:10-94`).
```rust
fn pause_music(mut sinks: Query<&mut AudioSink, With<MusicTrack>>) {
    for sink in &mut sinks {
        sink.pause();
    }
}
```

### Global volume and spatial audio
- `GlobalVolume` resource scales every sound (`volume.rs:10`)
- Spatial audio: `PlaybackSettings { spatial: true, .. }` (`audio.rs:57`) on
  the emitter and a `SpatialListener` on the listener (`audio.rs:173`); the
  emitter then gets a `SpatialAudioSink`, not an `AudioSink`

## Common Mistakes
- Loading `.wav`, `.mp3` or `.flac` without enabling that format feature (only
  Ogg Vorbis is on by default)
- Expecting `AudioSink` on the same frame as the spawn (it appears once the
  sound starts)
- `volume + Volume::Linear(0.1)` (operators removed in 0.17)
- Building buses or ducking on `bevy_audio` (it has none); reach for a crate
- Leaving one-shot entities alive (`PlaybackSettings::ONCE` keeps the entity;
  `DESPAWN` removes it)
