# /setup-engine — Section 11: Upgrade Subcommand

> Part of `/setup-engine`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 11. Upgrade Subcommand

**In this file:**

- Step 1 — Read Current Version State
- Step 2 — Fetch Migration Guide
- Step 3 — Pre-Upgrade Audit
- Step 4 — Confirm Before Updating
- Step 5 — Update VERSION.md
- Step 6 — Post-Upgrade Reminder

If invoked as `/setup-engine upgrade [old-version] [new-version]`:

### Step 1 — Read Current Version State

Read `docs/engine-reference/<engine>/VERSION.md` to confirm the current pinned
version, risk level, and any migration note URLs already recorded. If
`old-version` was not provided as an argument, use the pinned version from this
file.

### Step 2 — Fetch Migration Guide

Use WebSearch and WebFetch to locate the official migration guide between
`old-version` and `new-version`:

- Search: `"[engine] [old-version] to [new-version] migration guide"`
- Search: `"[engine] [new-version] breaking changes changelog"`
- Fetch the migration guide URL from VERSION.md if one is already recorded,
  or use the URL found via search.

Extract: renamed APIs, removed APIs, changed defaults, behavior changes, and
any "must migrate" items.

**Bevy:** skip the search. bevy.org publishes one guide per minor at
`https://bevy.org/learn/migration-guides/<old>-to-<new>/`, dots written as dashes
(`0-19-to-0-20`). An upgrade across several minors needs every guide in between
(0.18 → 0.20 is `0-18-to-0-19` and `0-19-to-0-20`): each minor is a breaking
release, and a skipped guide is a set of breaking changes the audit never looks
for. The new version's number and its minimum Rust version come from crates.io,
as in Section 3.

### Step 3 — Pre-Upgrade Audit

Scan the **code root** (resolve per `.claude/docs/code-root-resolution.md`) for code that uses APIs known to be deprecated or changed in the
target version:

- Use Grep to search for deprecated API names extracted from the migration
  guide (e.g., old function names, removed node types, changed property names)
- List each file that matches, with the specific API reference found

Present the audit results as a table:

```
Pre-Upgrade Audit: [engine] [old-version] → [new-version]
==========================================================

Files requiring changes:
  File                              | Deprecated API Found       | Effort
  --------------------------------- | -------------------------- | ------
  src/gameplay/player_movement.gd   | old_api_name               | Low
  src/ui/hud.gd                     | removed_node_type          | Medium

Breaking changes to watch for:
  - [change description from migration guide]
  - [change description from migration guide]

Recommended migration order (dependency-sorted):
  1. [system/layer with fewest dependencies first]
  2. [next system]
  ...
```

If no deprecated APIs are found in the code root, report: "No deprecated API usage
found in the code root — upgrade may be low-risk."

### Step 4 — Confirm Before Updating

Ask the user before making any changes:

> "Pre-upgrade audit complete. Found [N] files using deprecated APIs.
> Proceed with upgrading VERSION.md to [new-version]?
> (This will update the pinned version and add migration notes — it does NOT
> change any source files. Source migration is done manually or via stories.)"

On Bevy, the engine version is pinned in `Cargo.toml`, not by an installed
editor, so Step 5 has one more write. Ask it as its own question after this one:
"May I set `bevy = "[new major.minor]"` in `Cargo.toml` and run
`cargo update -p bevy`?" Say what it does: the next build compiles the new Bevy,
and it fails until the code is migrated. A "no" is a valid answer — the reference
docs and `project.yaml` are then ahead of the build until the developer makes
the change.

Wait for explicit confirmation before continuing.

### Step 5 — Update VERSION.md

After confirmation:

1. Update `docs/engine-reference/<engine>/VERSION.md`:
   - `Engine Version` → `[new-version]`
   - `Project Pinned` → today's date
   - `Last Docs Verified` → today's date
   - Re-evaluate and update the `Risk Level` and `Post-Cutoff Version Timeline`
     table if the new version falls beyond the LLM knowledge cutoff
   - Add a `## Migration Notes — [old-version] → [new-version]` section
     containing: migration guide URL, key breaking changes, deprecated APIs
     found in this project, and recommended migration order from the audit

2. If `breaking-changes.md` or `deprecated-apis.md` exist in the engine
   reference directory, append the new version's changes to those files.

3. If `project.yaml` exists at the repo root and has an `engine` block, Read it
   first, then update `engine.version` to `[new-version]` so the primary config
   store stays in sync with VERSION.md.

4. **Bevy, only if the user said yes in Step 4:** edit the `bevy = "…"` line in
   `Cargo.toml` to the new major.minor, then run `cargo update -p bevy`, and
   report the `Updating bevy v… -> v…` line it prints. The edit is what moves
   the version: Cargo reads `bevy = "0.19"` as any 0.19.x, so `cargo update`
   alone stays on 0.19 (verified with cargo 1.99.1: it locked 0 packages and
   noted 0.20.1 as available; after the edit the same command updated bevy
   v0.19.1 -> v0.20.1).

### Step 6 — Post-Upgrade Reminder

After updating VERSION.md, output:

```
VERSION.md updated: [engine] [old-version] → [new-version]

Next steps:
1. Migrate deprecated API usages in the [N] files listed above
2. Run /setup-engine refresh after upgrading the actual engine binary (on
   Bevy: after the Cargo.toml edit and `cargo update -p bevy`) to verify no new
   deprecations were missed
3. Run /architecture-review — the engine upgrade may invalidate ADRs that
   reference specific APIs or engine capabilities
4. If any ADRs are invalidated, run /propagate-design-change to update
   downstream stories
```

---
