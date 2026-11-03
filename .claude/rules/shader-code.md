---
paths:
  - "assets/shaders/**"
  - "**/*.gdshader"
  - "Assets/**/*.{shader,hlsl,cginc,compute,shadergraph}"
  - "Shaders/**"
  - "**/*.{usf,ush}"
  - "**/*.{wgsl,wesl}"
---

# Shader Code Standards

All shader files, in every engine, must follow these standards to maintain
visual quality, performance, and cross-platform compatibility.

## Naming Conventions
- File naming: `[type]_[category]_[name].[ext]`
  - `spatial_env_water.gdshader` (Godot)
  - `SG_Env_Water` (Unity Shader Graph)
  - `M_Env_Water` (Unreal Material)
  - `mat_env_water.wesl` (Bevy)
- Use descriptive names that indicate the material purpose
- Prefix with the engine's shader type — Godot `spatial_`, `canvas_`, `particles_`,
  `post_`; Unity `SG_` (Shader Graph); Unreal `M_`, `MI_` (instance), `MF_` (function);
  Bevy `mat_` (3D `Material`), `mat2d_` (`Material2d`), `post_` (fullscreen), `cs_` (compute)
- Bevy 0.20: write `.wesl` (WESL) under `assets/shaders/`. A `.wgsl` file still
  loads, but as plain WGSL with no `import` and no shader defs, so it cannot use
  Bevy's shader modules (`docs/engine-reference/bevy/current-best-practices.md` § Shaders)

## Code Quality
- All uniforms/parameters must have descriptive names and appropriate hints
- Group related parameters (Godot: `group_uniforms`, Unity: `[Header]`, Unreal: Category,
  Bevy: one uniform struct per material, bound through `AsBindGroup`)
- Comment non-obvious calculations (especially math-heavy sections)
- No magic numbers — use named constants or documented uniform values
- Include authorship and purpose comment at the top of each shader file

## Performance Requirements
- Document the target platform and complexity budget for each shader
- Use appropriate precision: `half`/`mediump` on mobile where full precision isn't needed
- Minimize texture samples in fragment shaders
- Avoid dynamic branching in fragment shaders — use `step()`, `smoothstep()` and
  `mix()` (Godot, GLSL, Bevy WGSL/WESL) or `lerp()` (HLSL: Unity, Unreal)
- No texture reads inside loops
- Two-pass approach for blur effects (horizontal then vertical)

## Cross-Platform
- Test shaders on minimum spec target hardware
- Provide fallback/simplified versions for lower quality tiers
- Document which render pipeline the shader targets (Forward/Deferred, URP/HDRP, Forward+/Mobile/Compatibility;
  Bevy renders opaque materials forward unless the project opts into deferred)
- Do not mix shaders from different render pipelines in the same directory

## Variant Management
- Minimize shader variants — each variant is a separate compiled shader
- Document all keywords/variants and their purpose
- Use feature stripping where possible to reduce build size
- Log and monitor total variant count per shader
