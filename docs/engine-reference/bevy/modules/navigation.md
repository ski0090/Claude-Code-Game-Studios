# Bevy Navigation — Quick Reference

Last verified: 2026-11-02 | Engine: Bevy 0.20.1

## Bevy Ships No Pathfinding

No 0.20.1 crate provides navmeshes, pathfinding or steering: there is no
navigation plugin in `DefaultPlugins`
(`bevy_internal-0.20.1/src/default_plugins.rs:5-104`). It comes from a crate,
chosen per project (a dependency decision for `technical-director`).

| Crate | Version for Bevy 0.20 | Approach |
|-------|-----------------------|----------|
| `vleue_navigator` | 0.17.0 | Navmesh (2D and 3D) |
| `bevy_northstar` | 0.8.0 | Grid pathfinding |

`oxidized_navigation` has no release for Bevy newer than 0.15 (2026-11-02).
Versions and repositories: `PLUGINS.md`. Read the crate's docs.rs page for its
API; it is not documented here.

## Not Pathfinding: UI Directional Navigation

`bevy_input_focus` and `bevy_ui` have **directional navigation**, which moves
UI focus between widgets with a gamepad or arrow keys:
`AutoDirectionalNavigation` on focusable nodes (`bevy_ui-0.20.1/src/auto_directional_navigation.rs:107`),
`DirectionalNavigationMap::add_edge` for explicit edges
(`bevy_input_focus-0.20.1/src/directional_navigation.rs:254`, `:315`). It has nothing to
do with moving agents through a level.

## Writing Your Own

A grid or graph search over game data is plain Rust in a system; keep the
search out of the per-frame path (run it when the goal changes, or spread it
over frames with an async task). `bevy::shape` ray casts and `MeshRayCast`
(see `modules/physics.md`) cover line-of-sight checks.

## Common Mistakes
- Suggesting a `NavigationAgent`- or `NavMesh`-style built-in (Bevy has none)
- Using a navigation crate version built for an older Bevy
- Confusing UI directional navigation with agent pathfinding
