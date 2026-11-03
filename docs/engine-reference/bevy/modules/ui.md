# Bevy UI — Quick Reference

Last verified: 2026-11-02 | Engine: Bevy 0.20.1

## What Changed Since ~0.15 (LLM Cutoff)

### 0.20 Changes
- **`Button` and `Interaction` are deprecated** (`bevy_ui-0.20.1/src/widget/button.rs:24-30`,
  `focus.rs:61-65`). Use `bevy::ui_widgets::Button` with an `On<Activate>`
  observer; style from `bevy::picking::hover::Hovered` and `bevy::ui::Pressed`.
  None of the new names is in the prelude
- **Pointer events are flat types**: `On<PointerClick>`, `On<PointerOver>`, …;
  the pointer is `ev.pointer` (`.id`, `.position`) (`bevy_picking-0.20.1/src/events.rs:74`, `:353`)
- **Font size defaults to `FontSize::Rem(1.)`**; `Val::Em` / `Val::Rem` are new
- **`BorderRadius` corners are `CornerRadius`** (`bevy_ui-0.20.1/src/geometry.rs:1282`)
- **Text input**: `TextInput` (in `bevy_ui_widgets`) requires `EditableText`;
  Escape releases focus and propagates
- `FixedNode` positions a node against the viewport; headless `TabList` / `Tab`;
  rotated and scaled nodes clip correctly

### 0.19 Changes
- `bevy_ui_widgets` is no longer experimental and its plugins are in
  `DefaultPlugins`: adding `UiWidgetsPlugins` again panics
- `TextFont { font: FontSource, font_size: FontSize }`; text layout on Parley
- UI debug overlay: `GlobalUiDebugOptions` resource plus a per-node
  `UiDebugOptions` component (`bevy_ui_render-0.20.1/src/debug_overlay.rs:41`, `:109`)
- `2d` / `3d` features no longer pull in `ui`

### 0.18 Changes
- `BorderRadius` is a field of `Node`, not a component
- `LineHeight` is a component; `AutoDirectionalNavigation` for gamepad and
  keyboard focus movement (`bevy_ui-0.20.1/src/auto_directional_navigation.rs:107`)
- `IgnoreScroll` for sticky headers (`ui_node.rs:430`)

### 0.17 Changes
- UI nodes use `UiTransform`, not `Transform` (`bevy_ui-0.20.1/src/ui_transform.rs:144`)
- `BorderColor::all(c)`; `ScrollPosition(Vec2)`; `px()`, `percent()`, `vw()`,
  `auto()` helpers; `ViewportNode` renders a camera into a node

## Current API Patterns

### Button (0.20)
```rust
use bevy::{prelude::*, ui_widgets::{observe, Activate, Button}};

fn setup(mut commands: Commands) {
    commands.spawn(Camera2d);
    commands.spawn((
        Node {
            width: percent(100),
            height: percent(100),
            align_items: AlignItems::Center,
            justify_content: JustifyContent::Center,
            ..default()
        },
        children![(
            Button,
            Node { padding: UiRect::all(px(12)), ..default() },
            children![Text::new("Play")],
            observe(|_activate: On<Activate>| {
                info!("Play pressed");
            }),
        )],
    ));
}
```
Imports and the `observe(..)` / `On<Activate>` shape follow
`bevy-0.20.1/examples/ui/widgets/button.rs:1-100`. For hover and press colours,
add `Hovered::default()` to the button, as that example does, and query
`(&Hovered, Has<Pressed>)` (`Hovered` is immutable).

### Text
```rust
commands.spawn((
    Text::new("Score: 0"),
    TextFont { font_size: FontSize::Px(32.0), ..default() },
    TextColor(Color::WHITE),
));
```
`FontSize` and `FontSource` at `bevy_text-0.20.1/src/text.rs:783`, `:284`;
`TextFont { font: handle.into(), .. }` for a loaded font.

### Widgets in `bevy::ui_widgets`
`Button`, `Checkbox`, `Slider`, `TextInput`, `TabList` / `Tab`, `Popover`,
`MenuPopup`: unstyled ("headless"), driven by observers. `bevy_feathers` styles
them for tools; its 0.20 release note recommends vendoring feathers widgets into
a game rather than depending on them.

## Common Mistakes
- `Interaction` polling or `bevy::ui::Button` in new code (deprecated in 0.20)
- `On<Pointer<Click>>` (0.20 is `On<PointerClick>`)
- `Query<&Transform, With<Node>>` (UI uses `UiTransform`; matches nothing)
- Adding `UiWidgetsPlugins` or `InputDispatchPlugin` to an app with `DefaultPlugins`
- `BorderRadius` as a component, `BorderColor(c)`, `TextFont { font_size: 20.0 }`
- Hard-coding `px` sizes for text that should follow `RemSize`
