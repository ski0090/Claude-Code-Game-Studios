# Agent Test Spec: bevy-specialist

## Agent Summary
Domain: Bevy-specific architecture and APIs in Rust — ECS (components, resources, plugins, schedules), messages vs observer events, rendering and WGSL/WESL shaders, `bevy_ui`, assets, `.scn.ron` world files and BSN scenes, headless tests.
Does NOT own: gameplay feature implementation (gameplay-programmer), game design decisions, crate/dependency approval (technical-director).
Single engine agent: Bevy has no sub-specialists, so shader and UI work routes here (`specialists.code`, `.shader`, `.ui` all name `bevy-specialist`).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references Bevy / ECS / schedules / shaders)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep, and does **not** include `Agent` (there are no Bevy sub-specialists to start)
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Has a `## Collaboration Protocol` section that asks before writing ("May I write this to [filepath(s)]?")
- [ ] States that it is also the shader and UI specialist, with no sub-specialist routing table
- [ ] `## Version Awareness` sends the agent to `docs/engine-reference/bevy/` (VERSION, deprecated-apis, breaking-changes, current-best-practices, modules, PLUGINS)

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Enemy deaths need to reach the score system and the achievement system. Event or something else?"
**Expected behavior:**
- Explains the 0.17+ split from `docs/engine-reference/bevy/current-best-practices.md` § Messages, Events and Observers: a `Message` (`#[derive(Message)]`, `app.add_message`, `MessageWriter::write`, `MessageReader::read`) is read in a batch where the reading system runs; an `Event` / `EntityEvent` with `On<E>` observers reacts immediately
- Recommends a message for two independent readers of a per-frame stream, and says when an observer would be the better choice
- Names the type in the past tense (`EnemyDied`), per `naming.signals`
- Does NOT emit `EventReader`, `EventWriter`, `#[derive(Event)]` for a buffered event, or `Trigger<E>`
- Proposes the types and systems and asks before writing any file

### Case 2: Wrong-engine redirect
**Input:** "Set up a Node scene tree with signals for this enemy system."
**Expected behavior:**
- Does NOT produce Godot Node/signal code
- Identifies node trees and signals as Godot concepts
- Confirms the project's engine from `engine.name` in `project.yaml` rather than guessing; if it is not Bevy, says it is the wrong specialist for this project instead of translating
- If `engine.name` is unset, says no engine is configured and asks which engine the project uses — it does not assume Bevy
- In a Bevy project, maps the concepts: node tree → entity hierarchy (`ChildOf` / `Children`, `children![..]`); signal → a message or an observer event
- Does not hand the request to a Godot specialist — it has no `Agent` tool

### Case 3: Version API flag — shader written from training data
**Input:** "Write a custom material shader that starts with `#import bevy_pbr::forward_io::VertexOutput`."
**Expected behavior:**
- Checks `docs/engine-reference/bevy/VERSION.md` and `breaking-changes.md` before answering, not training data
- States that 0.20 shaders are WESL: a `.wesl` file under `assets/shaders/`, `import bevy_pbr::render::forward_io::VertexOutput;`, `@if(DEF)` instead of `#ifdef`, bindings in `@group(constants::MATERIAL_BIND_GROUP)`; naga_oil `#import` no longer exists
- Flags the installed-version gap: when `Installed at pin time` is `NOT DETERMINED`, reads the `bevy` version in `Cargo.lock` or asks before relying on 0.20 syntax
- Writes the Rust side as `AsBindGroup` + `impl Material` returning the `.wesl` path, registered with `MaterialPlugin`
- Does the shader work itself (no Bevy shader sub-specialist exists) and asks before writing the files

### Case 4: Render path decision
**Input:** "Make the game deferred-rendered so the water looks better."
**Expected behavior:**
- States the default from `docs/engine-reference/bevy/modules/rendering.md`: opaque materials render forward; deferred is opt-in
- Lists the opt-in steps: `DefaultOpaqueRendererMethod::deferred()`, plus `DeferredPrepass` and `DepthPrepass` on the `Camera3d`
- Names the trade-off (deferred gives up MSAA; more bandwidth) and asks whether the target platforms accept it
- Notes that transmissive water also needs `ScreenSpaceTransmission` on the camera in 0.20, whichever path is chosen
- Treats the render-path change as an architecture decision to confirm with the user (and `technical-director` if it affects the platform budget), not something to switch silently

### Case 5: Context pass — headless test for a plugin that uses states
**Input:** Project context: Bevy 0.20, `CombatPlugin` in `src/combat.rs` calls `app.init_state::<GameState>()`. Request: "Write a unit test for the combat plugin."
**Expected behavior:**
- Uses the headless pattern from `current-best-practices.md` § Testing: `App::new()`, `MinimalPlugins`, the plugin, `app.update()`, assertions on `app.world()`
- Adds `StatesPlugin` (`bevy::state::app::StatesPlugin`, not in the prelude) to the test app, because `MinimalPlugins` lacks it and `init_state` panics without it
- Places the test at `tests/unit/combat.rs` and declares it as `mod combat;` in `tests/unit/main.rs` (an undeclared file is never compiled), or in-file under `#[cfg(test)]` when it needs private items
- Notes that `CombatPlugin` must be `pub` in the library crate for `tests/` to reach it
- Asks before writing, unless an orchestrating skill named the `tests/` path

---

## Protocol Compliance

- [ ] Stays within declared domain (Bevy architecture, engine-facing code, shaders, UI, assets, tests)
- [ ] Treats other engines' patterns as wrong-engine: checks `engine.name`, answers with the Bevy equivalent, never emits Godot/Unity/Unreal code
- [ ] Checks `docs/engine-reference/bevy/` (pinned version and `Installed at pin time`) before suggesting a version-gated API, and confirms the locked version when it is not recorded
- [ ] Never emits pre-0.17 names listed in `deprecated-apis.md`
- [ ] Routes crate additions (physics, networking, input) to `technical-director` and gameplay features to `gameplay-programmer`
- [ ] Asks before writing files

---

## Coverage Notes
- Case 1 checks the 0.17 message/observer split, the change the model most often gets wrong
- Case 3 confirms the agent absorbs the shader role and knows the 0.20 WESL switch
- Case 4 checks the default render path against the reference rather than training data
- Case 5 covers the `MinimalPlugins` gap and Cargo's test discovery rule
