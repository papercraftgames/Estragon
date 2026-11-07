# @papercraftgames/estragon

Pre-1.0 Godot addon: native Gogo/GGX compilation/editor, signal-driven descriptions reconciled with retained Nodes, layout-first Node2D UI and bounded Node3D adapters. Godot owns rendering, physics and scene lifetime. No Node/Bun compiler or runtime is required for authoring or Play.

## Install into a Godot project

P02 direct-install support is pending an owner-published release; earlier public betas may not contain this fix. The following contract applies to a package containing P02. Install the current beta in the Godot project root:

```sh
yarn add --exact --ignore-scripts @papercraftgames/estragon@beta
```

Keep the package where Yarn installs it. Do not copy, symlink or ignore the addon. Before opening the editor, add its full configuration path to the existing `editor_plugins/enabled` list in `project.godot` (preserve other enabled plugins):

```ini
[editor_plugins]
enabled=PackedStringArray("res://node_modules/@papercraftgames/estragon/addons/estragon/editor/plugin.cfg")
```

Godot's Plugins panel discovers candidates under `addons/`; the enabled-plugin project setting accepts a full `res://` configuration path outside that directory. Yarn installation alone does not enable the plugin. Install dependencies before opening Godot; keep only one Estragon tree to avoid duplicate classes/UIDs. Commit the package manifest/lockfile and plugin setting, retaining the package's stable `.gd.uid` sidecars. Godot alone handles editing and Play after installation.

Explicit authored preload aliases reference the chosen installation, for example `preload("../../../node_modules/@papercraftgames/estragon/addons/estragon/runtime/composition/element.gd")` in a Gogo file whose generated script lives three directories below the project root. As with ordinary GDScript, relative authored imports resolve from the **generated script's directory**. Canonical registered widget class names also work after Godot indexes the project. Internal dependencies are script-relative; compiler-injected dependencies are calculated from installed Resources and the actual output directory. A different project-relative installation needs only matching authored imports and the plugin configuration setting; no production source edits. Standard `addons/estragon` placement remains supported.

Author `.gogo` files and normal `.tscn` hosts referencing generated scripts. Optional `gogo.config.json`: `{"version":1,"source_roots":["src"]}`. Native save and main/current Play compile with actual-path validation, invalid/unsavable-source rejection, rollback and repair. Generated files must be rebuilt after relocating an installed addon, just as authored imports must be updated.

[Source-authored Counter example](https://github.com/papercraftgames/Estragon/tree/main/examples/counter), [language](https://github.com/papercraftgames/Estragon/blob/main/docs/GOGO_LANGUAGE.md), [native UI](https://github.com/papercraftgames/Estragon/blob/main/docs/NODE_UI.md), [editor](https://github.com/papercraftgames/Estragon/blob/main/docs/EDITOR.md), [package/release contract](https://github.com/papercraftgames/Estragon/blob/main/docs/PACKAGING.md).

Canonical widgets: EstragonRect/Text/Button/Toggle/HBox/VBox. Class-wide typed Gogo bindables, nested conditionals/keyed lists and bounded bool `bind:value` share one native manager. This is not a complete styling/focus/text/IME/accessibility suite. Target Godot 4.0+; fresh verification is only official Linux 4.0.4 and pinned 4.7.0, no untested platform/minor certification. Current documented older-engine diagnostics and #44 highlighter limitation remain.

MIT. Original copyright and attribution are retained in LICENSE; repository ownership transfer does not alter them. No install scripts, JavaScript compiler, tests, examples, raw Assets or contributor dependencies are shipped.
