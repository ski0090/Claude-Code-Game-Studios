# Bevy Physics — Quick Reference

Last verified: 2026-11-02 | Engine: Bevy 0.20.1

## Bevy Ships No Physics Engine

No 0.20.1 crate provides rigid bodies, colliders, joints or a solver
(`DefaultPlugins` lists no physics plugin: `bevy_internal-0.20.1/src/default_plugins.rs:5-104`).
Physics comes from a third-party crate, chosen per project. CCGS leaves
`engine.physics` as `[TO BE CONFIGURED]` for Bevy and never picks one: it is a
dependency decision for `technical-director`.

| Crate | Version for Bevy 0.20 | Notes |
|-------|-----------------------|-------|
| `avian2d` / `avian3d` | 0.8.0 | ECS-native |
| `bevy_rapier2d` / `bevy_rapier3d` | 0.37.0 | Bevy plugin over the Rapier engine |
| `bevy-tnua` | 0.33.1 | Character controller on top of either |
| `bevy_transform_interpolation` | 0.6.0 | Smooths fixed-step motion between frames |

Versions and repositories: `PLUGINS.md`. Their APIs change with every Bevy minor
and are not documented here: read the crate's docs.rs page for that version.

## What Bevy Itself Provides

- **Fixed timestep**: the `FixedUpdate` schedule (`bevy_app-0.20.1/src/main_schedule.rs:133`)
  and `Time<Fixed>` (`bevy_time-0.20.1/src/fixed.rs:69`). Gameplay that must be
  frame-rate independent and deterministic runs there; read
  `time.delta_secs()` (`time.rs:283`) inside it for the fixed step.
- **Geometry without a solver** in `bevy::shape` (moved out of `bevy_math` in
  0.20): bounding volumes `Aabb2d`, `BoundingSphere` and ray casts such as
  `RayCast3d` (`bevy_shape-0.20.1/src/bounding/bounded2d/mod.rs:47`,
  `bounded3d/mod.rs:506`, `raycast3d.rs:14`). Enough for simple overlap tests.
- **Mesh ray casts** for picking and line of sight: the `MeshRayCast` system
  parameter (`bevy_picking-0.20.1/src/mesh_picking/ray_cast/mod.rs:175`).

## What Changed Since ~0.15 (LLM Cutoff)

- 0.20: `bevy_math::primitives` and bounding types → `bevy::shape`; curves →
  `bevy::curve` (prelude users are unaffected)
- 0.18: `Aabb` updates automatically when a mesh or sprite changes
- 0.17: `Transform::compute_matrix()` → `to_matrix()`
- Physics crates move with Bevy: the crate versions that matched 0.16 do not
  compile against 0.20

## Common Mistakes
- Writing code against a physics crate's API from memory (it changes every Bevy minor)
- Adding a physics crate without a version that requires `bevy ^0.20`
- Moving physics bodies in `Update` with a frame delta instead of `FixedUpdate`
- Mixing two physics crates in one app
