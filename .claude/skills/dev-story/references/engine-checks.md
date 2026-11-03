# Phase 6: Parse check and capture on Unity, Unreal and Bevy

Read only when the engine is Unity, Unreal or Bevy. Report the command, its exit
code and any error lines. No executable: `parse NOT VERIFIED — engine binary not
available`.

## Unity

**Parse check:** the `commands.smoke` command (`-batchmode -quit -projectPath .
-logFile -`). Exit 1 with `error CS…` lines means a script does not compile.

**Capture** needs `Assets/Scripts/ScreenshotOnArg.cs`, given word for word in
`run-and-observe.md` (named in `SKILL.md`, Phase 6). When the project has none
(look for `Assets/**/ScreenshotOnArg.cs`), ask "May I write
`Assets/Scripts/ScreenshotOnArg.cs`?" and write it exactly as given before
launching. Declined: nothing can capture, so report
`Run result: NOT VERIFIED — ScreenshotOnArg.cs not written`.

## Unreal

**Parse check:** build the editor target. A compile error fails it (`Result:
Failed`, non-zero exit).

- Windows: `"<UE root>/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" <Project>Editor Win64 Development -Project="<absolute path>/<Project>.uproject"`
- Linux: `"<UE root>/Engine/Build/BatchFiles/Linux/Build.sh" <Project>Editor Linux Development -Project=…`
- macOS: `"<UE root>/Engine/Build/BatchFiles/Mac/Build.sh" <Project>Editor Mac Development -Project=…`

The commands are from Epic's documentation, as recorded in
`docs/engine-reference/unreal/current-best-practices.md` ("Command Line").

**Capture:** launch straight into the map the story touched, as
`run-and-observe.md` gives it.

## Bevy

**Parse check:** the `commands.smoke` command, `cargo check --all-targets`. It
compiles the library, the binary and every test target without running
anything. Any line starting `error[E` (or `error: could not compile`) means the
code does not compile: report those lines, and the check fails whatever else
the output says (the exit code is then 101). A clean check says the code
compiles, not that it works. The first check on a fresh clone compiles Bevy
itself and takes many minutes: give it a timeout of 1800 seconds.

**Capture:** the "Bevy" section of `run-and-observe.md` (`### Bevy 0.20 — one
plugin`). It needs `src/screenshot_on_arg.rs`, given word for word there, with
`pub mod screenshot_on_arg;` in `src/lib.rs` and the plugin added in
`src/main.rs`. When the project has none (look for `src/screenshot_on_arg.rs`),
ask "May I write `src/screenshot_on_arg.rs` and add its plugin to `src/lib.rs`
and `src/main.rs`?" and write them exactly as given before launching. Declined:
nothing can capture, so report
`Run result: NOT VERIFIED — screenshot_on_arg.rs not written`. Launch and read
the image as that section says (an all-black image is a cold start: launch
again, never OBSERVED).
