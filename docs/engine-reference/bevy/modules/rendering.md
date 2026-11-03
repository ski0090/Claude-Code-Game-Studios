# Bevy Rendering — Quick Reference

Last verified: 2026-11-02 | Engine: Bevy 0.20.1

## What Changed Since ~0.15 (LLM Cutoff)

### 0.20 Changes
- **Shaders are WESL** (`.wesl`, `import a::b;`, `@if`); naga_oil and GLSL are
  gone. Rules and an example: `current-best-practices.md` § Shaders
- **`ScreenSpaceTransmission` is opt-in**: `Camera3d` no longer adds it; add it
  to the camera for transmissive materials (`bevy_pbr-0.20.1/src/transmission/mod.rs:63`)
- **`Tonemapping::None` is a raw passthrough**; `Tonemapping::Linear` is "no
  curve". `Camera2d` defaults to `Linear`; `Camera3d` requires `Tonemapping`,
  whose default is `TonyMcMapface` (`bevy_render-0.20.1/src/view/mod.rs:283-327`)
- **Sprites render as `Mesh2d` + `Material2d`**; `SpriteMaterial<M>` puts a custom
  material on a sprite (`bevy_sprite_render-0.20.1/src/sprite_mesh/sprite_extended_material.rs:218`)
- OIT material gate is `MATERIAL_OIT_ENABLED`; opt out with `Material::enable_oit()`

### 0.19 Changes
- Render graph replaced by systems in the `Core3d` / `Core2d` schedules
- `shadows_enabled` → `shadow_maps_enabled`; new `contact_shadows_enabled`
- `Skybox` → `bevy::light::Skybox` with `image: Option<Handle<Image>>`;
  `Atmosphere` is its own entity in `bevy::light`
- `Vignette`, `LensDistortion` post effects (`bevy::post_process`)
- `ShaderStorageBuffer` → `ShaderBuffer`; bloom luma in linear space (dimmer)

### 0.18 Changes
- `RenderTarget` is a component, not `Camera::target`
- `AmbientLight` resource → `GlobalAmbientLight`; `AmbientLight` is per-camera
- `Material::enable_prepass()` / `enable_shadows()` replace `MaterialPlugin` fields

### 0.17 Changes
- `bevy_render` split: `bevy::camera`, `bevy::light`, `bevy::mesh`, `bevy::image`,
  `bevy::shader`, `bevy::post_process`, `bevy::anti_alias`
- `Camera { hdr: true }` → `Hdr` component (`bevy_camera-0.20.1/src/components.rs:89`);
  `Bloom` requires it

## Default Render Method

Opaque materials render **forward** by default. `DefaultOpaqueRendererMethod`
defaults to `OpaqueRendererMethod::Forward` (`bevy_pbr-0.20.1/src/material.rs:1462-1466`;
`#[default] Forward` at `bevy_material-0.20.1/src/opaque.rs:24-25`).
`StandardMaterial` uses `Auto`, which follows that resource
(`bevy_pbr-0.20.1/src/pbr_material.rs:943`); a custom `Material` returns
`Forward` unless it overrides `opaque_render_method` (`material.rs:170-172`).
Deferred is opt-in: insert `DefaultOpaqueRendererMethod::deferred()` and add
`DeferredPrepass` and `DepthPrepass` to the `Camera3d`
(`bevy_core_pipeline-0.20.1/src/prepass/mod.rs:81-85`). Deferred gives up MSAA
(`bevy_material-0.20.1/src/opaque.rs:13-18`).

## Current API Patterns

### 3D scene
```rust
use bevy::{camera::Hdr, prelude::*}; // `Hdr` is not in the prelude

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    commands.spawn((
        Mesh3d(meshes.add(Cuboid::default())),
        MeshMaterial3d(materials.add(StandardMaterial::default())),
        Transform::from_xyz(0.0, 0.5, 0.0),
    ));
    commands.spawn((
        DirectionalLight { shadow_maps_enabled: true, ..default() },
        Transform::from_xyz(4.0, 8.0, 4.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));
    commands.spawn((
        Camera3d::default(),
        Hdr, // needed by Bloom
        Transform::from_xyz(-2.0, 2.5, 5.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));
}
```

### Custom material (Rust side of the WESL example)
```rust
use bevy::{prelude::*, render::render_resource::AsBindGroup, shader::ShaderRef};

#[derive(Asset, TypePath, AsBindGroup, Debug, Clone)]
struct CustomMaterial {
    #[uniform(0)]
    color: LinearRgba,
}

impl Material for CustomMaterial {
    fn fragment_shader() -> ShaderRef {
        "shaders/custom_material.wesl".into()
    }
}
// app.add_plugins(MaterialPlugin::<CustomMaterial>::default());
```
From `bevy-0.20.1/examples/shader/shader_material.rs:4-58`. 2D: `Material2d` +
`MeshMaterial2d` (`bevy_sprite_render-0.20.1/src/mesh2d/material.rs:148`, `:217`).

### Screenshot
`commands.spawn(Screenshot::primary_window()).observe(save_to_disk(path))`
(`bevy::render::view::screenshot`). The CCGS capture plugin is in
`.claude/docs/run-and-observe.md` § "Bevy 0.20 — one plugin".

## Common Mistakes
- Writing `.wgsl` with `#import` (naga_oil is gone) or `@group(2)` for material bindings
- Expecting deferred by default (forward is the default)
- Missing `ScreenSpaceTransmission` on a camera that shows glass or water (0.20)
- `Tonemapping::None` to mean "no curve" (use `Linear`)
- `Camera { hdr: true }`, `Camera { target }`, `AmbientLight` as a resource (all gone)
- Writing a render-graph `ViewNode` for post-processing (systems since 0.19)
