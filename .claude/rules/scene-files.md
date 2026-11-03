---
paths:
  - "**/*.tscn"
  - "**/*.tres"
  - "**/*.unity"
  - "**/*.prefab"
  - "Assets/**/*.asset"
  - "**/*.scn.ron"
---

# Scene and Asset File Rules

The engine's editor writes these files. A hand edit that breaks one can stop a
scene loading, or drop references without an error. Change them in the editor
when you can.

## Godot (`.tscn`, `.tres`, `.uid`)

When you edit the text by hand:

- Never change the `format=` value in the `[gd_scene]` or `[gd_resource]` header.
- Never reuse an `id`: every `[ext_resource]` and `[sub_resource]` id is unique in its file.
- Never copy a node block with its `unique_id=` (Godot 4.6+). Drop it from the copy.
- Never invent a `uid://` value. Leave `uid=` off a new reference and let the
  editor or `godot --headless --path . --import` assign it.
- Never hand-edit TileMapLayer or GridMap cell data. It is encoded, so change it in the editor.
- Never edit or delete a `.uid` file, and commit it with its script or shader.
  Godot 4.4+ writes one beside each; when you move or rename the script or
  shader outside the editor, move its `.uid` with it.
- After a hand edit, run `godot --headless --path . --import` and open or run
  the scene once to confirm it loads without errors.

## Unity (`.unity`, `.prefab`, `.asset`)

- Never hand-edit `.unity`, `.prefab` or `.asset` YAML while a Unity Editor is
  reachable: open on this project, or reachable through its command-line or MCP
  tools. The Editor holds its own copy, and its next save can overwrite or
  conflict with the edit. Make the change through the Editor, or hand the user
  the steps. If you cannot tell whether an Editor is reachable, treat it as reachable.
- With no Editor reachable, keep every `fileID` and `guid` reference intact,
  never invent a GUID, never edit or delete a `.meta` file, and open the scene
  in the Editor afterwards to confirm it loads.

## Bevy (`.scn.ron`)

A `.scn.ron` is RON that `DynamicWorld::serialize` wrote or a person typed, and
the `WorldAssetLoader` in `bevy_world_serialization` (not `bevy_scene`, which is
BSN since 0.19) loads it as a `DynamicWorld`. Bevy itself has no editor; a Besfa
game (its `Cargo.toml` names a `besfa_*` crate or a `besfa_editor` feature) has
one, below.

### A Besfa game: edit through Besfa

The Besfa editor writes the game's scenes (`assets/scenes/main.scn.ron` and the
prefabs under `assets/`), and saves its whole in-memory scene over the file.

- **Edit through the besfa MCP server** (`besfa mcp`, which `besfa new` puts in
  `.mcp.json`): `start` runs the game in edit mode, `entities` lists ids and
  component values, `send` places, sets, parents and deletes (`instantiate`,
  `spawn`, `set`, `insert`, `remove`, `parent`, `delete`, terrain and scatter
  commands), `send {"command":"save"}` writes the file, `stop` ends it. A
  `screenshot` command renders the scene to a PNG for checking the result.
  Or ask the user to make the change in the editor.
- **Never edit the file by hand, and never `start` the MCP game, while the
  editor has the project open**: the editor's next save overwrites the edit, and
  two writers corrupt it. Nothing tells you the editor is open, so ask the user
  first (a subagent, which cannot ask, returns that question instead of editing).
- A hand edit with the editor closed follows the rules below, then load it
  through the MCP (`start`, then `entities`) to confirm every entity spawns.

### Any Bevy game

When you edit one:

- Keep it valid RON. A syntax error fails the whole load.
- Every type path must name a type the game registers for reflection
  (`#[derive(Reflect)]` with `#[reflect(Component)]` or `#[reflect(Resource)]`).
  An unknown path fails the load with "no registration found". Check the path
  against the source: paths move between versions (0.20 moved `Tonemapping` to
  `bevy_render::view`).
- Entity ids in the file are local to it: loading maps each one to a new
  entity. A component field that refers to another entity uses that entity's id
  in the same file, and is remapped only when the component implements
  `MapEntities` (`#[reflect(MapEntities)]`).
- After a hand edit, load it: run the game, or a headless test that spawns it
  with `DynamicWorldRoot`, and confirm it loads without errors.
