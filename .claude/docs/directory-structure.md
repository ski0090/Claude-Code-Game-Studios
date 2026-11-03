# Directory Structure

```text
/
├── CLAUDE.md                    # Master configuration
├── project.yaml                 # Machine-readable project config — engine, modes, stage (source of truth)
├── .claude/                     # Agent definitions, skills, hooks, rules, docs
├── <code root>/                 # Game source code — THE PATH IS ENGINE-SPECIFIC, see below
├── assets/                      # Game assets (art, audio, vfx, shaders, data)
├── design/                      # Game design documents (gdd, narrative, levels, balance)
├── docs/                        # Technical documentation (architecture, api, postmortems)
│   └── engine-reference/        # Curated engine API snapshots (version-pinned)
├── tests/                       # Game test suites (unit, integration, performance, playtest)
├── tools/                       # Build and pipeline tools (ci, build, asset-pipeline)
├── prototypes/                  # Throwaway prototypes (outside the code root)
├── production/                  # Production management (sprints, milestones, releases)
│   ├── session-state/           # Ephemeral session state (active.md — gitignored)
│   └── session-logs/            # Session audit trail (gitignored)
└── studio-tests/                # QA for the skills/agents themselves — /skill-test, /skill-improve
```

## The code root is engine-specific

**Two of the four supported engines will not build a project whose code sits in
`src/`.** This is not a style preference — it is a hard constraint of the engine's
own toolchain:

| `engine.name` | Code root | Why it cannot be `src/` |
|---|---|---|
| **Godot** | `src/` | No constraint — Godot loads from `res://` anywhere under the project root. |
| **Unity** | `Assets/` | Unity compiles **only** `Assets/` and `Packages/`. Code outside them is invisible to the compiler. |
| **Unreal** | `Source/<Module>/` | UnrealBuildTool discovers modules under `Source/`; content lives in `Content/`. A module elsewhere is not built. |
| **Bevy** | `src/` | Cargo's default: `src/lib.rs` is the library crate, `src/main.rs` the binary. Game logic goes in the library, `pub`, because the tests under `tests/` link only its public API; `main.rs` only builds the `App`. |

**Resolve the code root from `engine.name` before writing any source file.** A
path shown as `src/…` alone is a Godot example: read it as *"the code root"* and
substitute the row above. `src/` is the table's Godot and Bevy row, not a
universal path.

**Godot and Bevy share `src/`, so the directory alone cannot tell them apart.**
The project file does: Godot has `project.godot` at the root, Bevy a `Cargo.toml`
with a `bevy` dependency. Either way the code root is `src/`, so a tree with no
`engine.name` still resolves to the right root; only the engine needs one of
those two files.

**Tests follow the same rule** — the same compilers decide what they see:

| `engine.name` | Test root | Anywhere else |
|---|---|---|
| **Godot** | `tests/unit/`, `tests/integration/` | — |
| **Unity** | `Assets/Tests/EditMode/`, `Assets/Tests/PlayMode/` | not compiled: "0 tests, Passed" |
| **Unreal** | `Source/<Module>/Private/Tests/` | not built: "No automation tests matched" |
| **Bevy** | `tests/unit/main.rs`, `tests/integration/main.rs` (each declares its systems as `mod <system>;`, one file per system in the same folder); helpers in `tests/helpers/mod.rs`, declared from each test root with `#[path = "../helpers/mod.rs"] mod helpers;`; unit tests of private items in a `#[cfg(test)]` module of the `src/` file | not compiled: a file that `main.rs` does not `mod`-declare is never compiled — no error, no tests (verified on 0.20.1) |

Read `tests/unit/[system]/` (or `integration/`) anywhere as the test root plus `[System]/`.
