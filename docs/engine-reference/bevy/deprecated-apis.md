# Bevy — Deprecated APIs

Last verified: 2026-11-02 | Engine: Bevy 0.20.1

If an agent suggests any API in the "Don't use" column, it MUST be replaced with
the "Use instead" column. Most rows are **removed**, not deprecated: Bevy renames
without a deprecation period more often than with one, so the old name fails to
compile. Rows marked *(deprecated)* still compile with a warning in 0.20.1. Every
"Use instead" name was checked in the 0.20.1 source; the version is the release
that made the change (see `breaking-changes.md`).

## ECS, Events and Observers

| Don't use | Use instead | Since | Notes |
|-----------|-------------|-------|-------|
| `EventReader<E>` / `EventWriter<E>` / `Events<E>` | `MessageReader<M>` / `MessageWriter<M>` / `Messages<M>` | 0.17 | Buffered "events" are messages |
| `#[derive(Event)]` for a buffered event | `#[derive(Message)]` | 0.17 | `#[derive(Event)]` now means an observer event |
| `app.add_event::<E>()` | `app.add_message::<M>()` | 0.17 | |
| `writer.send(e)`, `world.send_event(e)`, `commands.send_event(e)` | `writer.write(m)`, `world.write_message(m)`, `commands.write_message(m)` | 0.17 | |
| `Trigger<E>` (observer parameter) | `On<E>` | 0.17 | `On` derefs to the event |
| `OnAdd`, `OnInsert`, `OnRemove`, `OnDespawn` | `Add`, `Insert`, `Remove`, `Despawn` | 0.17 | Written `On<Add<T>>` since 0.20 |
| `OnReplace` / `Replace`, `on_replace` | `Discard`, `on_discard` | 0.19 | |
| `On<Add, T>` | `On<Add<T>>` | 0.20 | Same for every lifecycle event |
| `trigger.target()` | `ev.entity`, or `ev.event_target()` | 0.17 | |
| `world.trigger_targets(ev, entity)` | `world.trigger(Ev { entity })` / `commands.trigger(..)` | 0.17 | The target lives in the event |
| `#[event(traversal = .., auto_propagate)]` | `#[entity_event(propagate)]` | 0.17 | |
| `DefaultErrorHandler` | `FallbackErrorHandler` | 0.19 | |
| `GLOBAL_ERROR_HANDLER` | `App::set_error_handler` | 0.17 | |
| `Condition` | `SystemCondition` | 0.17 | |
| `init_non_send_resource`, `non_send_resource_mut` | `init_non_send`, `non_send_mut` | 0.19 | |
| `clear_children`, `remove_children`, `remove_child` | `detach_all_children`, `detach_children`, `detach_child` | 0.18 | |
| `EntityRow`, `Entity::row()`, `Entity::from_row` | `EntityIndex`, `Entity::index()`, `Entity::from_index` | 0.18 | |
| `FilteredResources` *(deprecated)* | `QueryParamBuilder` + `Query<FilteredEntityRef>` | 0.20 | |
| `DeferredWorld::query` *(deprecated)* | `QueryState::query_mut` | 0.20 | |

## States, Time and Schedules

| Don't use | Use instead | Since | Notes |
|-----------|-------------|-------|-------|
| `StateScoped(S)` | `DespawnOnExit(S)` / `DespawnOnEnter(S)` | 0.17 | Always enabled; no `enable_state_scoped_entities` |
| `NextState::set_if_neq`, `set_state_if_neq` | `NextState::set_if_different`, `set_state_if_different` | 0.20 | No deprecated wrapper in 0.20.1 |
| `add_state_scoped_event` | `add_message` + `clear_messages_on_exit` | 0.17 | |
| `timer.finished()`, `timer.paused()` | `timer.is_finished()`, `timer.is_paused()` | 0.17 | |
| `TransformSystem`, `UiSystem`, `InputSystem`, `RenderSet` | `TransformSystems`, `UiSystems`, `InputSystems`, `RenderSystems` | 0.17 | Every built-in set ends in `Systems` |
| `SimpleExecutor`, `set_executor_kind` | `SingleThreadedExecutor`, `set_executor` | 0.18 / 0.19 | |

## Scenes and Assets

| Don't use | Use instead | Since | Notes |
|-----------|-------------|-------|-------|
| `SceneRoot` | `WorldAssetRoot` | 0.19 | glTF scenes: `WorldAssetRoot(asset_server.load(GltfAssetLabel::Scene(0).from_asset(path)))` |
| `DynamicScene`, `DynamicSceneRoot`, `DynamicSceneBuilder` | `DynamicWorld`, `DynamicWorldRoot`, `DynamicWorldBuilder` | 0.19 | In `bevy::world_serialization` |
| `SceneSpawner`, `SceneInstanceReady` | `WorldInstanceSpawner`, `WorldInstanceReady` | 0.19 | |
| `bevy::scene::ScenePlugin` meaning RON scenes | `bevy::world_serialization::WorldSerializationPlugin` | 0.19 | `bevy::scene` is now BSN |
| `asset_server.load_with_settings(..)`, `load_untyped(..)` | `asset_server.load_builder().with_settings(..).load(..)` / `.load_untyped(..)` | 0.19 | Old methods removed in 0.20.1 |
| `Handle::Weak`, `weak_handle!`, `clone_weak()` | `Handle::Uuid`, `uuid_handle!`, `clone()` | 0.17 | `weak_handle!` still exists *(deprecated)* |
| `"x.glb#Material0"` as a `StandardMaterial` | `"x.glb#Material0/std"` | 0.19 | `#Material0` is a `GltfMaterial` |
| `bevy::asset::ron`, `bevy::scene::ron` | the `ron` crate as a direct dependency | 0.18 | |
| `AssetId::invalid()` *(deprecated)* | `Option<AssetId<T>>` | 0.20 | |

## Rendering and Shaders

| Don't use | Use instead | Since | Notes |
|-----------|-------------|-------|-------|
| `#import bevy_pbr::forward_io::VertexOutput` in a `.wgsl` | `import bevy_pbr::render::forward_io::VertexOutput;` in a `.wesl` | 0.20 | naga_oil is gone |
| `#ifdef DEF` … `#endif`, `#{DEF}` | `@if(DEF)`, `constants::DEF` | 0.20 | |
| `@group(2)` for material bindings | `@group(constants::MATERIAL_BIND_GROUP)` | 0.20 | Bevy's own `.wesl` files use the constant |
| GLSL shaders, `shader_format_glsl`, `shader_format_wesl` | WESL (always on) | 0.20 | SPIR-V passthrough unchanged |
| `Camera { hdr: true }` | `Hdr` component | 0.17 | |
| `Camera { target }` | `RenderTarget` component | 0.18 | |
| `AmbientLight` as a resource | `GlobalAmbientLight` | 0.18 | `AmbientLight` is a per-camera component |
| `shadows_enabled` on lights | `shadow_maps_enabled` | 0.19 | |
| `bevy::core_pipeline::Skybox` | `bevy::light::Skybox` (`image: Some(h)`) | 0.19 | |
| `Tonemapping::None` for "no tonemapping curve" | `Tonemapping::Linear` | 0.20 | `None` is a raw passthrough |
| `ShaderStorageBuffer` | `ShaderBuffer` | 0.19 | |
| `ViewNode`, `add_render_graph_node` | systems in the `Core3d` / `Core2d` schedules | 0.19 | |
| `gizmos.cuboid(..)` | `gizmos.cube(..)` | 0.18 | |
| `Atmosphere::earthlike` | `Atmosphere::earth` | 0.19 | |

## UI, Text, Input and Picking

| Don't use | Use instead | Since | Notes |
|-----------|-------------|-------|-------|
| `Button` (from `bevy::ui`) *(deprecated)* | `bevy::ui_widgets::Button` + an `On<Activate>` observer | 0.20 | Not in the prelude |
| `Interaction` *(deprecated)* | `bevy::picking::hover::Hovered` + `bevy::ui::Pressed` | 0.20 | `Hovered` is immutable |
| `BorderRadius` component | `Node { border_radius, .. }` | 0.18 | Corners are `CornerRadius` since 0.20 |
| `BorderColor(c)` | `BorderColor::all(c)` | 0.17 | |
| `TextFont { font: handle, font_size: 20.0, line_height }` | `font: handle.into()` (`FontSource`), `font_size: FontSize::Px(20.0)`, `LineHeight` component | 0.18 / 0.19 | |
| `FontSource::SansSerif` | `FontSource::sans_serif()` | 0.20 | |
| `JustifyText` | `Justify` | 0.17 | |
| `Transform` on UI nodes | `UiTransform` | 0.17 | |
| `Pointer<Click>`, `Pointer<Press>`, `Pointer<Over>` | `PointerClick`, `PointerPress`, `PointerOver` | 0.20 | `ev.pointer.id`, `ev.pointer.position` |
| `Anchor::BottomLeft` field on `Sprite` | `Anchor::BOTTOM_LEFT` component | 0.17 | |
| `Window { cursor_options }` | `CursorOptions` component | 0.17 | |

## Cargo Features

| Don't use | Use instead | Since |
|-----------|-------------|-------|
| `animation` | `gltf_animation` | 0.18 |
| `bevy_sprite_picking_backend`, `bevy_ui_picking_backend`, `bevy_mesh_picking_backend` | `sprite_picking`, `ui_picking`, `mesh_picking` | 0.18 |
| `experimental_bevy_ui_widgets`, `experimental_bevy_feathers` | `bevy_ui_widgets`, `bevy_feathers` | 0.19 |
| `shader_format_wesl`, `shader_format_glsl` | — (WESL is always on) | 0.20 |

## Patterns (Not Just APIs)

| Deprecated Pattern | Use Instead | Why |
|--------------------|-------------|-----|
| One `#[derive(Event)]` type read with an `EventReader` | `Message` for pull-based batches, `Event` / `EntityEvent` + observers for push-based reactions | 0.17 split them (`bevy_ecs-0.20.1/src/message/mod.rs:100`) |
| Game logic in `src/main.rs` | Plugins in the library crate (`src/lib.rs`), `main.rs` only builds the `App` | Integration tests link only the library's pub API |
| Spawning `UiWidgetsPlugins` or `InputDispatchPlugin` yourself | Rely on `DefaultPlugins` | Adding them twice panics since 0.19 |
| `Query<Entity>` meaning "all game entities" | Add `Without<IsResource>` (or a marker) | Resources are entities since 0.19 |
| naga_oil `.wgsl` with `#import` | `.wesl` | 0.20 dropped the preprocessor |
