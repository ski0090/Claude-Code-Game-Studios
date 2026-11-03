# Bevy — Current Best Practices

Last verified: 2026-11-02 | Engine: Bevy 0.20.1

Practices that are **new or changed** since the model's training data (~0.15).
This supplements (not replaces) the agent's built-in knowledge. Source lines are
in the 0.20.1 crates (`crate-0.20.1/src/file.rs:line`) unless a URL is given.
The Rust snippets in this directory's files compiled against Bevy 0.20.1
(Windows, 2026-11-02), and the tests shown passed; not compiled: the WESL
shader and the `bevy_remote` snippet in `modules/networking.md`.

## Project Layout (CCGS convention)

- `Cargo.toml` declares `bevy = "0.20"`; Bevy 0.20.1 needs Rust 1.97.1 or newer.
- Game logic lives in the **library crate**: `src/lib.rs` and its modules, with
  plugins `pub`. `src/main.rs` only builds the `App`. Cargo integration tests
  under `tests/` link the library's pub API only, so logic in `main.rs` cannot be
  tested from there.
- Assets in `assets/` beside `Cargo.toml`; RON scenes in `assets/scenes/*.scn.ron`;
  shaders in `assets/shaders/*.wesl`. Build output goes to `target/`.

```rust
// src/main.rs — builds the App, nothing else
use bevy::prelude::*;

fn main() {
    App::new()
        .add_plugins((DefaultPlugins, my_game::GamePlugin))
        .run();
}
```

```rust
// src/lib.rs
use bevy::prelude::*;

#[derive(Component)]
pub struct Health(pub i32);

#[derive(Message)]
pub struct Damage(pub i32);

pub fn apply_damage(mut damage: MessageReader<Damage>, mut q: Query<&mut Health>) {
    for d in damage.read() {
        for mut h in &mut q {
            h.0 -= d.0;
        }
    }
}

pub struct GamePlugin;

impl Plugin for GamePlugin {
    fn build(&self, app: &mut App) {
        app.add_message::<Damage>().add_systems(Update, apply_damage);
    }
}
```

This pair, with the tests below, compiled and passed on Bevy 0.20.1 (the lead's
probe crate, Windows, 2026-11-02).

## Cargo Features (0.18+)

- `default = ["2d", "3d", "ui", "audio"]` (`bevy-0.20.1/Cargo.toml:2867`). Since
  0.19 `2d` and `3d` do not pull in `ui`, and none pulls in `audio`: with
  `default-features = false`, list each collection you use.
- `dev` = `debug`, `bevy_dev_tools`, `render_dev_tools`, `file_watcher`
  (`Cargo.toml:2901`). `dynamic_linking` "improves iterative compile times"
  (`bevy-0.20.1/docs/cargo_features.md:131`); keep both out of release builds.
- `bevy_remote` (the Bevy Remote Protocol) and `bevy_settings` are off by
  default. See `modules/networking.md` and `modules/serialization.md`.
- Fast-compile setup: https://bevy.org/learn/quick-start/getting-started/setup
  (linked from the 0.20.1 README).

## Messages, Events and Observers (0.17+)

| Kind | Declare | Send | Receive | Runs |
|------|---------|------|---------|------|
| Message | `#[derive(Message)]` + `app.add_message::<M>()` | `MessageWriter<M>::write(m)`, `world.write_message(m)` | `MessageReader<M>::read()` in a system | When the reading system runs; pull-based, batched |
| Event | `#[derive(Event)]` | `commands.trigger(e)`, `world.trigger(e)` | `app.add_observer(\|e: On<E>\| ..)` | Immediately on trigger; push-based |
| Entity event | `#[derive(EntityEvent)]` with an `entity: Entity` field | `commands.trigger(E { entity, .. })` | `commands.entity(id).observe(..)` or a global observer | Observers of that entity, then global ones |
| Lifecycle | built in | spawning, inserting, removing | `On<Add<T>>`, `On<Insert<T>>`, `On<Discard<T>>`, `On<Remove<T>>`, `On<Despawn<T>>` | Immediately; payload has `entity` |

Sources: `bevy_ecs-0.20.1/src/message/mod.rs:100`, `event/mod.rs:89`, `:369`,
`observer/system_param.rs:25` (`On` derefs to the event, `:164`), `lifecycle.rs:339`,
`:352`.

```rust
#[derive(Message)]
pub struct EnemyDied { pub enemy: Entity }      // a batch read by the score system

#[derive(EntityEvent)]
pub struct Damaged { pub entity: Entity, pub amount: u32 }

// in any system that has `mut commands: Commands`:
//     commands.trigger(Damaged { entity: target, amount: 5 });

fn on_damaged(damaged: On<Damaged>, mut q: Query<&mut Health>) {
    if let Ok(mut h) = q.get_mut(damaged.entity) {
        h.0 -= damaged.amount as i32;
    }
}

fn on_player_added(add: On<Add<Player>>) {
    info!("player {:?} spawned", add.entity);
}
// app.add_observer(on_damaged).add_observer(on_player_added);
```

**Naming.** Bevy has no signals and no naming rule for events. CCGS's
`naming.signals: past_tense` applies to game messages and events that report
something that happened: `EnemyDied`, as Bevy's own
`bevy-0.20.1/tests/how_to_test_systems.rs:11` names one. An event that asks for
something is a request and reads as one (Bevy's examples use `DealDamage`,
`Explode`). Bevy's lifecycle events (`Add`, `Remove`, `Despawn`) are Bevy's
names, not a pattern to copy.

## Resources, Errors and States

- **Resources are entities (0.19+).** `trait Resource: Component`
  (`bevy_ecs-0.20.1/src/resource.rs:87`). `Query<Entity>` and `Query<EntityMut>`
  also match resource entities; add `Without<IsResource>` (`:124`).
- **Systems may return `Result`.** Use `?` and `.context("..")` (`ContextExt`,
  `bevy_ecs-0.20.1/src/error/bevy_error.rs:458`). Since 0.20 a panic in a system,
  run condition or observer becomes a `BevyError` sent to the
  `FallbackErrorHandler`, which re-panics by default; set your own with
  `App::set_error_handler` (`bevy_app-0.20.1/src/app.rs:1493`).
- **States need `StatesPlugin`**, which is in `DefaultPlugins` but not
  `MinimalPlugins`: `init_state` without it panics ("The `StateTransition`
  schedule is missing", `bevy_state-0.20.1/src/app.rs:102-104`).
- `NextState::set(s)` always runs `OnExit` / `OnEnter`, even to the same state;
  `set_if_different` skips that (`bevy_state-0.20.1/src/state/resources.rs:198`,
  `:206`). Tag per-state entities with `DespawnOnExit(state)`.

## Scenes: BSN and RON Worlds (0.19+)

- **`bevy::scene` is BSN**, a code-first scene system: `bsn!` builds a `Scene`,
  `commands.spawn_scene(..)` spawns it (`bevy_scene-0.20.1/src/spawn.rs:223`).
  0.20.1 ships no `.bsn` file loader (its docs say ".bsn asset files" come "in
  the future", `bevy_scene-0.20.1/src/lib.rs:79`).

```rust
#[derive(Component, FromTemplate)]
struct Hp { current: u32, max: u32 }

fn enemy() -> impl Scene {
    bsn! { Hp { current: 100, max: 100 } }
}
// commands.spawn_scene(bsn! { #Boss @enemy() Hp { max: 200 } Children [ Sword -- Shield ] });
```

- **RON scene files are `DynamicWorld`s** in `bevy::world_serialization`. The
  `WorldAssetLoader` takes `.scn` and `.scn.ron`
  (`bevy_world_serialization-0.20.1/src/world_asset_loader.rs:73-74`); spawn one
  with `DynamicWorldRoot(asset_server.load("scenes/level_01.scn.ron"))`
  (`components.rs:27`). Only reflected types round-trip: derive `Reflect` and
  add `#[reflect(Component)]`; registration is automatic through the
  `reflect_auto_register` feature in `default_app`. Writing one:
  `modules/serialization.md`.
- **glTF scenes** still load as `WorldAsset`:
  `WorldAssetRoot(asset_server.load(GltfAssetLabel::Scene(0).from_asset("models/ship.glb")))`.

## Assets and the Asset Root

- `AssetPlugin::default()` reads from `file_path: "assets"`
  (`bevy_asset-0.20.1/src/lib.rs:335`, `:346`), relative to a base path.
- The base path is `BEVY_ASSET_ROOT` if set, else `CARGO_MANIFEST_DIR` if set,
  else the executable's directory (`bevy_asset-0.20.1/src/io/file/mod.rs:25-35`).
  Both variables are read at run time with `env::var`. Cargo sets
  `CARGO_MANIFEST_DIR` for `cargo run` and `cargo test`
  (https://doc.rust-lang.org/cargo/reference/environment-variables.html), so
  those resolve `<crate>/assets`; a shipped binary run directly resolves
  `<exe dir>/assets`. `file_path` is joined to the base path
  (`FileAssetReader::new`, `io/file/mod.rs:50`), so `BEVY_ASSET_ROOT` names the
  folder that **contains** `assets/`, not `assets/` itself. Ship `assets/`
  beside the executable or set `BEVY_ASSET_ROOT`.
- Loads outside the asset folders are refused by default
  (`UnapprovedPathMode::Forbid`, `lib.rs:273-285`).
- `asset_server.load(path)` for the common case; settings, guards and untyped
  loads go through `asset_server.load_builder()` (0.19+).

## Shaders (0.20: WESL)

- **Write `.wesl`.** Every built-in Bevy 0.20.1 shader is `.wesl` (zero `.wgsl`
  files in the crates) and every shader path in the 0.20.1 examples ends in
  `.wesl`. The loader still takes `.wgsl` (`bevy_shader-0.20.1/src/shader.rs:341-343`),
  but loads it as plain WGSL with no imports (`shader.rs:135-146`), so a `.wgsl`
  file cannot use Bevy's shader modules or shader defs.
- Imports come first, end with `;`, and name the module by its path in the
  crate: `import bevy_pbr::render::forward_io::VertexOutput;`
  (`bevy_pbr-0.20.1/src/render/forward_io.wesl`). `import super::util::f;` for a
  sibling asset. `@if(DEF)` replaces `#ifdef`; integer defs are `constants::NAME`.
- Material bindings use `@group(constants::MATERIAL_BIND_GROUP)`, as Bevy's own
  shaders do (`bevy_pbr-0.20.1/src/render/pbr_bindings.wesl:38`).

```wesl
// assets/shaders/custom_material.wesl (Bevy 0.20.1's own example)
import bevy_pbr::render::forward_io::VertexOutput;

@group(constants::MATERIAL_BIND_GROUP) @binding(0) var<uniform> material_color: vec4<f32>;

@fragment
fn fragment(mesh: VertexOutput) -> @location(0) vec4<f32> {
    return material_color;
}
```

Source: https://github.com/bevyengine/bevy/blob/v0.20.1/assets/shaders/custom_material.wesl
and the 0.20 migration guide's "WESL Shaders" section. The Rust side is in
`modules/rendering.md`.

## UI (0.20)

- Buttons are `bevy::ui_widgets::Button` with an `On<Activate>` observer;
  `bevy::ui::Button` and `Interaction` are deprecated. See `modules/ui.md`.
- `px(..)`, `percent(..)`, `vw(..)`, `auto()` build `Val`s
  (`bevy_ui-0.20.1/src/geometry.rs:587-624`); `Val::Em` / `Val::Rem` are new.

## Testing (Headless)

Bevy's own pattern (`bevy-0.20.1/tests/how_to_test_apps.rs`,
`how_to_test_systems.rs`): `MinimalPlugins` instead of `DefaultPlugins`, call
`app.update()`, read `app.world()`. No window or GPU.

```rust
// tests/unit/combat.rs, declared in tests/unit/main.rs as `mod combat;`
use bevy::prelude::*;
use my_game::{Damage, GamePlugin, Health};

#[test]
fn damage_lowers_health() {
    let mut app = App::new();
    app.add_plugins((MinimalPlugins, GamePlugin));
    let e = app.world_mut().spawn(Health(5)).id();
    app.world_mut().write_message(Damage(5));
    app.update();
    assert_eq!(app.world().get::<Health>(e).unwrap().0, 0);
}
```

- `MinimalPlugins` is `TaskPoolPlugin`, `FrameCountPlugin`, `TimePlugin` and
  `ScheduleRunnerPlugin` (`bevy_internal-0.20.1/src/default_plugins.rs:163-170`).
  There is no `StatesPlugin`, `AssetPlugin`, `InputPlugin` or `TransformPlugin`:
  a `GamePlugin` that calls `init_state` panics unless the test adds
  `bevy::state::app::StatesPlugin` (not in the prelude), and input resources must be
  inserted by the test (`app.insert_resource(ButtonInput::<KeyCode>::default())`,
  then `.press(KeyCode::Space)`; `how_to_test_apps.rs:52-63`, `:96-98`).
- The first `app.update()` runs `Startup` (`how_to_test_apps.rs:72-74`).
- One system alone: `world.run_system_once(system)` (`RunSystemOnce`,
  `bevy_ecs-0.20.1/src/system/system.rs:331`).
- Unit tests that reach private items go in-file under `#[cfg(test)] mod tests`.
- Cargo only discovers `tests/*.rs` and `tests/<dir>/main.rs`. A file under
  `tests/unit/` that `main.rs` does not `mod`-declare is never compiled: no
  error, no tests (observed on the probe, 0.20.1).

## Command Line

| Purpose | Command |
|---------|---------|
| Build | `cargo build --release` |
| Test | `cargo test` (one target: `cargo test --test unit`) |
| Run | `cargo run` |
| Smoke (compile only) | `cargo check --all-targets` |
| Capture a frame | `cargo run -- --screenshot <absolute path>`: `.claude/docs/run-and-observe.md` § "Bevy 0.20 — one plugin" |

libtest output, per test: `test <path> ... ok` / `... FAILED` / `... ignored`;
per test binary (lib, each `tests/` target, doctests): `running N tests`, then
`test result: ok. N passed; M failed; K ignored; 0 measured; F filtered out; finished in Xs`
(`test result: FAILED. ...` when any failed). Zero tests: every `running N
tests` line has N = 0. Exit code 0 when all pass; **101 on a test failure and
also on a compile error** — tell them apart by `error[E` / `error: could not
compile` lines.

## Diagnostics

`DefaultPlugins` has only the `DiagnosticsPlugin` store. Add from
`bevy::diagnostic`: `FrameTimeDiagnosticsPlugin` (`fps`, `frame_time`),
`EntityCountDiagnosticsPlugin` (`entity_count`),
`SystemInformationDiagnosticsPlugin` (needs the `sysinfo_plugin` feature, in
`default_platform`) and `LogDiagnosticsPlugin`, which logs every diagnostic once
a second by default (`bevy_diagnostic-0.20.1/src/log_diagnostics_plugin.rs:94`).
On-screen: `bevy::dev_tools::fps_overlay::FpsOverlayPlugin` (`dev` feature).

## Sources

- 0.20.1 crates in the local cargo registry (`bevy_*-0.20.1/src`), cited inline
- Migration guides: `breaking-changes.md` § Sources
- docs.rs: https://docs.rs/bevy/0.20.1/bevy/
- Bevy examples at the tag: https://github.com/bevyengine/bevy/tree/v0.20.1/examples
