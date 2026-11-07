# Native Gogo editor workflow

Enable the Estragon plugin in a Godot project containing the addon. For a direct Yarn install, enable `res://node_modules/@papercraftgames/estragon/addons/estragon/editor/plugin.cfg` in `[editor_plugins] enabled=PackedStringArray(...)` in `project.godot`. Keep the addon inside `node_modules`; no copy, symlink or `.gdignore` over the package is needed. Dependency installation alone does not enable a Godot plugin. See [packaging](PACKAGING.md).

Author GDScript-first `.gogo` files and run scenes normally. Save and both main/current Play paths compile with Godot alone; normal editing needs no Node/Bun executable, external compiler or language server. `gogo.config.json` source roots are authoritative; otherwise discovery uses the documented project exclusions.

## Create a script

Use **Project > Tools > New Gogo Script…**. Choose a project directory and filename, then the Node2D or Node3D starter. Both templates import the composition `Element` and a native layout entry; Node2D includes a text greeting. Imports are computed relative to the generated `.gd` directory and the actual installed resources, including direct Yarn and relocated addons. Attach the generated script to a matching native host to run it.

The dialog appends `.gogo` when no extension is supplied. It rejects another extension, existing files/directories, missing directories, unsafe/excluded paths and locations outside configured source roots. It never overwrites source; cancel writes nothing. Fix invalid configuration or choose an eligible directory before creating a file. The addon scans the filesystem and opens the new source in the stock Script Editor.

## Highlighting and completion

Authenticated Gogo tabs use theme colors for GDScript keywords/types, annotations, functions, numbers, strings/comments and symbols, plus GGX tags, attributes and embedded expressions. A tolerant line cache carries multiline string/comment/tag/expression state, rescanning the changed suffix. Incomplete code remains editable without a successful compile. Quoted markup and `<` comparisons remain code/string contexts. Undo, redo and buffer replacement invalidate the cache.

Use Godot's completion shortcut (**Ctrl+Space** in the default Linux keymap) or type a member dot, tag opener, annotation or identifier. Suggestions appear in the native CodeEdit popup; native selection, insertion and undo/redo apply. Coverage includes keywords, annotations, declarations, known native/global classes, imported constructible Node aliases, closing tags, writable native/lexical attributes and signals, `key`, supported bool `bind:value`, `self` and explicitly typed members, including inside GGX expressions. Closing-tag candidates include `/` because native CodeEdit treats it as part of the replacement word. Comments, strings and plain markup text do not request code suggestions.

Completion reads ClassDB and lexical declarations/imports; it never instantiates authored scripts. It refreshes for buffer, import/filesystem, source-path and scene-context changes. This is bounded static assistance, not GDScript language-server parity: unknown receivers, arbitrary return-type inference, dynamic collections and complex nested scopes have no promised member inference. Native built-in value types do not expose ClassDB member metadata. Unknown information must not invent members. Ordinary `.gd` tabs retain their native services.

## Diagnostics, save and Play

After a short idle, lightweight native parser/bindable analysis marks authored source lines with a dedicated **!** gutter. The Gogo bottom panel labels this **syntax-only typing feedback**, separate from verified build/semantic validation. Click a panel diagnostic or gutter marker to navigate to its authored `.gogo` line/column; UTF-16 compiler columns are converted to Godot Unicode caret columns. Repair clears the markers. No debugger breakpoints or unrelated editor marks are changed. Godot 4.0's public API does not expose arbitrary language-service squiggles on a stock CodeEdit, so the visible line gutter is the supported presentation.

The plugin saves current Gogo buffers before both Play paths even with native autosave disabled. Unsavable files, syntax/type/handler failures block stale execution and retain authored diagnostic messages. Staged multi-file publication validates actual-path semantics, generated code/maps and dependent resources, refreshes existing Scripts in place and restores bytes/maps/timestamps/cache identity on failure. Repair recovers normal Play. Stable UIDs and no-op output identity are preserved. F04 uses one description compiler for all GGX; retired Node-returning view declarations are rejected. See [cutover](F04_CUTOVER.md).

## Native API boundaries and lifecycle

The public ScriptEditor API on 4.0 has no TextFile-opening entry point. Creation/navigation therefore use a bounded bridge: FileSystemDock selects an exact full path, then the selected public Tree/ItemList emits its native activation signal. No private editor method, guessed basename or menu injection is used. This bridge is version-bounded to Godot 4.0–4.7, with fresh evidence only on the two approved engines; unknown newer versions select the file without pretending to open it. The preexisting owner-accepted hidden never-associated tab limitation [#44](https://github.com/papercraftgames/Estragon/issues/44) remains: reveal and activate that tab to authenticate it. No fix/PASS claim is made for that case.

Disable removes the tool action/dialogs, completion handlers and owned gutters, restoring each CodeEdit's prior completion settings. Multiple visible/previously associated Gogo tabs and project restart are covered by focused editor tests. The text-file extension preference is global and persists after disabling; preserve existing values and never erase user preferences.

Native GGX builds at startup before scene restoration. Isolated preflight is unavailable on 4.0.4; mandatory actual-path validation and rollback remain. Running-app hot reload/new inherited defaults are not promised. Live preview and debugger remapping remain future work.

## Focused verification

`tools/check-editor-ux.ts` packs exact tracked addon bytes, installs with Yarn directly into a fresh isolated project and drives the real stock editor/menu/dialog/CodeEdit and main/current child games. It checks completion insertion/undo/redo, highlighting, diagnostics, ordinary `.gd` isolation, plugin lifecycle/restart, rejected creation and failed-Play identity preservation. Two additional template-only path probes cover ordinary `addons/estragon` and a nonstandard location; these are not repeated editor certification suites. Package bytes/UIDs must remain unchanged.

The opt-in **Focused Gogo editor UX** workflow runs Linux 4.7 development checks or bounded 4.0.4/4.7 acceptance by explicit PR label. It does not expand routine CI or the seven-stage release gate. Software OpenGL/Xvfb supplies the editor display; Mesa software Vulkan satisfies stock 4.7's startup RenderingDevice capability probe even under OpenGL. Native errors fail the run; only the expected failed-build callback from deliberate invalid-source Play is accepted. Exact results, screenshots, source/engine hashes and manual-interactive smoke status belong to [#115](https://github.com/papercraftgames/Estragon/issues/115)/its sole PR. Physical keypress tests are not required. Tests use isolated settings and never enable the addon or change preferences in this checkout. See [testing](TESTING.md) and [CI budget](CI_PERFORMANCE.md).
