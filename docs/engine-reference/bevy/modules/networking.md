# Bevy Networking — Quick Reference

Last verified: 2026-11-02 | Engine: Bevy 0.20.1

## Bevy Ships No Multiplayer Networking

No 0.20.1 crate provides replication, RPCs, client prediction or a game
transport; `DefaultPlugins` has no networking plugin
(`bevy_internal-0.20.1/src/default_plugins.rs:5-104`). Multiplayer comes from a
crate, chosen per project (a dependency decision for `technical-director`):

| Crate | Version for Bevy 0.20 | Role |
|-------|-----------------------|------|
| `lightyear` | 0.31.0 | Replication, prediction, interpolation, transports |
| `bevy_replicon` | 0.45.5 | Server-authoritative replication, transport-agnostic |
| `bevy_replicon_renet` | 0.21.0 | renet transport for replicon |
| `bevy_renet` | 6.0.0 | renet UDP transport |

`bevy_matchbox` (WebRTC) has no Bevy 0.20 release (2026-11-02). Versions and
repositories: `PLUGINS.md`. The security-relevant names (RPC attributes,
replicated components, authority checks) belong to the crate the game picked:
read them from that crate's docs.rs page, for that version.

## The One Network Surface Bevy Does Ship: Bevy Remote Protocol

`bevy_remote` serves the running app's world to remote tools as JSON-RPC 2.0
(https://docs.rs/bevy_remote/0.20.1/bevy_remote/). It is a debugging and editor
tool, not game networking.

- `RemotePlugin` (`bevy::remote::RemotePlugin`) sets up the protocol "without
  starting any transports"; `RemoteHttpPlugin` (`bevy::remote::http::RemoteHttpPlugin`)
  adds HTTP, by default on port 15702
  (https://docs.rs/bevy_remote/0.20.1/bevy_remote/http/index.html).
- Behind the `bevy_remote` cargo feature, **off by default** (not in the
  `default` closure; `bevy-0.20.1/Cargo.toml:2817`), and not built for wasm
  (`bevy_internal-0.20.1/Cargo.toml:809-812`).
- With both plugins added, anything that reaches the port can read and change
  the world. Keep them out of release builds, for example behind a `dev` cargo
  feature of the game or `#[cfg(debug_assertions)]`.

```rust
// Debug builds only.
#[cfg(debug_assertions)]
app.add_plugins((bevy::remote::RemotePlugin::default(),
                 bevy::remote::http::RemoteHttpPlugin::default()));
```
The `default()` constructors are as in `bevy-0.20.1/examples/remote/server.rs`.

## What Changed Since ~0.15 (LLM Cutoff)

- 0.19: dropping a `Task` on wasm cancels it; `.detach()` keeps it running
  (affects async networking code on the web)
- Networking crates move with Bevy: the versions that matched 0.16 do not
  compile against 0.20

## Common Mistakes
- Suggesting a built-in replication or RPC API (Bevy has none)
- Shipping `RemoteHttpPlugin` in a release build
- Using a networking crate version built for an older Bevy
- Writing a crate's API from memory instead of its docs.rs page for the pinned version
