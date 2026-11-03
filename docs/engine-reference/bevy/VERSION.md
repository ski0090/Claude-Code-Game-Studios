# Bevy — Version Reference

Last verified: 2026-11-02

| Field | Value |
|-------|-------|
| **Engine Version** | Bevy 0.20 (latest patch 0.20.1) |
| **Installed at pin time** | NOT DETERMINED — `/setup-engine` §3 reads the `bevy` package in the project's `Cargo.lock` and records the result here. |
| **Release Date** | October 2026 (0.20.0 Oct 8, 2026; 0.20.1 Oct 28, 2026) |
| **Minimum Rust** | 1.97.1 (`rust-version` in the `bevy` 0.20.1 crate's `Cargo.toml`) |
| **Project Pinned** | 2026-11-02 |
| **Last Docs Verified** | 2026-11-02 |
| **LLM Knowledge Cutoff** | May 2025 |

## Knowledge Gap Warning

The LLM's training data likely covers Bevy up to ~0.15. 0.16 shipped a month
before the cutoff and may be thinly covered; 0.17, 0.18, 0.19 and 0.20 were all
released after it. Bevy has no LTS line and every 0.x minor is a breaking
release, so four breaking releases sit between the model and this pin. Names
the model knows (`EventReader`, `Trigger`, `OnAdd`, `SceneRoot`,
`DynamicScene`, `#import` in shaders, `Pointer<Click>`) no longer compile.
Always cross-reference this directory before suggesting Bevy API calls.

## Installed-Version Gap Warning

The warning above is one-directional — it covers the **model** knowing less than
this pin. The reverse gap is real and `/setup-engine` §3 creates it deliberately
("pin the newer one and upgrade later"): this reference can sit **ahead of the
project's locked Bevy**, and an agent citing it correctly then emits APIs that do
not compile. **Check `Installed at pin time` above before trusting a
version-qualified claim** — `NOT DETERMINED` means the gap is unknown, not absent.

Bevy is a crate, not an installed editor; even a Besfa game's editor builds the
game with the game's own locked Bevy. The installed version is the
`[[package]]` with
`name = "bevy"` in `Cargo.lock`, read from its `version = "0.20.x"` line, and
`bevy = "0.20"` in `Cargo.toml` resolves to any 0.20.x. Compare major.minor
(`0.20`). A lock on 0.19 means every 0.20 row in `breaking-changes.md` is ahead
of the code.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 0.17 | Sep 2025 | HIGH | Buffered events renamed to messages (`Message`, `MessageReader`, `MessageWriter`); observers take `On<E>`; `EntityEvent`; `bevy_render` split into `bevy_camera`, `bevy_light`, `bevy_mesh`, `bevy_image`, `bevy_shader`; UI uses `UiTransform`; headless UI widgets |
| 0.18 | Jan 2026 | HIGH | Cargo feature collections (`2d`, `3d`, `ui`, `audio`); `RenderTarget` is a component; `GlobalAmbientLight`; `BorderRadius` moves into `Node`; `detach_*` hierarchy methods; `NextState::set` always runs transitions |
| 0.19 | Jun 2026 | HIGH | Next-generation scenes: `bevy_scene` is now BSN (`bsn!`), the old RON scenes move to `bevy_world_serialization` (`DynamicWorld`, `WorldAssetRoot`); resources are components; text layout on Parley; `load_builder`; render graph becomes systems |
| 0.20 | Oct 2026 | HIGH | Shaders are WESL (naga_oil and GLSL gone); flat pointer events (`PointerClick`); `On<Add<T>>`; `Button`/`Interaction` deprecated for `ui_widgets`; transmission opt-in; sprites drawn as `Mesh2d`; BSN syntax changes |

## Before the Cutoff

0.16 (Apr 24, 2025; 0.16.1 May 30, 2025) predates the May 2025 cutoff by about
a month; the Knowledge Gap Warning still applies to it. `breaking-changes.md`
starts at 0.16 → 0.17 for that reason.

## Sources

Release dates from the crates.io API
(`https://crates.io/api/v1/crates/bevy/versions`, checked 2026-11-02): 0.16.0
2025-04-24, 0.17.0 2025-09-30, 0.18.0 2026-01-13, 0.19.0 2026-06-19, 0.20.0
2026-10-08, 0.20.1 2026-10-28. Migration guides: `breaking-changes.md` § Sources.
API facts in this directory were checked against the 0.20.1 crates' source
(`bevy_*-0.20.1/src`), cited as `crate-0.20.1/src/file.rs:line`.
