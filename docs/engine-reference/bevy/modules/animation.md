# Bevy Animation — Quick Reference

Last verified: 2026-11-02 | Engine: Bevy 0.20.1

## What Changed Since ~0.15 (LLM Cutoff)

### 0.19 Changes
- `MeshMorphWeights { weights }` → enum `MeshMorphWeights::Value { weights }` or
  `MeshMorphWeights::Reference(Entity)`; a parent's `MorphWeights` is no longer
  copied automatically, and `MorphPlugin` is gone (`bevy_mesh-0.20.1/src/morph.rs:120`)
- Skinned meshes are culled using the animated pose (`DynamicSkinnedMeshBounds`)
- glTF scenes spawn through `WorldAssetRoot` (was `SceneRoot`)

### 0.18 Changes
- `AnimationTarget { id, player }` → two components, `AnimationTargetId` and
  `AnimatedBy` (`bevy_animation-0.20.1/src/lib.rs:187`, `:215`)
- `AnimationEventTrigger::animation_player` → `AnimationEventTrigger::target`
  (`animation_event.rs:21`)
- Cargo feature `animation` → `gltf_animation` (`bevy-0.20.1/Cargo.toml:2926`)

### 0.17 Changes
- Clip events: `#[derive(AnimationEvent)]` read with an `On<E>` observer
  (`animation_event.rs:16`); was `#[derive(Event)]` + `Trigger<E>`
- `GltfLoaderSettings::load_animations` can skip animation loading
- The `Animation` system set is `AnimationSystems`, now in `bevy_app`
  (`bevy_app-0.20.1/src/main_schedule.rs:200`)

## Current API Patterns

### Play a glTF clip
```rust
use bevy::{prelude::*, world_serialization::WorldInstanceReady};

#[derive(Component)]
struct AnimationToPlay { graph: Handle<AnimationGraph>, index: AnimationNodeIndex }

fn setup(mut commands: Commands, assets: Res<AssetServer>, mut graphs: ResMut<Assets<AnimationGraph>>) {
    let (graph, index) = AnimationGraph::from_clip(
        assets.load(GltfAssetLabel::Animation(0).from_asset("models/fox.glb")),
    );
    commands
        .spawn((
            AnimationToPlay { graph: graphs.add(graph), index },
            WorldAssetRoot(assets.load(GltfAssetLabel::Scene(0).from_asset("models/fox.glb"))),
        ))
        .observe(play_when_ready);
}

// The glTF scene spawns an AnimationPlayer somewhere below our entity.
fn play_when_ready(
    ready: On<WorldInstanceReady>,
    mut commands: Commands,
    children: Query<&Children>,
    to_play: Query<&AnimationToPlay>,
    mut players: Query<&mut AnimationPlayer>,
) {
    let Ok(anim) = to_play.get(ready.entity) else { return };
    for child in children.iter_descendants(ready.entity) {
        if let Ok(mut player) = players.get_mut(child) {
            player.play(anim.index).repeat();
            commands.entity(child).insert(AnimationGraphHandle(anim.graph.clone()));
        }
    }
}
```
The shape of `bevy-0.20.1/examples/animation/animated_mesh.rs:34-97`.
`AnimationGraph::from_clip` (`bevy_animation-0.20.1/src/graph.rs:509`),
`AnimationGraphHandle` (`graph.rs:139`), `AnimationPlayer::play` (`lib.rs:882`)
returning an `ActiveAnimation` with `repeat` (`lib.rs:522`, `:657`),
`GltfAssetLabel` (`bevy_gltf-0.20.1/src/label.rs:33`, `from_asset` `:112`).

### Cross-fades
`AnimationTransitions::play(&mut player, index, Duration)` blends from the
current clip (`bevy_animation-0.20.1/src/transition.rs:78`); add
`AnimationTransitions` beside the `AnimationPlayer`.

### Events on a clip
`clip.add_event(time, MyEvent)` (`lib.rs:326`) with `#[derive(AnimationEvent, Clone)]`
on `MyEvent`; the derive is not in the prelude (`use bevy::animation::AnimationEvent;`,
as `bevy-0.20.1/examples/animation/animation_events.rs:4` does). Observe it with
`On<MyEvent>`; the animated entity is `ev.trigger().target`.

## Common Mistakes
- `AnimationTarget { id, player }`, `SceneRoot`, `#[derive(Event)]` for clip events
- Inserting `AnimationGraphHandle` on the `WorldAssetRoot` entity: it goes on
  the descendant that has the `AnimationPlayer`, once `WorldInstanceReady` fires
- Animating UI nodes through `Transform` (UI uses `UiTransform`)
- Building with `default-features = false` and no `gltf_animation`
