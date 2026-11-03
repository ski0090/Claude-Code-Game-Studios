# Bevy Saving and Serialization — Quick Reference

Last verified: 2026-11-02 | Engine: Bevy 0.20.1

## Bevy Ships No Save-Game System

There is no save slot, save file format or per-user save directory in Bevy
0.20.1. A game builds saving from the pieces below, or from a crate such as
`bevy_pkv` (`PLUGINS.md`). What follows is what Bevy does ship.

## World Serialization (`bevy::world_serialization`, 0.19+)

The crate formerly called `bevy_scene` (renamed in 0.19, when `bevy_scene`
became BSN). It turns a set of entities and resources into a `DynamicWorld` and
writes it as RON.

- Build: `DynamicWorldBuilder::from_world(&world, &registry)` with filters
  (`deny_all`, `allow_component::<T>()`, `allow_resource::<R>()`), then
  `extract_entities(..)`, `extract_resources()`, `build()`
  (`bevy_world_serialization-0.20.1/src/dynamic_world_builder.rs:90-373`).
- Write: `dynamic_world.serialize(&registry)` returns a RON `String`
  (`dynamic_world.rs:229`; needs the crate's `serialize` feature, on by default).
- Load: the `WorldAssetLoader` reads `.scn` and `.scn.ron` into a
  `DynamicWorld` (`world_asset_loader.rs:73-74`); spawn it with
  `DynamicWorldRoot(asset_server.load(path))` (`components.rs:27`) or apply it
  with `write_to_world` (`dynamic_world.rs:211`).
- Only types registered for reflection round-trip: derive `Reflect` and add
  `#[reflect(Component)]` / `#[reflect(Resource)]`. Since 0.19 asset handles
  survive (de)serialization when the asset derives `Reflect` with `#[reflect(Asset)]`.

```rust
use bevy::prelude::*;

#[derive(Component, Reflect)]
#[reflect(Component)]
struct Inventory { gold: u32 }

fn save_inventory(world: &mut World) -> Result {
    let registry = world.resource::<AppTypeRegistry>().clone();
    let registry = registry.read();
    let mut query = world.query_filtered::<Entity, With<Inventory>>();
    let entities: Vec<Entity> = query.iter(world).collect();
    let save = DynamicWorldBuilder::from_world(world, &registry)
        .deny_all()
        .allow_component::<Inventory>()
        .extract_entities(entities.into_iter())
        .build();
    let _ron: String = save.serialize(&registry)?;
    // write `_ron` to the player's save location
    Ok(())
}
```
The registry access follows the crate's own doc example (`serde.rs:47-55`).

## User Settings (`bevy_settings`, 0.19+)

Behind the `bevy_settings` cargo feature, **off by default**
(`bevy-0.20.1/Cargo.toml:2820`). The 0.20.1 crate (`bevy-settings` on crates.io)
exports `SettingsPlugin`, the `SettingsGroup` trait and derive,
`SaveSettingsDeferred`, `SaveSettings` and `SaveSettingsSync`, and stores
settings on "the filesystem or browser local storage, depending on platform"
(https://docs.rs/bevy-settings/0.20.1/bevy_settings/). The 0.19 release note
calls the plugin `PreferencesPlugin`; 0.20.1 names it `SettingsPlugin`. Read
the docs.rs page before writing code against it: this crate was not in the
local registry, so its signatures were not checked.

## Runtime Asset Saving (0.19+)

`save_using_saver(asset_server, &saver, &path, SavedAsset::from_asset(&a), &settings)`
writes an asset through an `AssetSaver` (`bevy_asset-0.20.1/src/saver.rs:533`,
`SavedAsset` `:100`). Run it on the `IoTaskPool`; it is `async`.

## Security Notes

- A save file is player-controlled input. Deserializing a `DynamicWorld`
  creates whatever registered component types the file names (the deserializer
  resolves types through the `TypeRegistry`, `serde.rs:107-108`), with whatever
  field values it holds. Validate values after loading, and prefer a narrow
  save struct of your own over a whole-world dump for player saves.
- Asset loads outside the approved asset folders are refused by default
  (`UnapprovedPathMode::Forbid`, `bevy_asset-0.20.1/src/lib.rs:273-285`);
  `Allow` is "strongly discouraged" where the app has scripts or mods.

## Common Mistakes
- `DynamicScene`, `DynamicSceneBuilder`, `bevy::scene` for RON files (renamed in 0.19)
- Saving components that never derived `Reflect` (they are silently absent)
- Treating a `.scn.ron` save from disk as trusted data
- Expecting Bevy to pick a save directory (it does not)
