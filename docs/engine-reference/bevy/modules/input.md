# Bevy Input — Quick Reference

Last verified: 2026-11-02 | Engine: Bevy 0.20.1

Bevy has no action-mapping layer: `bevy_input` gives raw device state.
Rebindable actions come from a crate (`leafwing-input-manager`,
`bevy_enhanced_input`; versions in `PLUGINS.md`).

## What Changed Since ~0.15 (LLM Cutoff)

### 0.20 Changes
- Pointer events are flat types (`PointerClick`, `PointerPress`, …) — `modules/ui.md`
- `FocusCause` gains `Auto`; Escape in a text input clears `InputFocus` and propagates
- Cursor icons: `bevy_feathers::cursor` → `bevy_picking::cursor`

### 0.19 Changes
- `InputFocus` is read with `get()` and written with `set(entity, cause)` /
  `clear()` (`bevy_input_focus-0.20.1/src/lib.rs:145-156`; `FocusCause` at
  `gained_and_lost.rs:16`); `InputDispatchPlugin` is in `DefaultPlugins`

### 0.18 Changes
- With `default-features = false`, input sources are features: `keyboard`,
  `mouse`, `gamepad`, `touch`, `gestures` (`bevy-0.20.1/Cargo.toml:2933`, `:2941`,
  `:2921`, `:2993`, `:2922`). Without them the input silently never arrives
- `AutoDirectionalNavigation` moves UI focus with a gamepad or arrow keys

### 0.17 Changes
- Raw input streams are messages: read `KeyboardInput`, `MouseMotion`,
  `MouseWheel` with a `MessageReader` (`#[derive(Message)]` at
  `bevy_input-0.20.1/src/keyboard.rs:100`, `mouse.rs:100`, `:203`)
- `ButtonInput<Key>` (logical, layout-aware key) beside `ButtonInput<KeyCode>`
  (physical key) (`bevy_input-0.20.1/src/lib.rs:116`)
- `InputSystem` set → `InputSystems`; cursor grab and visibility moved to the
  `CursorOptions` component on the window entity (`bevy_window-0.20.1/src/window.rs:752`)

## Current API Patterns

### Keyboard and mouse
```rust
fn player_input(
    keys: Res<ButtonInput<KeyCode>>,
    buttons: Res<ButtonInput<MouseButton>>,
    motion: Res<AccumulatedMouseMotion>,
) {
    if keys.just_pressed(KeyCode::Space) { /* jump */ }
    if buttons.pressed(MouseButton::Left) { /* fire */ }
    let look = motion.delta; // Vec2 accumulated this frame
}
```
`ButtonInput` at `bevy_input-0.20.1/src/button_input.rs:125` (`just_pressed`
`:188`); `AccumulatedMouseMotion` / `AccumulatedMouseScroll` at `mouse.rs:264`, `:285`.

### Gamepads are entities
```rust
fn gamepad_input(gamepads: Query<&Gamepad>) {
    for gamepad in &gamepads {
        let stick: Vec2 = gamepad.left_stick();
        if gamepad.just_pressed(GamepadButton::South) { /* jump */ }
    }
}
```
`Gamepad` component at `bevy_input-0.20.1/src/gamepad.rs:376`, `left_stick`
`:418`, `GamepadButton::South` `:583`. Touch: the `Touches` resource (`touch.rs:249`).

### Faking input in a headless test
`MinimalPlugins` has no `InputPlugin`. Insert the resource and drive it:
`app.insert_resource(ButtonInput::<KeyCode>::default())`, then
`app.world_mut().resource_mut::<ButtonInput<KeyCode>>().press(KeyCode::Space)`
and `app.update()`; `.clear()` resets `just_pressed`
(`bevy-0.20.1/tests/how_to_test_apps.rs:52-63`, `:96-120`).

## Common Mistakes
- `EventReader<KeyboardInput>` (it is a `MessageReader` since 0.17)
- Matching `KeyCode` for text entry or shortcuts that should follow the layout
  (use `ButtonInput<Key>` or the text input widget)
- A minimal-features build without `keyboard` / `mouse` / `gamepad`
- Writing `input_focus.0` (use `get()` / `set(entity, cause)`)
- Hard-coding bindings in gameplay systems instead of an action layer or a
  data file the player can rebind
