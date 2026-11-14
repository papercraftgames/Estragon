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
| `box.gd` / `EstragonBox` | Constructible horizontal stack, shared Box padding/content contract. |
| `hbox.gd` / `EstragonHBox` | X-axis stack with `gap`; children use inherited void `Node.add_child`. |
| `vbox.gd` / `EstragonVBox` | Y-axis stack with the same core and child/lifetime rules. |

These extend `EstragonComponent2D` directly, through Text, or through the shared Box base. Use an explicit `Estragon2D` entry, same-dimensional immediate-parent scope and the [C1 boundaries/lifetime/authority contract](NODE_RUNTIME.md). Plain Nodes interrupt layout; another entry re-enters it. Godot owns rendering/transforms and Node lifetime. There is no Control substitution, RefCounted wrapper tree or custom child-adder.

Length properties now accept numeric values or retained unit strings. See [unit grammar, immediate-parent percentages, viewport/reference units, flex/stretch and offsets](LENGTHS.md). Dimensions default to `"auto"`; fixed dimensions override intrinsic measurement. HBox selects X and VBox Y. Overflow remains visible.

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

## Controlled boolean input (F05-B)

`EstragonToggle` extends the native Button pointer/layout/drawing path with typed `value: bool` and user-only `value_changed(value: bool)`. Programmatic assignments redraw without an edit event; completed enabled primary-pointer activation toggles once. [Two-way Gogo contract/demo and boundaries](TWO_WAY_BINDINGS.md). No Control wrapper, keyboard-focus/text/IME or accessibility expansion is included. Exact evidence/review is in #101/its sole PR.

## L03 — nested Gogo views in parent layout

A normal Gogo component may keep `extends Node2D` and return an HBox, VBox, Text or native Estragon Button. When that host sits in a contiguous same-dimensional layout tree, its **managed view root supplies the host's slot**: natural/fixed dimensions and fill constraints pass through to the parent, which places the real host in sibling order. The returned root is arranged at zero local offset inside that slot. Children do not need a new Entry at every level. See the runnable [Home](../examples/nested_layout/Home.gogo), [Settings](../examples/nested_layout/Settings.gogo) and [Rose](../examples/nested_layout/Rose.gogo), or run `examples/nested_layout/Home.tscn`. The example uses the explicit `UiButton` alias for `EstragonButton`; bare `Button` retains Godot's native Control meaning and is never remapped. L03 did not adapt Controls; L04 below now supplies their automatic compatible 2D slots.

The same stack rules apply through a host: fixed root dimensions override fill; natural dimensions come from the returned participant subtree; root fill flags request the parent's remaining main-axis share/cross-axis allocation. Multiple nested Gogo hosts and a host returning another Gogo host forward through the same mathematical core. Native transforms/lifetime/identity remain real. Layout owns translation of the participating host and returned root; scale/rotation remain native and are not included in intrinsic local size, just as for other participants. Do not author a second translation on a root intended to be parent-arranged.

Only runtime composition hosts registered by the existing external computation manager receive this bridge. An unrelated plain Node/Node2D/Node3D remains a boundary. Only the one managed `build_view` root supplies the L03 host bridge; unreferenced scene-authored/unmanaged siblings are not moved, adopted or projected. E08 separately permits [explicit borrowed scene references](SCENE_CHILDREN.md) in that view, through external logical layout edges while native parent/owner stay unchanged. A plain/non-layout root (including the minimal neutral Node2D/Node3D stub), incompatible dimension, or an explicit Entry root contributes **zero** to the host's parent slot. Such a host can still occupy a zero-size sibling slot/gap; no universal size is invented. Layout descendants below a plain root remain unscoped unless an Entry deliberately re-enters. Return an explicit Entry to own an independent scope/position, or a deliberate plain Node root to opt out of continuity. An independent scope's desired footprint is not inferred by the parent.

A 3D host returning native `EstragonComponent3D` participants uses the analogous shared model/row extents in local world units. It does not introduce Text/Button3D, fill flags not already present on 3D participants, 3D wrapping, pixel-to-world conversion, or cross-dimensional allocation. An incompatible 2D/3D boundary remains unallocated.

The bridge is framework-owned, alongside its existing Computation: weak host lookup plus one coordinator/core, no injected fields/metadata or helper Node on user components. Register before nested view mount so pointer participants find the existing Entry router. Native removal/re-entry unregisters/reconnects the same models. Child content/shape changes invalidate the shared parent model eventfully, reflow later siblings, and do not require parent recomposition or frame polling. Root replacement disconnects the old model/subscription. Managed GGX stays `owner=null`; PackedScene saves authored hosts and remounts their view once after reopening. Native source maps/editor rollback remain unchanged.

L03 supersedes E07's historical plain-Gogo-host boundary proof; archived results are not relabeled. Plain **native** boundaries and explicit Entry independence remain current. L01 adds the [pixel Box model](#l01--pixel-box-model). Percentages (L02) and universal native adapters remain separate. Explicit scene-child projection is now scoped by [E08 #136](SCENE_CHILDREN.md). The focused `tools/check-nested-layout.ts --editor` runner records actual before/after frames, measured slots, native pointer Exit, reactivity/identity/lifecycle, direct Yarn and isolated editor main/current Play/reload. Exact evidence/review state is on [#137](https://github.com/papercraftgames/Estragon/issues/137)/its sole PR. Only Linux official4.0.4/pinned4.7.0 are freshly tested; no physical keyboard requirement or release authorization is introduced.

Exact L03 acceptance: [rendered before/after, measured slots, native input/editor and lifecycle evidence](evidence/L03_NESTED_LAYOUT.md). The live issue/sole PR controls review/merge status.

## L04 — native Control auto-layout

Ordinary Godot Controls now occupy automatic slots as direct or [borrowed](SCENE_CHILDREN.md#native-controls-l04) children of a compatible 2D Estragon Box. Previously HBox ignored a native Button's footprint, allowing the following Rose component to overlap Exit. L04 measures native minimums through the existing coordinator/core. No wrapper, Script injection, extra Node, tag remapping or second renderer is involved. `Button` remains Godot Button; `UiButton` remains the independent Node2D EstragonButton. Naming changes are separate #146.

| Child | Size and placement authority |
| --- | --- |
| Button, Label, LineEdit, TextureRect and other compatible Control | Godot supplies `get_combined_minimum_size()`; Estragon assigns the outer position/size in a Box slot. Godot owns appearance, GUI input, focus, theme and clipping. |
| Native Container | Same outer slot; Godot exclusively measures/sorts its internal Control children. Estragon treats the Container as an opaque leaf. |
| Estragon participant / nested Gogo view | Existing natural/fixed/fill contract through the same mathematical core. A compatible native Control can also be the Gogo view root. |
| Plain Node2D, Sprite2D, Polygon2D, nonvisual Node | No automatic footprint or gap. Native authored position remains authoritative. |
| Node3D / meshes / physics | Existing explicit world-unit participant/adapter contract; no automatic Control pixel conversion. |

For bounded geometry, `EstragonNative2D` measures one direct Polygon2D's transformed vertices/offset; `EstragonNative3D` measures one direct MeshInstance3D's transformed AABB. These explicit adapters never stretch the visual. `observe_native` uses CanvasItem rect/Mesh changed signals where available; Polygon edits require `invalidate_native()`. See [supported providers and bounds](NODE_RUNTIME.md). Arbitrary visible nodes do not acquire a guessed size.

### Natural minimum and allocation

Native text/font/theme/texture and `custom_minimum_size` determine the **natural minimum**. An empty Control with zero native minimum stays zero; authored `size` is not a preferred-size input. Use `custom_minimum_size={Vector2(160,40)}` for intentional empty geometry. Estragon writes `position` and `size` as **outputs** while the Control participates. Reading those assigned values back as intrinsic size would create a feedback loop.

Default native `SIZE_FILL` stays natural. Explicit `SIZE_EXPAND_FILL` on either native size_flags axis requests that axis's existing Box fill allocation. This is a deliberately small subset: other flag combinations remain natural; native stretch ratios/shrink alignment are not translated into a new Box algorithm. Inside a native Container, Godot supports its normal full flag semantics. Controls retain native properties: author unit `width`/`height`, `flex`, `stretch` and `gap` on the surrounding Estragon Box. Fixed Box dimensions override its corresponding growth/stretch request. Native minimum floors reserve space before equal sharing; insufficient fixed outer space permits sequential overflow rather than shrinking a native Control below its minimum. L04 adds no custom Control percentages/max constraints/margins/padding API. L01 separately adds [Estragon participant insets](#l01--pixel-box-model).

`minimum_size_changed`, `theme_changed`, `size_flags_changed`, visibility and guarded native rect changes schedule coalesced deferred measurement. Native changes reflow affected branches without rerunning Gogo functions. Self-authored Gogo bindables still use ordinary recomposition. Writes compare against the last assigned rect and suppress their own resize feedback; idle frames do no minimum reads or layout passes. A custom Control whose intrinsic data changes without a native signal must call Godot's `update_minimum_size()`. Runtime changes to unsupported coordinate configuration must likewise notify minimum-size invalidation; arbitrary ancestor transform changes are not globally observed.

### One rectangle owner

Supported Controls use zero anchors, zero local rotation/pivot, unit local scale and `top_level=false`, in the same native canvas/viewport as their logical Box. Native offsets are the position/size representation written by allocation. Do not simultaneously animate or manually author a participating outer rect; external rect edits cause the Box to restore its allocation. Shared transformed native ancestors remain Godot-owned. Borrowed controls support translated logical/native parent bases, not different rotation/scale bases.

Nonzero anchors, local pivot/rotation/scale, top-level coordinates, incompatible CanvasLayer/viewport/bases or an actual native Container parent cause a bounded warning and exclusion from the Box. Anchors/transforms/flags are never silently reset. A released or newly ineligible Control restores its pre-allocation rect if it still has the same native parent. Its native visibility/input/lifetime continue normally; exclusion does not hide or free it. Remove it from the returned Box or use an ordinary plain boundary for deliberate native manual positioning. General reactive offsets/transforms remain #88.

Borrowing never changes native clipping, CanvasLayer, Z, visibility or draw/input ancestry. Native Controls separated by Node2D Boxes can be distinct Godot GUI roots: author native `focus_next`/`focus_previous` NodePaths to cross those roots. The bridge preserves those links and native keyboard activation/text input; it does not synthesize a focus graph or dispatch Control clicks through Estragon's custom-button pointer router.

### Runnable examples

Run [NativeHome.tscn](../examples/nested_layout/NativeHome.tscn) for the owner's flexible-spacer Home/Settings/Rose arrangement using a native Exit button. [Home.tscn](../examples/nested_layout/Home.tscn) retains the UiButton version. [NativeGallery.tscn](../examples/nested_layout/NativeGallery.tscn) demonstrates all snippets below, a native Container, a generated Settings component and an owned Scene-dock Button. Keep the normal explicit Element/Box imports shown in its Gogo source; native class tags need no alias.

```gogo
func exit() -> void:
    get_tree().quit()
func build_view() -> Element:
    return <HBox gap={8.0}>
        <Button text="Exit" pressed={self.exit} />
        <Label text="Ready" />
    </HBox>
```

```gogo
<VBox gap={8.0}>
    <LineEdit placeholder_text="Native editing" />
    <TextureRect texture={self.picture} />
</VBox>
<HBoxContainer><Label text="Left" /><Label text="Right" /></HBoxContainer>
```

The TextureRect's texture supplies its natural minimum under Godot's native expand mode. The example creates a 64×24 ImageTexture in `_ready`. `<NativeSettings />` returns an HBox/native Button and inherits its parent's Entry; it needs no independent Entry. [Exact focused Linux evidence](evidence/L04_NATIVE_CONTROLS.md) distinguishes native graphics/editor proof from manual-interactive or release certification.

## Responsive layout

Use `<Entry2D width="100vw" height="100vh">`, parent-relative unit dimensions, and weighted `flex` with cross-axis `stretch`. [Complete contract and migration](LENGTHS.md). Native `get_viewport_rect()` expressions remain composition snapshots; unit specs resolve from viewport signals without recomposition.

## L01 — pixel Box model

`EstragonBox` is a constructible horizontal container. `EstragonHBox` and `EstragonVBox` extend it and select horizontal/vertical stacking; `Entry2D` also inherits its content-box properties. All remain real Node2D instances using one coordinator and mathematical core. Use canonical class tags or explicit preload aliases (`Box`, `HBox`, `VBox`); Godot's native `Container` is still opaque and retains its own internal layout.

```gogo
<VBox width={400} height="300" padding={16} padding_top={24} gap={12}>
    <HBox height={60} margin={8} margin_left={12} />
    <Rect width={100} height={40} margin_bottom={8} />
</VBox>
```

Lengths use the [shared numeric/string contract](LENGTHS.md). Width/height are border-box bounds including padding and excluding margin. Shorthands default to zero; individual edge overrides default to `"auto"` and inherit the shorthand. Explicit zero edges override independently of assignment order. Invalid native writes diagnose and retain valid state; GGX rejects before commit.

Auto measurement sums child outer extents along the stack axis, takes the largest outer extent across it, adds gaps once, then adds container padding once. Fixed bounds may be smaller than natural content. Arrangement subtracts padding from bounds and clamps each available content axis at zero. Main-axis child margins and gaps are reserved before weighted flex sharing; cross-axis fill subtracts that child's cross margins. Native Control minimum floors still apply. Fixed/natural children and minimum-constrained native Controls overflow sequentially when insufficient space remains; a zero-minimum flex child can receive zero pixels. Padding does not clip drawing or native input. There is no margin collapse, negative spacing or implicit child shrink.

Children start at the content origin plus their leading margin. Cross-axis alignment remains leading; `center` centers the complete outer row (including margins/gaps) inside the content rectangle and retains its existing symmetric overflow behavior. Margins affect parent measurement/allocation only, never the child's painted/hit bounds. A scope root's own margin has no parent to consume it. Nested Gogo hosts forward a managed root's margin once to the parent; their returned root stays at local zero. Layout retains native ownership/transforms and translates the real participating Nodes; pointer routing uses those native transforms.

Padding belongs to Box/Entry containers. Text and UiButton retain their existing font measurement and UiButton's intrinsic text inset; they do not acquire container padding or text wrapping. Margin applies to Rect/Text/UiButton/Box and other EstragonComponent2D subclasses. Native Controls use their L04 minimum/size-flags API and do not gain custom properties. Bounded 3D native geometry remains in world units; authored lengths use the explicit scale in the [shared contract](LENGTHS.md). Changes invalidate affected branches through existing signals/deferred flushes, without idle polling or a second layout/reconciliation path.

Run [BoxModel.tscn](../examples/box_model/BoxModel.tscn) to change padding with a retained UiButton while keeping the explicit left edge fixed. The colored row demonstrates outer margins separately from inner padding. [Focused L01 runner](../tools/check-box-model.ts) uses fresh direct-Yarn consumers and isolated editor/game settings; exact review evidence is maintained on #55/its sole PR.

[Exact L01 native acceptance, rendered geometry and editor/compile evidence](evidence/L01_BOX_MODEL.md). Both approved Linux engines pass the scoped proof; live issue/sole PR controls review and merge state.
