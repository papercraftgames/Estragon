# Native 2D UI — canonical C4 API

> **F04 current composition path:** the canonical Counter uses a typed `build_view() -> Element`, generated bindable getter observation and the sole external manager. Eager GGX and per-target bindings are removed; see [cutover/parity](F04_CUTOVER.md) and live #98/its PR for verification/review. Native widget/layout APIs below are retained.


[C3 #81](https://github.com/resistdesign/Estragon/issues/81) implements the existing minimal UI slice as production Node2D components. It builds on merged C1/C2 and the same shared mathematical core used by the 2D/3D runtime and proof paths. This is a bounded usable slice; broader widgets, focus/keyboard/touch, accessibility, rich text/wrapping, themes and general styling remain outside C3. Current native-addon release acceptance is tracked in #83; historical C01 verdicts remain archival facts.

## Run the Gogo Counter

Open the repository in an approved Godot editor with the Estragon plugin enabled. Open `examples/counter/Counter.tscn` and Run Current Scene. Edit `examples/counter/Counter.gogo`; normal saved builds and compile-before-Play use only Godot and the bundled addon. Checked-in generated GDScript/maps let the scene open before the first rebuild. No Bun/Node/compiler executable setup is required by users.

Click **+**: Count changes and Reset enables. Click **Reset**: Count returns to zero. Resize the window: the accent and nested action row follow the viewport; buttons share the available width. The label and buttons retain identity and subscriptions. The Counter reads bindable count in its view; the manager applies changed Count/Reset declarations to retained Nodes. Input uses named native pressed handlers. Managed output is transient owner=null; PackedScene persists the authored host and reconstructs output once on mount.

## Public components

All paths below are relative to `addons/estragon/runtime/node/`. Use explicit preload aliases in `.gogo` as shown in the Counter; registered class names are also supported by C2. Names have ordinary native/import meaning; there is no reserved legacy tag table.

| Script / registered name | Contract |
| --- | --- |
| `rect.gd` / `EstragonRect` | Native rectangle drawing with `fill: Color`; natural size zero, explicit/fill dimensions. |
| `text.gd` / `EstragonText` | Native `Font` measurement/drawing, `text`, `font`, positive `font_size`, `color`; explicit newlines only. |
| `button.gd` / `EstragonButton` | Text plus fixed 14×8 pixel internal padding, native `pressed` signal, `disabled`, background hover/held/disabled states. |
| `hbox.gd` / `EstragonHBox` | X-axis stack with `gap`; children use inherited void `Node.add_child`. |
| `vbox.gd` / `EstragonVBox` | Y-axis stack with the same core and child/lifetime rules. |

These extend `EstragonComponent2D` directly or through Text. Use an explicit `Estragon2D` entry, same-dimensional immediate-parent scope and the [C1 boundaries/lifetime/authority contract](NODE_RUNTIME.md). Plain Nodes interrupt layout; another entry re-enters it. Godot owns rendering/transforms and Node lifetime. There is no Control substitution, RefCounted wrapper tree or custom child-adder.

Width/height `-1` means natural; finite nonnegative values are fixed. A stack sums its children's natural main-axis sizes plus gaps, takes the cross-axis maximum, and includes its own intrinsic content. Fixed dimensions override natural measurement. `fill_width`/`fill_height` apply only on natural axes: main-axis fill children share nonnegative remaining space equally after fixed/natural siblings and gaps; cross-axis fill takes available space. Overflow remains visible, with no implicit clipping or negative allocation. This bounded rule is not CSS Flexbox. HBox selects X, VBox Y; existing proof/3D X defaults remain intact. No 3D wrapping/unit decision is implied.

Text caches native Font metrics until text, font, font size or `Font.changed` invalidates them. Resource subscriptions connect/disconnect with native lifetime and font replacement. Layout changes invalidate the affected branch and coalesce on the existing coordinator; unrelated measurements stay cached. Paint-only colors and button pointer state queue redraw without layout. Idle trees do no layout work; no `_process` polling.

Primary pointer press captures one live enabled button, then release over that same button emits once. Inverse native canvas transforms determine the hit. Entry-scoped weak registration avoids ownership cycles. Disabled buttons occlude lower buttons, and removal, visibility change, disabling and Window focus loss cancel capture. Effective native Z and tree order select overlapping buttons within one entry. This is bounded primary-mouse input, not focus/navigation or general input arbitration between multiple entries/CanvasLayers. Native signal connections and identity survive reflow and explicit scene ownership survives pack/reload.

## Verification and evidence

`tools/check-native-ui.ts` runs isolated Godot-only build, native runtime assertions, real editor save/unsaved main/current-scene Play and negative semantic/source-map/save-failure repair, then graphics-backed Counter captures. PATH contains no external compiler. Linux acceptance uses only official 4.0.4 and pinned 4.7.0 with Xvfb/Mesa. Unexpected errors, missing completion markers and native leaks fail the runner. See [commands](TESTING.md#c3-native-2d-components-and-counter). Current execution links and exact outcomes are recorded on #81 and its review PR; no untested platform/minor is certified. Captures cover zero, incremented, and reset/resized states. Headless editor assertions alone are not visual evidence.

## C4 removal inventory

C4 [#83](https://github.com/resistdesign/Estragon/issues/83) follows merged C3 PR #82. The branch replaces the transitional native widget names with canonical EstragonRect/Text/Button/HBox/VBox under runtime/node/{rect,text,button,hbox,vbox}.gd. The shipped Counter is now examples/counter/Counter.tscn and the project main scene. Its explicit preload aliases target these canonical classes; Button alone retains its ordinary Godot meaning. There is no hidden short-tag mapping or compatibility alias.

| Retired path/requirement | Replacement / disposition |
| --- | --- |
| runtime/display_object, container, stack, legacy rect/text/button/hbox/vbox plus UIDs | Native Node2D widgets and composed mathematical core; Node.add_child/native lifetime/owner tests. Deleted. |
| runtime/surface, canvas_renderer, paint_list, pointer_dispatcher, gogo_view | Native drawing/font/input and entry-scoped weak routing. Deleted. |
| compiler legacy factories/leaf/literal/callback branches, native_node selector and native validator/emitter forwards | One native typed validator/emitter plus static resolver. Deleted. |
| stage-0 XML/JSON source/IR/interpreter and tools/gogo, transpile/build/reference compiler/tests/commands | Godot-only normal Gogo/Node composition; T10 retirement requirement coordinated here. Deleted. |
| Old hello/compiled/mixed/layout/interactive and legacy Counter consumers/generated assets | Native Counter main scene and normal Gogo 2D/3D demos. Deleted/replaced. |
| B1 compiler proof, B2/B3 duplicate visual/adapters/forwarding shims and executable consumers | Current native C1/C2/C3 runtime/editor/graphics and retained pure core math/metadata tests. Deleted/replaced. |
| Legacy frontend/generation/runtime/editor fixture suites and failure-exemption collectors | Current native compiler lexical/type/map/publication/rollback, real editor/highlighter/Play, current layout/input/identity/owner coverage. Replaced. |
| Standalone executable export and discontinued distribution scene/raw-string/helper gates | Fresh cache-free addon install, native source-only rebuild/current scenes and native resource-pack integration. Removed requirement, not historical failure relabeling. |
| C01/B1–C3 reports, source snapshots and R01 research | Preserved as explicitly Godot-ignored archival evidence; no active product dependencies or tolerated Logger errors in current imports. |

Current acceptance and actual verdict are recorded on #83 and its sole PR; [TESTING](TESTING.md) defines the native-addon gate. C4 is a review submission, not Done until owner review/merge. It does not implement broader widgets or bindings and does not authorize publishing.

Current [dynamic observed composition](REACTIVE_GGX.md) use these native setters and their existing redraw/affected-branch invalidation; no parallel layout engine or position authority is added.
