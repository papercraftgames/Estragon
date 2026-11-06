# @papercraftgames/estragon

Pre-1.0 Godot addon: native Gogo/GGX compilation/editor, signal-driven descriptions reconciled with retained Nodes, layout-first Node2D UI and bounded Node3D adapters. Godot owns rendering, physics and scene lifetime. No Node/Bun compiler or runtime is required for authoring or Play.

## Install into a Godot project

Install the currently published beta with Yarn. The `beta` dist-tag resolves to the published package; `--exact` pins its resolved version in the consumer's manifest:

```sh
yarn add --exact --ignore-scripts @papercraftgames/estragon@beta
```

Yarn alone installs into `node_modules`; it does not register a Godot plugin. From the project root, with no existing `addons/estragon` directory:

```sh
touch node_modules/.gdignore
mkdir -p addons
cp -R node_modules/@papercraftgames/estragon/addons/estragon addons/estragon
```

The `.gdignore` prevents Godot importing a duplicate copy from node_modules. Use a copy, not a source/output symlink. For upgrades, back up local addon modifications and deliberately replace the previous addon directory; do not nest/merge two addon versions. Commit the copied addon and its `.gd.uid` sidecars. A teammate receiving that project can edit/run with Godot alone; node_modules is not needed at runtime.

Open Godot → Project Settings → Plugins and enable **Estragon** at `res://addons/estragon/editor/plugin.cfg`. Author `.gogo` files and normal `.tscn` hosts referencing the generated script. Optionally put `{"version":1,"source_roots":["src"]}` in project `gogo.config.json`. Normal save and both main/current Play paths compile and validate natively; invalid or unsavable source blocks stale Play and recovers after repair.

[Source-authored Counter example](https://github.com/papercraftgames/Estragon/tree/main/examples/counter), [language](https://github.com/papercraftgames/Estragon/blob/main/docs/GOGO_LANGUAGE.md), [native UI](https://github.com/papercraftgames/Estragon/blob/main/docs/NODE_UI.md), [editor](https://github.com/papercraftgames/Estragon/blob/main/docs/EDITOR.md), [package/release contract](https://github.com/papercraftgames/Estragon/blob/main/docs/PACKAGING.md).

Canonical widgets: EstragonRect/Text/Button/Toggle/HBox/VBox. Class-wide typed Gogo bindables, nested conditionals/keyed lists and bounded bool `bind:value` share one native manager. This is not a complete styling/focus/text/IME/accessibility suite. Target Godot 4.0+; fresh verification is only official Linux 4.0.4 and pinned 4.7.0, no untested platform/minor certification. Current documented older-engine diagnostics and #44 highlighter limitation remain.

MIT. Original copyright and attribution are retained in LICENSE; repository ownership transfer does not alter them. No install scripts, JavaScript compiler, tests, examples, raw Assets or contributor dependencies are shipped.
