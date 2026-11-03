# Bevy — Breaking Changes

Last verified: 2026-11-02 | Engine: Bevy 0.20.1

Changes between Bevy versions, focused on post-cutoff releases (0.17+). Every
0.x minor is breaking. Rows are sorted by risk: **HIGH** = common game code
stops compiling or silently behaves differently; **MED** = a compile break in
less common APIs; **LOW** = rare or internal. Names in the right-hand column are
the **0.20.1** names: many 0.17–0.19 names were renamed again later, and the row
says so. Each was checked in the 0.20.1 crates' source.

## 0.19 → 0.20 (Oct 2026 — POST-CUTOFF, HIGH RISK)

| Risk | Subsystem | Before → 0.20.1 | Details |
|------|-----------|-----------------|---------|
| HIGH | Shaders | naga_oil `.wgsl` (`#import`, `#ifdef`, `#{DEF}`) → WESL `.wesl` (`import a::b;`, `@if(DEF)`, `constants::DEF`) | naga_oil and GLSL are gone; plain WGSL with no preprocessor directives still loads. Module paths now include the crate folder: `bevy_pbr::forward_io` → `bevy_pbr::render::forward_io`, `bevy_pbr::prepass_utils` → `bevy_pbr::prepass::utils`. `#define_import_path` is gone. See `current-best-practices.md` § Shaders |
| HIGH | Observers | `On<Add, Player>` → `On<Add<Player>>` | Same for `Insert`, `Discard`, `Remove`, `Despawn`. Untyped `On<Add>` → `On<Add<()>>`. `Add<(A, B)>` matches A **or** B. The payload is `AddEvent { entity }` (`bevy_ecs-0.20.1/src/lifecycle.rs:339`, `:352`) |
| HIGH | Picking | `On<Pointer<Click>>` → `On<PointerClick>` | Every pointer event is a flat type: `PointerPress`, `PointerRelease`, `PointerClick`, `PointerMove`, `PointerOver`, `PointerOut`, `PointerDragStart`, `PointerDrag`, `PointerDragEnd`, `PointerDragEnter`, `PointerDragOver`, `PointerDragLeave`, `PointerDragDrop`, `PointerScroll`, `PointerCancel`. `ev.pointer_id` → `ev.pointer.id`; position is `ev.pointer.position` (`bevy_picking-0.20.1/src/events.rs:74`, `:353`) |
| HIGH | Queries | `iter_many*` / `par_iter_many*` yield `Item` → `Result<Item, QueryEntityError>` | Add `.matched()` for the old behaviour (`bevy_ecs-0.20.1/src/query/iter.rs:1620`) |
| HIGH | Scenes (BSN) | scene references gain `@`: `scene_fn()` → `@scene_fn()`, a scene expression `{s}` → `@{s}`; `template_value(x)` → `x`; entities in a list separated by `--` | Field values keep plain `{expr}`. Commas, `( )` groups and `bsn![..]` still compile with deprecation warnings. `VariantDefaults` removed. Treat 0.19 BSN snippets as 0.19-only |
| HIGH | 3D render (silent) | `Camera3d` added `ScreenSpaceTransmission` → you add it | Transmissive materials render differently until the camera has `ScreenSpaceTransmission` (`bevy_pbr-0.20.1/src/transmission/mod.rs:63`) |
| HIGH | Render (silent) | `Tonemapping::None` = no curve → `Tonemapping::Linear` | `None` is now a full passthrough (no grading, dither or clamp). `Camera2d` defaults to `Linear` (`bevy_render-0.20.1/src/view/mod.rs:283`) |
| HIGH | Sprites (silent) | sprite renderer → `Mesh2d` + `Material2d` backend | Sprites on the same Z may draw in another order. New field `Sprite::alpha_mode` breaks struct literals without `..default()` |
| MED | UI | `bevy::ui::widget::Button` + `Interaction` → `bevy::ui_widgets::Button` + `On<Activate>`; `Hovered` + `Pressed` for looks | Old names are `#[deprecated]` aliases and still in the prelude; the new ones are **not** in the prelude (`bevy_ui-0.20.1/src/widget/button.rs:24-30`, `focus.rs:61-65`) |
| MED | States | `NextState::set_if_neq` → `set_if_different`; `set_state_if_neq` → `set_state_if_different` | The guide promises deprecated wrappers; 0.20.1 has none (`bevy_state-0.20.1/src/state/resources.rs:206`) |
| MED | Text / UI units | `TextFont::default()` size `FontSize::Px(20.)` → `FontSize::Rem(1.)`; new `Val::Em` / `Val::Rem` | Looks the same until `RemSize` changes. `Val::resolve` takes `EmSize` and `RemSize` (`bevy_text-0.20.1/src/text.rs:762`) |
| MED | UI | `BorderRadius` fields `Val` → `CornerRadius` | Use `CornerRadius::circular(v)` or `.into()` |
| MED | Text | `FontSource::SansSerif` → `FontSource::sans_serif()`; `TextInput` (in `bevy_ui_widgets`) is the input widget, `EditableText` its text | `TextInput` requires `EditableText` |
| MED | ECS | `Name::from(&str)` → `&'static str` only | `Name::new(s.to_owned())` for other strings |
| MED | ECS | `&mut World` may be any system parameter | `ExclusiveFunctionSystem`, `ExclusiveSystemParam`, `ExclusiveMarker` removed |
| MED | Scheduling | Built-in sets `.chain()` → `.chain_weak()` | Breaks only ordering not visible as ECS access (channels, atomics); add `.after(..)` |
| MED | Math | `bevy_math::primitives` → `bevy::shape`; curves and splines → `bevy::curve` | Prelude users are unaffected |
| MED | Shaders | material gate `OIT_ENABLED` → `MATERIAL_OIT_ENABLED` | Opt out per material with `fn enable_oit() -> bool` (`bevy_pbr-0.20.1/src/material.rs:208`) |
| MED | Reflection | `Tonemapping`, `DebandDither` type paths → `bevy_render::view` | Rust imports resolve; reflected paths in `.scn.ron` files and BRP keys change |
| MED | Picking | `bevy_feathers::cursor` → `bevy_picking::cursor` | |
| LOW | Assets | `AssetId::invalid()` deprecated → `Option<AssetId<T>>` | |
| LOW | Mesh | `MeshTag(x)` → `MeshTag::new(x)` | |
| LOW | Reflection | `FromType` → `CreateTypeData`; `to_dynamic*()` return `Result` | |
| LOW | Render internals | `DepthAttachment` → `DepthStencilViewAttachment`; `UnpreparedBindGroup` → `BindGroupBuilder`; extraction moved to `bevy_extract` | UI rendering is retained (site-only section "UI rendering is now retained") |

0.20.1 (Oct 28, 2026) is a fix-only patch: nine commits, no API changes
(https://github.com/bevyengine/bevy/releases).

## 0.18 → 0.19 (Jun 2026 — POST-CUTOFF, HIGH RISK)

| Risk | Subsystem | Before → 0.20.1 | Details |
|------|-----------|-----------------|---------|
| HIGH | Scenes | old `bevy_scene` → `bevy_world_serialization` (`bevy::world_serialization`) | `Scene` → `WorldAsset`, `SceneRoot` → `WorldAssetRoot`, `DynamicScene` → `DynamicWorld`, `DynamicSceneRoot` → `DynamicWorldRoot`, `DynamicSceneBuilder` → `DynamicWorldBuilder`, `SceneSpawner` → `WorldInstanceSpawner`, `SceneInstanceReady` → `WorldInstanceReady`, `ScenePlugin` → `WorldSerializationPlugin`. `bevy::scene` is now the BSN crate. `.scn` / `.scn.ron` still load, as `DynamicWorld` |
| HIGH | ECS | resources are components | `Query<Entity>`, `Query<EntityMut>`, `Query<()>` now also match resource entities; filter with `Without<IsResource>`. `trait Resource: Component` (`bevy_ecs-0.20.1/src/resource.rs:87`, `:124`) |
| HIGH | Lifecycle | `Replace` / `on_replace` → `Discard` / `on_discard` | `DiscardEvent` runs before the old value is replaced (`bevy_ecs-0.20.1/src/lifecycle.rs:410`) |
| HIGH | States (silent) | `NextState::set(same)` now also fires `DespawnOnEnter` / `DespawnOnExit` | Use `set_if_different` to skip a same-state transition |
| HIGH | Plugins | remove `UiWidgetsPlugins` and `InputDispatchPlugin` from `add_plugins` | Both are in `DefaultPlugins`; adding them again panics |
| HIGH | Cargo | `2d` / `3d` no longer imply `ui`; none imply `audio` | `default = ["2d", "3d", "ui", "audio"]`; with `default-features = false`, list `ui` and `audio` yourself (`bevy-0.20.1/Cargo.toml:2867`) |
| HIGH | Assets | `load_with_settings`, `load_untyped`, `load_acquire`, … → `asset_server.load_builder()` | `.with_settings(f)`, `.with_guard(g)`, then `.load(path)` / `.load_untyped(path)`. The old methods are gone in 0.20.1 (`bevy_asset-0.20.1/src/server/mod.rs:371`) |
| HIGH | glTF (silent) | `"x.glb#Material0"` was `Handle<StandardMaterial>` → now `Handle<GltfMaterial>` | Use `"x.glb#Material0/std"` for a `StandardMaterial`. A wrong handle type compiles and fails at load |
| HIGH | Text | `TextFont { font: Handle<Font>, font_size: f32 }` → `font: FontSource`, `font_size: FontSize` | `handle.into()` and `FontSize::Px(v)`; new `weight`, `width`, `style` |
| HIGH | Lights | `shadows_enabled` → `shadow_maps_enabled` | On point, spot and directional lights; new `contact_shadows_enabled` |
| HIGH | Skybox | `bevy::core_pipeline::Skybox` → `bevy::light::Skybox`; `image: h` → `image: Some(h)` | |
| MED | ECS | `init_non_send_resource`, `non_send_resource_mut`, … → `init_non_send`, `non_send_mut`, … | Old names gone in 0.20.1 |
| MED | Commands | `impl Command<Result> for X` → `impl Command for X { type Out = Result; }` | |
| MED | Errors | `DefaultErrorHandler` → `FallbackErrorHandler` | `bevy_ecs-0.20.1/src/error/handler.rs:117` |
| MED | ECS | `SystemState::get` / `get_mut` return `Result` | `Ref<T>` is now `Copy`, so `r.clone()` clones the `Ref` |
| MED | Assets | `Assets::get_mut` → `Option<AssetMut<A>>` | `AssetEvent::Modified` fires only on a real mutable access |
| MED | Text | layout on Parley (was cosmic-text); `Font::try_from_bytes` → `Font::from_bytes(data)` | System fonts by name need the `system_font_discovery` feature |
| MED | Rendering | `Hdr` → `bevy::camera::Hdr`; `AlphaMode`, `OpaqueRendererMethod` → `bevy_material` | |
| MED | Rendering | render graph (`ViewNode`, `add_render_graph_node`) → systems in `Core3d` / `Core2d` schedules | Custom post-processing is rewritten |
| MED | Rendering | `ShaderStorageBuffer` → `ShaderBuffer`; bloom luma in linear space (looks dimmer) | |
| MED | Atmosphere | `Atmosphere` is its own entity in `bevy::light`; `earthlike` → `earth`; `bottom_radius` / `top_radius` → `inner_radius` / `outer_radius` | |
| MED | Animation | `MeshMorphWeights { weights }` → enum `Value { weights }` / `Reference(Entity)` | `MorphPlugin` removed |
| MED | Input focus | `input_focus.0` → `get()`, `set(entity, cause)`, `clear()` | `set` takes a `FocusCause` (`bevy_input_focus-0.20.1/src/lib.rs:145`) |
| MED | Audio | rodio 0.22; format features `vorbis` (default), `wav`, `mp3`, `flac`, `aac`, `audio-all-formats` | |
| MED | Tasks (web) | dropping a `Task` on wasm cancels it | `.detach()` to keep it running |
| LOW | Schedules | `set_executor_kind(..)` → `set_executor(..)` | |

## 0.17 → 0.18 (Jan 2026 — POST-CUTOFF, HIGH RISK)

| Risk | Subsystem | Before → 0.20.1 | Details |
|------|-----------|-----------------|---------|
| HIGH | States (silent) | `NextState::set(same)` was skipped → always runs `OnExit` / `OnEnter` | To skip, use `set_if_different` (0.18 called it `set_if_neq`) |
| HIGH | Run conditions (silent) | a combinator over an invalid system errored → counts as `false` | `a.or(b)` can be true when `a` is invalid |
| HIGH | Camera | `Camera { target: .. }` → `RenderTarget` component | `bevy_camera-0.20.1/src/camera.rs:893` |
| HIGH | Lighting | `AmbientLight` resource → `GlobalAmbientLight` | `AmbientLight` is now a per-camera component (`bevy_light-0.20.1/src/ambient_light.rs:12`, `:62`) |
| HIGH | UI | `BorderRadius` component → `Node { border_radius, .. }` | |
| HIGH | Text | `TextFont::line_height` → `LineHeight` component | |
| HIGH | Hierarchy | `clear_children` / `remove_children` / `remove_child` / `clear_related` → `detach_all_children` / `detach_children` / `detach_child` / `detach_all_related` | Detach only; nothing is despawned |
| HIGH | Cargo | `animation` → `gltf_animation`; `bevy_*_picking_backend` → `sprite_picking`, `ui_picking`, `mesh_picking` | Feature collections arrive (`2d`, `3d`, `ui`, …); see `current-best-practices.md` § Cargo Features for the 0.20 set |
| HIGH | Mesh | `mesh.attribute()`, `indices()`, … → `try_*` variants returning `Result` | The old calls panic on render-world-only meshes |
| MED | Cargo / Input | `default-features = false` builds need `keyboard`, `mouse`, `gamepad`, `touch`, `gestures` | Input sources silently disappear without them |
| MED | Animation | `AnimationTarget { id, player }` → `AnimationTargetId` + `AnimatedBy` | |
| MED | Materials | `MaterialPlugin { prepass_enabled, shadows_enabled }` → `Material::enable_prepass()` / `enable_shadows()` | |
| MED | Gizmos | `gizmos.cuboid(..)` → `gizmos.cube(..)` | |
| MED | Picking (silent) | `DragEnter` also fires when a drag starts over a hovered entity | Now `PointerDragEnter` |
| MED | ECS | `Entity::row()` / `EntityRow` → `Entity::index()` / `EntityIndex`; old `index() -> u32` → `index_u32()` | |
| MED | Assets | custom `AssetLoader`, `AssetSaver`, `AssetTransformer` need `TypePath` | `#[derive(TypePath)]` |
| MED | Assets | `bevy::asset::ron` / `bevy::scene::ron` re-exports removed | Depend on `ron` directly |
| LOW | Scheduling | `SimpleExecutor` → `SingleThreadedExecutor` | |

## 0.16 → 0.17 (Sep 2025 — POST-CUTOFF, HIGH RISK)

| Risk | Subsystem | Before → 0.20.1 | Details |
|------|-----------|-----------------|---------|
| HIGH | ECS messages | `#[derive(Event)]` + `EventReader` / `EventWriter` / `Events` → `#[derive(Message)]` + `MessageReader` / `MessageWriter` / `Messages` | `writer.send(e)` → `writer.write(m)`; `world.send_event` → `world.write_message`; `app.add_event` → `app.add_message` (`bevy_app-0.20.1/src/app.rs:427`) |
| HIGH | ECS events | `Event` now means an observer event; targeted ones derive `EntityEvent` with an `entity: Entity` field (or `#[event_target]`) | `bevy_ecs-0.20.1/src/event/mod.rs:89`, `:369` |
| HIGH | Observers | `Trigger<E>` parameter → `On<E>` | `On` derefs to the event. `Trigger` is now an unrelated trait |
| HIGH | Observers | `OnAdd` / `OnInsert` / `OnReplace` / `OnRemove` / `OnDespawn` → `Add` / `Insert` / `Discard` / `Remove` / `Despawn` in `bevy_ecs::lifecycle` | Written `On<Add<T>>` in 0.20 |
| HIGH | Observers | `trigger.target()` → `ev.entity` (or `ev.event_target()`); `world.trigger_targets(e, id)` → `world.trigger(E { entity: id })` | `#[event(traversal, auto_propagate)]` → `#[entity_event(propagate)]` |
| HIGH | Rendering | `bevy::render::{camera, view, primitives}` → `bevy::camera`; lights → `bevy::light`; meshes → `bevy::mesh`; `Image` → `bevy::image`; `Shader` → `bevy::shader` | Prelude-only code is unaffected |
| HIGH | Rendering | `Material2d`, `ColorMaterial` → `bevy_sprite_render`; `UiMaterial` → `bevy_ui_render`; `Bloom` → `bevy::post_process`; TAA/FXAA/SMAA → `bevy::anti_alias` | |
| HIGH | Camera | `Camera { hdr: true }` → `Hdr` component | `bevy_camera-0.20.1/src/components.rs:89` |
| HIGH | States | `StateScoped(S)` → `DespawnOnExit(S)` (also `DespawnOnEnter`) | Always enabled; `enable_state_scoped_entities` is gone |
| HIGH | UI (silent) | UI nodes use `UiTransform` / `UiGlobalTransform`, not `Transform` | `Query<&Transform, With<Node>>` matches nothing |
| HIGH | UI | `BorderColor(c)` → `BorderColor::all(c)` | |
| HIGH | Sprite | `Sprite { anchor: Anchor::BottomLeft }` → `Anchor::BOTTOM_LEFT` component | |
| HIGH | Time | `timer.finished()` / `paused()` → `is_finished()` / `is_paused()` | |
| HIGH | ECS (silent) | `Option<Single<D>>` skipped the system on several matches → now `None` | |
| MED | Queries (silent) | `Query<EntityRef>` and `Option<&Disabled>` no longer see disabled entities | Add `Allow<Disabled>` |
| MED | Schedules | system sets renamed `*Systems`: `TransformSystem` → `TransformSystems`, `UiSystem` → `UiSystems`, `InputSystem` → `InputSystems`, `RenderSet` → `RenderSystems`, … | `Condition` → `SystemCondition` |
| MED | Assets | `Handle::Weak`, `weak_handle!`, `clone_weak()` → `Handle::Uuid`, `uuid_handle!`, `clone()` | |
| MED | Window | `Window::cursor_options` → `CursorOptions` component | `WindowResolution::new` takes `u32` |
| MED | Text | `JustifyText` → `Justify`; `Text2d` → `bevy_sprite` | |
| MED | Errors | `GLOBAL_ERROR_HANDLER` → `App::set_error_handler` | |
| LOW | Transform | `compute_matrix()` → `to_matrix()` | |

## Sources

- 0.19 → 0.20: https://bevy.org/learn/migration-guides/0-19-to-0-20/ (drafts also in
  the `bevy` 0.20.1 crate, `_release-content/migration-guides/`)
- 0.18 → 0.19: https://bevy.org/learn/migration-guides/0-18-to-0-19/ (drafts in the
  `bevy` 0.19.1 crate, `_release-content/migration-guides/`)
- 0.17 → 0.18: https://bevy.org/learn/migration-guides/0-17-to-0-18/
- 0.16 → 0.17: https://bevy.org/learn/migration-guides/0-16-to-0-17/
- Release notes: https://bevy.org/news/bevy-0-17/ … https://bevy.org/news/bevy-0-20/
- Where a guide and the 0.20.1 source disagree (the `set_if_neq` wrappers, `TextLayoutItem`,
  `UiDebugOverlay`), the source wins and the row follows it.
