# Bevy 0.20 — Ecosystem Crates

Last verified: 2026-11-02

Bevy ships no physics, navigation, multiplayer networking or editor. Those come
from third-party crates, each tied to one Bevy minor: a crate built for 0.19 does
not compile against 0.20. This index lists only crates whose newest stable
release on crates.io requires Bevy 0.20 (checked 2026-11-02 through the
crates.io API: `https://crates.io/api/v1/crates/<name>/<version>/dependencies`,
the `bevy`, `bevy_ecs` or `bevy_app` requirement). Nothing here is a default:
adding any crate is a dependency decision for `technical-director`.

---

## How to Use This Guide

- **Version** is the crate's newest stable release and the one to put in
  `Cargo.toml`. A newer Bevy needs a newer crate release; check its changelog.
- **APIs are not documented here.** These crates change with every Bevy minor
  and their names were not checked against source. Read the crate's docs.rs page
  for that exact version before writing code against it, and say so when you
  have not.
- Engine subsystems that Bevy does ship (input, audio, UI, animation,
  rendering) are in `modules/`.

---

## Physics — `modules/physics.md`

| Crate | Version | Bevy req | Released | Repository |
|-------|---------|----------|----------|------------|
| `avian2d` / `avian3d` | 0.8.0 | `^0.20` | 2026-10-20 | https://github.com/avianphysics/avian |
| `bevy_rapier2d` / `bevy_rapier3d` | 0.37.0 | `^0.20` | 2026-10-10 | https://github.com/dimforge/rapier |
| `bevy-tnua` (character controller) | 0.33.1 | `^0.20` | 2026-10-30 | https://github.com/idanarye/bevy-tnua |
| `bevy_transform_interpolation` | 0.6.0 | `^0.20` | 2026-10-18 | https://github.com/Jondolf/bevy_transform_interpolation |

## Input

| Crate | Version | Bevy req | Released | Repository |
|-------|---------|----------|----------|------------|
| `leafwing-input-manager` | 0.22.0 | `^0.20.0` | 2026-10-15 | https://github.com/leafwing-studios/leafwing-input-manager |
| `bevy_enhanced_input` | 0.27.2 | `^0.20` | 2026-10-26 | https://github.com/simgine/bevy_enhanced_input |

## Debug UI and Inspection

| Crate | Version | Bevy req | Released | Repository |
|-------|---------|----------|----------|------------|
| `bevy_egui` | 0.43.1 | `bevy_ecs ^0.20.0` | 2026-10-10 | https://github.com/vladbat00/bevy_egui |
| `bevy-inspector-egui` | 0.38.0 | `bevy_ecs ^0.20.0` | 2026-10-17 | https://github.com/jakobhellermann/bevy-inspector-egui/ |
| `bevy_mod_debugdump` (schedule graphs) | 0.17.0 | `bevy_ecs ^0.20.0` | 2026-10-17 | https://github.com/jakobhellermann/bevy_mod_debugdump |

## Assets and Loading

| Crate | Version | Bevy req | Released | Repository |
|-------|---------|----------|----------|------------|
| `bevy_asset_loader` | 0.28.1 | `bevy_ecs ^0.20.0` | 2026-10-13 | https://github.com/NiklasEi/bevy_asset_loader |
| `bevy_common_assets` (JSON, RON, TOML … as assets) | 0.18.0 | `bevy_app ^0.20` | 2026-10-09 | https://github.com/NiklasEi/bevy_common_assets |
| `bevy_embedded_assets` | 0.17.0 | `bevy_ecs ^0.20` | 2026-10-27 | https://github.com/vleue/bevy_embedded_assets |
| `iyes_progress` | 0.18.0 | `bevy_ecs ^0.20.0` | 2026-10-09 | https://github.com/IyesGames/iyes_progress |

## Audio — `modules/audio.md`

| Crate | Version | Bevy req | Released | Repository |
|-------|---------|----------|----------|------------|
| `bevy_kira_audio` | 0.27.1 | `bevy_ecs ^0.20` | 2026-10-13 | https://github.com/NiklasEi/bevy_kira_audio |

## Networking — `modules/networking.md`

| Crate | Version | Bevy req | Released | Repository |
|-------|---------|----------|----------|------------|
| `lightyear` | 0.31.0 | `bevy_ecs ^0.20` | 2026-10-21 | https://github.com/cBournhonesque/lightyear |
| `bevy_replicon` | 0.45.5 | `^0.20` | 2026-10-31 | https://github.com/simgine/bevy_replicon |
| `bevy_replicon_renet` | 0.21.0 | `^0.20` | 2026-10-31 | https://github.com/simgine/bevy_replicon_renet |
| `bevy_renet` | 6.0.0 | `bevy_ecs ^0.20` | 2026-10-30 | https://github.com/lucaspoffo/renet |

## Navigation — `modules/navigation.md`

| Crate | Version | Bevy req | Released | Repository |
|-------|---------|----------|----------|------------|
| `vleue_navigator` (navmesh) | 0.17.0 | `^0.20` | 2026-10-27 | https://github.com/vleue/vleue_navigator |
| `bevy_northstar` (grid pathfinding) | 0.8.0 | `^0.20` | 2026-10-29 | https://github.com/jtothethree/bevy_northstar |

## Levels, Tilemaps, Effects and Cameras

| Crate | Version | Bevy req | Released | Repository |
|-------|---------|----------|----------|------------|
| `bevy_ecs_tilemap` | 0.20.0 | `^0.20` | 2026-10-21 | https://github.com/StarArawn/bevy_ecs_tilemap |
| `bevy_ecs_ldtk` | 0.16.0 | `^0.20.0` | 2026-10-25 | https://github.com/Trouv/bevy_ecs_ldtk |
| `bevy_ecs_tiled` | 0.15.0 | `^0.20` | 2026-10-24 | https://github.com/adrien-bon/bevy_ecs_tiled |
| `bevy_hanabi` (GPU particles) | 0.20.0 | `^0.20` | 2026-11-01 | https://github.com/djeedai/bevy_hanabi |
| `bevy_tweening` | 0.17.0 | `^0.20` | 2026-11-01 | https://github.com/djeedai/bevy_tweening |
| `bevy_vector_shapes` | 0.14.0 | `^0.20` | 2026-10-12 | https://github.com/james-j-obrien/bevy_vector_shapes |
| `bevy_panorbit_camera` | 0.36.0 | `^0.20` | 2026-10-20 | https://github.com/Plonq/bevy_panorbit_camera |

Bevy 0.20 also has first-party camera controllers behind the `free_camera`,
`pan_camera` and `pan_orbit_camera` features (`bevy-0.20.1/Cargo.toml:2920`,
`:2945`, `:2946`; module `bevy::camera_controller`). Their type names were not
checked: the `bevy_camera_controller` crate was not in the local registry.

## Misc

| Crate | Version | Bevy req | Released | Repository |
|-------|---------|----------|----------|------------|
| `bevy_rand` | 0.16.0 | `bevy_ecs ^0.20.0` | 2026-10-09 | https://github.com/Bluefinger/bevy_rand |
| `bevy_pkv` (key-value persistence) | 0.17.0 | `bevy_ecs ^0.20` | 2026-10-23 | https://github.com/johanhelsing/bevy_pkv |
| `bevy_mod_scripting` | 0.23.0 | `^0.20` | 2026-10-14 | https://github.com/makspll/bevy_mod_scripting |

---

## No 0.20 Release Yet (2026-11-02)

Do not suggest these for a 0.20 project; check crates.io again before relying on
this list.

| Crate | Newest stable | Targets |
|-------|---------------|---------|
| `bevy_seedling` | 0.8.0 | Bevy 0.19 |
| `bevy_matchbox` | 0.15.0 | Bevy 0.19 (released after 0.20, still `^0.19.0`) |
| `bevy_framepace` | 0.22.0 | Bevy 0.19 |
| `bevy_editor_cam` | 0.10.1 | Bevy 0.19 |
| `bevy_prototype_lyon` | 0.17.0 | Bevy 0.19 |
| `iyes_perf_ui` | 0.5.0 | Bevy 0.16 |
| `oxidized_navigation` | 0.12.0 | Bevy 0.15 |
