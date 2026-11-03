# Run and Observe

Shared procedure for any skill that closes a story which changes something a
player can see. Used by `/dev-story` (Phase 6) and `/story-done` (Phase 3).
**A parse check is not a run, and a story nobody looked at does not close.**
This file explains how to look.

`.claude/docs/coding-standards.md` is the authority for *what* evidence a story
needs. This file is the procedure for *producing* the visual half of it.

## The rule

Every story that changes something player-observable is **launched and observed
before it closes**, and the observation is a **retained screenshot** in
`production/qa/evidence/`. Compiling proves the code loads. Tests prove the
logic. Neither proves the text fits in the box.

The agent can see images: Claude Code's `Read` tool renders a PNG. The whole
problem is getting a picture out of the engine unattended, and every supported
engine has a native way.

## The procedure

1. **Launch windowed** at a fixed resolution — `1280x720` unless the project
   says otherwise — using `commands.run` from `project.yaml`. Never the
   headless / batch / null-RHI flag: those exist to *skip* rendering.
2. **Launch straight into the scene or map the story touched.** A feature that
   is only reachable through the main menu and three clicks is a feature the
   run will not reach. Stories should be written so their surface is reachable
   from a launch argument (a scene path, a map URL, a `--scene` flag).
3. **Wait, capture, quit.** Let the engine render real frames — 60 is a safe
   floor — capture one, and exit. Each engine's mechanism is below.
4. **Look.** `Read` the PNG. Compare what is on screen to the acceptance
   criteria. Clipped text, an overflowing panel, a missing element, the wrong
   colour — these are defects, and this is the only step that finds them.
5. **Retain.** Capture straight into the story's evidence folder, so nothing
   needs copying: `mkdir -p production/qa/evidence/[story-slug]`, then pass
   `production/qa/evidence/[story-slug]/[NN]-[what-it-shows].png` as the capture
   path (Godot adds its frame number to the name). `[story-slug]` is the story
   file's name without `.md`: `story-003-light-pickup` for
   `production/epics/core/story-003-light-pickup.md`. Reference the image from
   the evidence doc. A screenshot that was taken and discarded is an
   assertion, not evidence. Beside it, stamp the files it proves:
   `bash .claude/scripts/review-receipts.sh hash <each file the story changed> > production/qa/evidence/[story-slug]/stamp.txt`.
   A later edit to one of them then shows the evidence as older than the code.
6. **Report** one `Run result:` line in the implementation summary — vocabulary
   below.

## Per engine

| `engine.name` | Launch | Capture | Output lands in | Never use | Scaffold needed |
|---|---|---|---|---|---|
| Godot 4 | `godot --path . --windowed --resolution 1280x720 <scene>.tscn` | `--write-movie <path>.png --quit-after <N>` | beside the given path, `<name>00000000.png` … | `--headless` | **none** |
| Unity 6 | built player `.exe -screen-width 1280 -screen-height 720 -screen-fullscreen 0 --scene <Name>` | `ScreenCapture.CaptureScreenshot(<abs path>)` from a bootstrap script | the absolute path you pass | `-batchmode`, `-nographics` | one MonoBehaviour |
| Unreal 5 | `MSYS_NO_PATHCONV=1 "<UE root>/Engine/Binaries/Win64/UnrealEditor.exe" "$(pwd -W 2>/dev/null || pwd)/<Game>.uproject" <MapURL> -game -windowed -ResX=1280 -ResY=720` | `HighResShot 1280x720 filename=<abs path>` console command | the path you pass (else `Saved/Screenshots/WindowsEditor/`) | `-nullrhi`, `-unattended` alone | one actor or `-ExecCmds` |
| Bevy 0.20 | `cargo run -- --screenshot <abs path>` (the default window is 1280x720 physical pixels) | `Screenshot::primary_window()` + `save_to_disk(<abs path>)` from a plugin | the absolute path you pass | `MinimalPlugins` (no window, no renderer) | one plugin, two lines to register it |

### Godot 4 — zero scaffold

```
godot --path . --windowed --resolution 1280x720 --write-movie shots/shop.png --quit-after 60 res://scenes/shop.tscn
```

`--write-movie` is Movie Maker mode: with a `.png` target it writes a frame
sequence and `--quit-after` sets the frame count. Filenames carry **8**
zero-padded digits — `shop00000000.png` through `shop00000059.png` — so take the
last; a `shop.wav` lands beside them. `--fixed-fps` is applied automatically. The
scene path is positional; any `.tscn` can be launched directly, which is how step
2 is satisfied. The frames are recorded at the project's viewport size
(`display/window/size/viewport_width` and `_height`, 1152x648 when unset), not at
`--resolution`, which only sizes the window; the log's `recording movie in
<W>×<H>` line says which. The capture-on-trigger alternative below saves at the
window size.

Capture-on-trigger alternative, for a state a scene launch cannot reach: an
autoload that on the wanted condition does
`await RenderingServer.frame_post_draw`, then
`get_viewport().get_texture().get_image().save_png(path)`, then
`get_tree().quit()`.

### Unity 6 — one MonoBehaviour

`-batchmode` displays nothing, so the run is either the **built player** or the
editor in play mode. The player is the robust path:

```
Builds/Win64/Game.exe -screen-width 1280 -screen-height 720 -screen-fullscreen 0 --scene Shop --screenshot C:/abs/path/shop.png --after 60
```

`-screen-*` are Unity's own player arguments. `--scene`, `--screenshot` and
`--after` are **yours**, read by the script below. The template does not ship
it: the first time a Unity story needs a screenshot, `/dev-story` asks to write
it, verbatim, to `Assets/Scripts/ScreenshotOnArg.cs`. It needs no scene edit — it boots itself, and does nothing unless the player
was launched with `--screenshot`:

```csharp
using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

// Run-and-observe capture: Game.exe --scene Shop --screenshot C:/abs/shop.png --after 60
public class ScreenshotOnArg : MonoBehaviour
{
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    static void Boot()
    {
        if (Arg("--screenshot") == null) return;
        var go = new GameObject(nameof(ScreenshotOnArg));
        DontDestroyOnLoad(go);
        go.AddComponent<ScreenshotOnArg>();
    }

    static string Arg(string name)
    {
        var args = System.Environment.GetCommandLineArgs();
        for (int i = 0; i < args.Length - 1; i++)
            if (args[i] == name) return args[i + 1];
        return null;
    }

    IEnumerator Start()
    {
        var scene = Arg("--scene");
        if (!string.IsNullOrEmpty(scene)) yield return SceneManager.LoadSceneAsync(scene);
        int after = int.TryParse(Arg("--after"), out var n) ? n : 60;
        for (int i = 0; i < after; i++) yield return null;
        yield return new WaitForEndOfFrame();
        ScreenCapture.CaptureScreenshot(Arg("--screenshot"));
        for (int i = 0; i < 3; i++) yield return null;   // the file is written after the frame
        Application.Quit();
    }
}
```

Pass an **absolute** path — the relative base differs between editor and
player. `--scene` must be in the build settings. Building the player first
costs 1–3 minutes on a small project; that is the price of looking at the thing
you ship rather than the editor.

### Unreal 5 — one actor, or `-ExecCmds`

```
MSYS_NO_PATHCONV=1 timeout 60 "<UE root>/Engine/Binaries/Win64/UnrealEditor.exe" "$(pwd -W 2>/dev/null || pwd)/Game.uproject" /Game/Maps/Shop -game -windowed -ResX=1280 -ResY=720
```

That line is Windows'. On Linux the same arguments go to
`"<UE root>/Engine/Binaries/Linux/UnrealEditor"` (no `MSYS_NO_PATHCONV` needed);
on macOS Epic documents only the `UnrealEditor.app` bundle, so run the map from
the editor or a command you have confirmed (see
`docs/engine-reference/unreal/current-best-practices.md`, "Command Line").

`-game` runs standalone without the editor UI. The map is a **positional URL
immediately after the `.uproject`** — not a console command. **The
`MSYS_NO_PATHCONV=1` prefix is required on Windows:** Claude Code runs commands
in Git Bash, which rewrites any argument beginning with `/` as a Windows path, so
`/Game/Maps/Shop` reaches the engine as `C:/Program Files/Git/Game/Maps/Shop`
and the game stops on a "map not found" dialog nobody can see. Alternatively
pass the map through `-ExecCmds="open /Game/Maps/Shop"`, which is not converted.
**The project path must be absolute** — with `MSYS_NO_PATHCONV` set, only
`$(pwd -W 2>/dev/null || pwd)` gives one: a relative `Game.uproject` is not
found, and the launch waits on an error dialog forever (verified on 5.7). There
is no `-unattended` on this line, so every failure is a dialog nobody clicks:
always run it under `timeout`. Capture is the
`HighResShot` console command, fired either from a dev actor (`Execute Console
Command` on BeginPlay after a short delay, then `quit`) or from the launch line:

```
-ExecCmds="HighResShot 1280x720 filename=C:/abs/path/shop.png"
```

The size (or a multiplier such as `2`) comes **before** `filename=`:
`HighResShot filename=…` alone is rejected as bad input and saves nothing.
Without `filename=` the file lands in `Saved/Screenshots/WindowsEditor/`.
**Do not put `Quit` in the same `-ExecCmds` list** — it runs on the same
frame, before the file is written, and leaves nothing on disk. `-ExecCmds` has
no delay, so let `timeout` end the launch (exit 124 is expected) and check the
file exists; a dev actor can instead wait a second, then `quit`. The Blueprint node `Take High Res Screenshot` is editor-only and
does not work in a `-game` launch.

### Bevy 0.20 — one plugin

```
cargo run -- --screenshot "$(pwd -W 2>/dev/null || pwd)/production/qa/evidence/shop-panel/01-shop-open.png" --frames 60
```

Everything after `--` reaches the game, not Cargo. `--screenshot` and `--frames`
are **yours**, read by the plugin below. The template does not ship it: the
first time a Bevy story needs a screenshot, `/dev-story` asks to write it,
verbatim, to `src/screenshot_on_arg.rs`, and to add two lines: `pub mod
screenshot_on_arg;` in `src/lib.rs`, and
`.add_plugins(<crate>::screenshot_on_arg::ScreenshotOnArgPlugin)` beside
`DefaultPlugins` in `src/main.rs`. A bin-only crate (no `src/lib.rs`, such as a
Besfa game) takes both lines in `src/main.rs`: `mod screenshot_on_arg;` and
`.add_plugins(screenshot_on_arg::ScreenshotOnArgPlugin)` beside its other
plugins. Unlike Unity's script, a Bevy plugin does not register itself. It does nothing unless the game was launched with
`--screenshot`:

```rust
//! `cargo run -- --screenshot <abs path> [--frames N]` saves one frame and exits.
use bevy::prelude::*;
use bevy::render::view::screenshot::{save_to_disk, Screenshot, ScreenshotCaptured};

pub struct ScreenshotOnArgPlugin;

#[derive(Resource)]
struct Pending {
    path: String,
    frames: u32,
}

impl Plugin for ScreenshotOnArgPlugin {
    fn build(&self, app: &mut App) {
        let args: Vec<String> = std::env::args().collect();
        let arg = |name: &str| args.iter().position(|a| a == name).and_then(|i| args.get(i + 1));
        let Some(path) = arg("--screenshot") else { return };
        let frames = arg("--frames").and_then(|n| n.parse().ok()).unwrap_or(60);
        app.insert_resource(Pending { path: path.clone(), frames })
            .add_systems(Update, capture);
    }
}

fn capture(mut commands: Commands, mut pending: ResMut<Pending>) {
    if pending.frames == 0 {
        return;
    }
    pending.frames -= 1;
    if pending.frames == 0 {
        commands
            .spawn(Screenshot::primary_window())
            .observe(save_to_disk(pending.path.clone()))
            .observe(|_: On<ScreenshotCaptured>, mut exit: MessageWriter<AppExit>| {
                exit.write(AppExit::Success);
            });
    }
}
```

The capture is asynchronous: the image arrives a frame or more after the
screenshot entity spawns, both observers run when it does, and the game exits
only after the file is written. The log says `Screenshot saved to <path>`. Pass
an **absolute** path: `cargo run` keeps your shell's directory as the game's
working directory. The window opens at Bevy's default 1280x720 physical pixels,
which is step 1's resolution; a project that sets its own `Window` resolution
captures at that size instead.

**An all-black image is a cold start, not a result.** Bevy's default clear colour
is dark grey, so pure black means nothing rendered. The first launch after a
fresh build captured all black at 60 frames; the next five launches, at 60 to
300 frames, captured the scene. Launch again, or raise `--frames`, and never
report a black capture as `OBSERVED`.

The plugin does not choose a scene or state. Reach the story's surface through
the game's own launch argument (see "Reaching the state").

### Bevy — a Besfa game

A Besfa game (its `Cargo.toml` names a `besfa_*` crate or a `besfa_editor`
feature) is captured the same way, with two differences:

- **Launch with `commands.run`**, which carries the editor's features
  (`cargo run --features bevy/dynamic_linking,besfa_editor`), then `--
  --screenshot <abs path> --frames 60`. Plain `cargo run` rebuilds Bevy in the
  shared target. Run from a shell, the `besfa_editor` feature opens the game's
  own window, unpaused: the editor's edit mode needs environment variables only
  the editor and `besfa mcp` set.
- **A scene or level story can use the besfa MCP instead.** `send
  {"command":"screenshot","file":"production/qa/evidence/<slug>/01-<what>.png","eye":[x,y,z],"target":[x,y,z]}`
  (or `"top":<metres>` for a map view) renders the scene from a camera of its
  own, without editor overlays, to a path relative to the project. It shows
  what was placed, not what the player sees: no game camera, no UI. A HUD or
  menu story needs the plugin above. Never `start` the MCP game while the
  editor has the project open (`.claude/rules/scene-files.md`).

### Any engine — OS capture fallback

On Windows, PowerShell with `System.Drawing` can `CopyFromScreen` into a bitmap
and save it. It needs a visible desktop and the game window on top, and it
captures whatever is there — it cannot be told "the shop panel". Use it when the
engine-native path is unavailable, and say so in the run result. Linux CI with
no display needs `xvfb-run` in front of the launch; `--headless` is not a
substitute.

## The `Run result:` line

Exactly one of three shapes, in the implementation summary:

- **`Run result: OBSERVED — <what was on screen, one line>`** with the retained
  path. *"Shop panel renders, all 6 slots inside the frame, prices legible at
  720p — `production/qa/evidence/shop-panel/01-shop-open.png`."*
- **`Run result: NOT VERIFIED — <reason>`**. Engine binary not found,
  `commands.run` unset, launch crashed, screenshot empty. This is a **blocker**
  at the default gate level for Visual/Feel and UI stories, not a note — a
  story nobody looked at does not close. Under an explicit
  `testing.strict.visual`/`.ui: false` it is recorded and the story may close
  with the gap in `## Completion Notes`.
- **`Run result: N/A — <reason>`**, only for a story with genuinely nothing
  observable — a pure data migration, a save-format change with no surface.
  Say why. "It's a Logic story" is not a reason: a damage formula has a number
  on screen somewhere.

The run is **not waived at `qa.level: minimal`**. Tests are waived there; the
look is not. It is the cheapest verification in the pipeline and the one
whose absence produces a well-tested game that looks wrong.

## What a still can and cannot show

**Can:** layout, clipping, overflow, presence, alignment, colour, legibility,
that the right screen appeared at all. This is where shipped visual defects
actually live.

**Cannot:** timing, responsiveness, weight, animation curves, audio sync — the
"feel" half of Visual/Feel. Godot's `--write-movie` gives a frame sequence; the
other engines need OS video capture. Feel stays a human check in `/team-qa`.
Say which half the screenshot covered.

## Reaching the state

A screenshot of the title screen verifies nothing about depth 2. Either launch
the scene/map directly (Godot scene arg, Unreal map URL, Unity `--scene`) or
give the bootstrap a debug argument that sets state (`--gold=500 --depth=2`).
Bevy has no engine-level scene argument: the game reads its own (for example
`--state shop` choosing the initial `States` value, or a `.scn.ron` path it
loads), passed after `--` beside `--screenshot`.
Write stories so their surface is reachable one of those ways; a story that is
not is a story that will be marked `NOT VERIFIED` every time.

## Finding the engine

None of Godot, Unity or Unreal installs onto `PATH` on Windows. `engine.path` in
`project.yaml` is where the editor lives; resolve it before concluding "no
engine on this machine". Absence of a path is not absence of an engine. Bevy is
the exception: it is a crate the project's `Cargo.toml` pulls in, so the only
binary needed is `cargo` (rustup puts it on `PATH`), and `engine.path` is unused.
A Besfa game is the same: the editor is not needed to run or capture it.

---

*Commands above were run on Windows with Godot 4.6.1 (gdUnit4 6.1.3) and the
Godot ones again on 4.7.2 (gdUnit4 6.2.2), Unity
6000.3.23f1 and Unreal Engine 5.7; the Unreal Linux and macOS notes come from
Epic's documentation. The Bevy plugin and launch line were run on Windows with
Bevy 0.20.1 (debug build, Vulkan). `docs/engine-reference/<engine>/` is
the project's pinned authority; check it before trusting a version-qualified
claim here.*
