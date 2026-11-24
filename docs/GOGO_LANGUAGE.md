# Gogo and GGX — one description composition contract

**D07 import-selected Button:** `<Button>` means EstragonButton when explicitly imported from `runtime/node/button.gd`; without that import it remains Godot Button. Compatible native Controls automatically occupy 2D Box slots through native combined minimum sizes, including inside nested Gogo views and borrowed Scene-dock children. Native Containers remain opaque outer participants; their internals use Godot's layout. Plain Sprite/Node2D/nonvisual/3D tags do not gain universal dimensions. See the [developer comparison, working snippets and runnable native gallery](NODE_UI.md#l04--native-control-auto-layout), and [scene-owned Control rules](SCENE_CHILDREN.md#native-controls-l04). Native `size_flags=EXPAND_FILL` is a bounded fill request; Box unit lengths and grow/stretch are not properties on native Controls. Estragon owns compatible outer rects; Godot retains native GUI/theme/focus and Container interiors.

Gogo is a GDScript-like language in `.gogo`; GGX is its namespace-free syntax for describing native Godot Nodes. The bundled Godot compiler/editor emits typed, source-mapped GDScript. Normal editing and Play require only Godot and the addon.

> **ADR-0031 implementation boundary:** [CORE-01](CORE01_REACTIVITY.md) implements function memoization/GGX-aware reactivity in this change. Implicit two-way controls and CORE-02 data conversion remain accepted targets. The live #195 PR determines merge status.

### Gogo function behavior and remaining accepted targets

- A Gogo function containing **actual authored GGX** is automatically a reactive render function, even if it takes zero arguments. Bindable reads in its body (including locals/conditionals) invalidate its cached Element **structure**. Multiple call sites/mapped keyed occurrences mount independent native Nodes; a conditional child that changes type reconciles normally.
- Calls to **ordinary functions without GGX** during rendering are memoized by their explicit arguments only, including ordinary imported `.gd` helpers. A zero-arg ordinary helper is static; it does not observe hidden state. A manually assembled `Element.new(...)` or a Dictionary shaped like an element is not GGX and does not confer render-function semantics. Event handler references execute on events, not during rendering.
- `<Toggle value={self.show_details} />` is implicitly **two-way** when both properties are writable/`@bindable` with appropriate change signals. There is no intended final `bind:` syntax. With `var snapshot := self.show_details` and `<Toggle value={snapshot} />`, the source getter still invalidates the view but the control cannot write back to the original model property; this is one-way. Non-invertible expressions such as `value={not self.show_details}` are also one-way.
- Optional typed Gogo `ArrayCollection` receives nested upward notifications through bindable members. Gogo compiled typed assignments accept compatible raw Dictionary/Array data and hydrate statically declared model/collection destinations automatically. Declared defaults apply to absent keys. Generated `to_data()` exports plain nested data; incompatible types error. No custom constructors, user serializers, general union type or cast ceremony.

The function rules above describe CORE-01 source; implicit two-way binding and typed data handling remain **design acceptance**, not current compiler capabilities. See [ADR-0031](DECISIONS.md#adr-0031--ggx-implied-reactive-render-functions-automatic-memoizationbinding-and-observable-typed-data).

[F04 #98](https://github.com/papercraftgames/Estragon/issues/98) cuts over all supported consumers to this contract after merged F01–F03. The live issue/PR records acceptance/review; F05-A is merged (#100); F05-B (#101) adds the bounded controlled bool binding below, with verification/review in its live issue/sole PR; F06 is merged in #105 (`55156fb`); [profiling evidence](F06_PROFILING.md). See the [cutover/removal/parity report](F04_CUTOVER.md) and [architecture](REACTIVE_COMPOSITION_ARCHITECTURE.md).

- **Every GGX expression returns an Element description**, including ordinary helpers/lambdas, conditional branches and for/map callbacks. No eager native factory mode or target-owned binding helpers remain. Use an explicit `Element` preload alias from `runtime/composition/element.gd`.
- A Node host automatically composes its zero-argument `build_view() -> Element`. Typed Gogo bindable getter reads, including own reads in GGX-containing helpers and external models; ordinary helper bodies stay opaque, register dynamic dependencies. Their native signals queue only interested functions. One external parent-first manager reconciles retained native Nodes; no per-frame render, hooks or manual refresh.
- Tags resolve constructible native Node types, registered script classes, normal explicit preload aliases, or unique eligible project Gogo source names (see E07 below). Use canonical EstragonRect/Text/Button/HBox/VBox or explicit aliases. Unimported `Button` is Godot's Button; an explicit Script preload selects that lexical import. Resources/models are values, not native hierarchy children.
- Attributes use native property/signal metadata. Strings use quoted literals, typed expressions use braces. Events use named handlers/Callables; inline anonymous GGX event declarations reject. Unknown/duplicate/read-only/reserved props, invalid native types or required constructors fail with authored diagnostics and actual-path semantic validation before Play. Native Godot imperative constructors/scene operations remain valid outside declarative output.
- Child expressions accept Element/null/nested Arrays and eligible borrowed scene-child Nodes ([E08](SCENE_CHILDREN.md)), flatten left to right, and preserve authored positional slots and null holes. For/map use native GDScript syntax. Optional sibling-scoped `key` accepts int or nonempty String and never becomes a native property/metadata. Duplicate keys and bad dynamic entries preflight before commit. See [F02](F02_CONDITIONALS.md), [F03](F03_LISTS.md).
- `@bindable var count: int = 0` generates ordinary typed native getters/setters and per-property change signals in Gogo only. Code-only non-Node models remain valid. See [bindable semantics](BINDABLE_PROPERTIES.md). Raw Array/Dictionary mutations do not inherently notify; reference reassignment does. External native fields require a real signal adapter for automatic observation.
- Helpers are repeatable description computations. Effects belong in events/lifecycle methods. Nullable model expressions use native conditionals/fallbacks. Old Node-returning `build_view` GGX rejects; description values passed to native Node APIs reject through typed semantic validation. There is no compatibility wrapper or second renderer.
- Managed output is transient `owner=null`. Native scene ownership persists authored hosts/foreign objects; the view reconstructs once on mount/reload. Commit retains compatible IDs, native state/animation and unchanged desired props/handlers. Existing composed layout and transform authority remain; #88 is separate.

F05-A class-wide `@bindable` (#90) is a standalone preamble marker before `extends`/`class_name`, expanding eligible owned typed instance fields through the existing property lowering. Native exports are retained; inherited/untyped/inferred/static/local/inner fields stay ordinary. Typed custom/deferred accessors reject; explicit class+property coverage is idempotent. See [exact eligibility/grammar](BINDABLE_PROPERTIES.md#class-wide-annotation-f05-a) and live issue/sole PR for verification/review. UI-02 supports implicit `value={self.model.enabled}` for typed writable/observable Bool endpoints on Checkbox/Toggle; authored `bind:*` is removed; see [exact grammar/timing/ownership](TWO_WAY_BINDINGS.md). Broader input types, observable in-place collections, serialization remain future scoped work; bounded F06 profiling/optimizations are merged. No `.gd` custom annotations or `.bgd`, mandatory Repeater or immutable data tree.

Current verification uses only official Linux 4.0.4 and pinned 4.7.0, exact native source maps/UID/cache transactions, saved/unsaved main/current Play rejection/repair, real rendering and fresh/cold/pack proofs. See [testing](TESTING.md), [editor](EDITOR.md) and the live task evidence. No untested platform/minor claim.

Internal addon dependencies are script-relative. Generated dependencies are calculated from the installed Resource paths and generated destination; authored relative imports resolve from that destination as in ordinary GDScript. Native compiler API `compile(text, source_name, output_path)` accepts an explicit output path when it differs from the usual sibling `generated/<name>.gd`; source_name remains the authored diagnostic/map identity. In-memory semantic consumers must assign the corresponding GDScript resource path before reload. For pathless diagnostic names the default generated context is the project root. See [direct Yarn installation](PACKAGING.md).

The editor’s installed component catalog can insert explicit preload aliases and the Element type on deliberate completion acceptance. These remain ordinary visible Gogo declarations, not reserved short-tag factories or native Button remapping. Names/paths are resolved from actual installed resources and generated output; see [editor intelligence and public API limits](EDITOR.md#e03-discover-components-and-accept-imports).

## Project component tags (E07)

A saved, eligible `Settings.gogo` in the configured Gogo source roots can be used as `<Settings />` from another Gogo file without a manual preload, `class_name`, editor popup, or prior scene attachment. The source filename supplies the **case-sensitive** tag name. This works on a fresh headless build before any generated Settings Script exists. Compiler/build source discovery uses the same exclusions and containment rules as creation and scene authoring; generated/vendor/test/package directories are not project component catalogs.

Start both files with **New Gogo Component (2D)…** so their Element imports are already correct for the actual addon location. Keeping those imports and host declarations, replace only the functions:

```gogo
# Settings.gogo
func build_view() -> Element:
	return <Node2D name="SettingsGroup" />

# Home.gogo
func build_view() -> Element:
	return <Settings name="SettingsChild" />
```

The compiler emits mapped, hygienic private native Script imports relative to the **consuming generated `.gd` directory**. Native Script resources, typed properties/signals and the existing description reconciler remain authoritative. A child's own typed `build_view` mounts normally, observes its bindables, retains identity across unrelated parent updates, and disposes its records/subscriptions when removed. No external compiler, ScriptLanguage, special factory runtime or user-Node metadata is added. This is type discovery for tags, not automatic imports for arbitrary ordinary GDScript expressions/type annotations.

Explicit preload aliases choose their declared resource. Native-name Script imports use source-mapped private generated symbols because GDScript rejects shadowing built-in classes; authored spelling and selected resource remain authoritative. Duplicate filenames, local declarations, and different native/global symbols with the same unqualified name are ambiguity errors at the tag; there is no nearest-directory or first-match rule. A global `class_name` and project name pointing to the same generated Script are one identity. Missing global-script cache entries cannot reserve names or supply stale executables. Native class constants such as `const NativeGroup = Node2D` provide an explicit native spelling when a project filename collides. Without an explicit import, `Button` means the native Godot class; a colliding project source requires disambiguation. See [import-selected Button](BUTTON_IMPORTS.md) for both kinds in one file.

For two Settings sources, choose the desired path in completion, or declare distinct ordinary aliases. For example, from `app/Screens/Home.gogo`, generated imports resolve from `app/Screens/generated/`:

```gogo
const AccountSettings = preload("../../Account/generated/Settings.gd")
const GameSettings = preload("../../Game/generated/Settings.gd")
# Use <AccountSettings /> and <GameSettings />.
```

Completion computes these paths automatically. Existing mapped UID preloads resolve to the same source/native Script identity. The emitted literal uses that resource-relative path on both engines because 4.0.4 cannot open Script UID preloads directly; the authored UID declaration stays intact. Generated artifacts are implementation details; deleting/moving a source must not make an explicit old import select another same-named component. Rename the tag or deliberately select/reimport the new source. Source-root exclusions, invalid/non-Node/abstract/required-constructor components, self-reference and circular source/preload graphs reject before publication. Optional constructor arguments remain valid. One coherent source snapshot and dependency order feed the existing native actual-path transaction, maps, stable UIDs and cache rollback. On 4.0.4, isolated preflight and link introspection remain unavailable as documented; actual-path validation and lexical containment still apply. No stronger untested symlink guarantee is implied.

### Native layout through Gogo hosts (L03)

A normal Gogo Node2D/Node3D host now forwards its managed same-dimensional layout-participant view root into an existing parent Estragon scope. Return HBox/VBox/Text/EstragonButton directly; no child Entry is required. Parent layout measures the root and places the real host once, then allocates the root at zero local offset. Root natural/fixed/fill constraints, child reactive reflow, native identity/input and multi-level composition share the existing mathematical core. See [complete layout contract/example](NODE_UI.md#l03--nested-gogo-views-in-parent-layout).

Unrelated plain native Nodes remain boundaries. A non-layout/plain root, incompatible dimension, or independent Entry root contributes zero to the host's parent slot; explicit Entry keeps its separate scope/position. The neutral minimal templates remain unchanged, with no Entry/text/layout defaults. Scene-owned child projection via {get_children()} remains separate #136. E07's archived zero-size plain-Gogo-host result is historical and is superseded by L03's live issue/PR acceptance; it is not retroactively changed to PASS.

L01 [pixel Box layout](NODE_UI.md#l01--pixel-box-model) adds inherited typed numeric padding/margin edges, shared constructible `EstragonBox`, border-box dimensions and deterministic edge-over-shorthand precedence. L06 extends these to retained numeric/unit-string lengths with authored-span errors and whole-tree dynamic preflight; see [the current contract](LENGTHS.md). Use the [runnable example](../examples/box_model/BoxModel.gogo); native Controls and 3D geometry retain their existing bounded contracts.

L06 [unit lengths](LENGTHS.md) accepts numeric expressions and retained unit strings on registered Estragon length properties, including inline elements. Literal diagnostics and dynamic whole-tree preflight share one parser.

## Ordered attribute spreads (S03)

GGX opening tags accept `{...expression}`. The expression is ordinary native
GDScript and must evaluate to a Dictionary. Variable names have no special meaning:
`{...props}`, `{...style}` and `{...theme_values}` use identical grammar.

```gogo
func panel_values() -> Dictionary:
	return {"background_color":"#252b38", "padding":"12px", "min_width":"280px"}

func build_view() -> Element:
	var emphasis := {"border_color":"#8295bc", "border_width":"2px"}
	return <VBox {...panel_values()} padding="20px" {...emphasis}>
		<Button {...{"text":"Continue", "min_height":"36px", "pressed":pressed}} />
	</VBox>
```

Use ordinary explicit preload aliases for Element and component types, as in
[SpreadGallery](../examples/spreads/SpreadGallery.tscn). Unimported Button remains Godot's
native Button. Dictionaries may come from variables, constants, functions, modules
or inline expressions. Whitespace, GDScript comments, quoted text and nested
braces retain native lexical rules. This form is only legal in the opening tag's
attribute list; it adds no spread syntax to ordinary arrays, calls or expressions.

Each expression executes once, left to right, including named expressions. A
shallow Dictionary snapshot is taken at each spread's evaluation point, so a later
expression mutating the same Dictionary cannot rewrite an earlier contribution.
Values keep native reference semantics. Later assignments win across spreads and
named attributes; a later spread can override an earlier named value. Duplicate
explicitly written named attributes still reject. There is one final property or
handler per normalized name; overridden values are not sent to native setters.

Keys must be nonempty String/StringName names matching writable destination
native/script metadata. Native properties such as name/visible, Estragon lengths
and local paint fields, and native Callable signal values all use the existing
contracts. Text color remains native Color; background_color accepts its existing
Color/hex forms. Unknown/read-only/reserved names, bad types/lengths/colors/policies,
invalid handlers and Rect fill+background_color conflicts reject before any live
Node edit. Keys named `key` or any removed `bind:*` name cannot come from
spreads. Author those explicitly; keyed lists and controlled bindings still work
beside spreads, and binding conflicts are validated after expansion. Explicit event
attributes still require named handlers/Callables, without inline anonymous events.

Runtime Dictionary keys/types cannot be proven by compilation alone. The compiler
checks syntax and explicit attributes; actual-path native semantic validation
checks expressions; complete-description preflight checks expanded values before
commit. Diagnostics retain each final attribute's authored source and spread key.
Native named-method signal arity metadata is checked on both approved engines;
custom bound/unbound/lambda Callables retain native invocation semantics where
portable method metadata is unavailable. Callable validity/lifetime and owned
connect/disconnect checks always apply.

Bindable getter reads inside spread computations use the same existing observation
scope. Reassign a Dictionary reference to signal a change:

```gogo
var next := self.props.duplicate()
next["padding"] = "24px"
self.props = next
```

Raw in-place Dictionary mutation does not notify automatically. No proxy, observer,
style state container or polling loop is added. Recomposition preserves compatible
native identities/owners and changes only final values/handlers. Equal writes and
idle frames stay quiet; layout values invalidate affected layout, colors redraw.

When an effective spread-owned property disappears, the reconciler restores its
recorded legitimate class/native default (including _init defaults), unless the
native property has independently changed since that spread was committed. Records
stay external to user Nodes. Existing border-side `auto` and minimum numeric-zero
omission rules remain authoritative. Button local `padding="auto"`, Rect white
background, ordinary script defaults and native state such as disabled/visible
restore without probe/helper Nodes. A surviving named attribute remains effective;
ordinary named-only omission semantics are not broadened. A spread-only name on an
initially unnamed Node resets to its native class label because Godot rejects
empty names after attachment; sibling-name conflicts still fail preflight.

There is no style property or framework style structure, factory, utility, token,
palette, theme Resource, cascade or inherited style. This is a general-purpose GGX
language feature. Any future framework-level style support requires a separate
owner design decision. S04 visuals and wrapping/Grid remain separately scoped.

L08 [complete Box alignment/distribution](LAYOUT_FOUNDATION.md#l08--complete-physical-axis-distribution-and-child-overrides) uses canonical physical horizontal_align/vertical_align with main space-between/around/evenly, cross stretch and eligible2D align_self. Spreads supply the same ordinary properties; no justify/align aliases or style layer. Explicit key/bind controls and native Control APIs remain unchanged.


### Grid placement metadata (L09-10)

Under an imported native Grid, child attributes `area`, `row`, `column`,
`row_span`, `column_span` are reserved Element/parent layout placement. They work
with native Control and project Gogo tags, including ordered spreads. They never
become foreign Node setters or metadata. Complete desired-tree preflight validates
tracks, template and all cells before native commit; invalid dynamic input retains
the whole mounted tree and diagnoses the authored attribute/spread key. Root helper
descriptions defer placement validation until mounted under their actual Grid.
[Exact syntax/defaults/bounds](RESPONSIVE_LAYOUT.md).

### UX01 body text and bare Boolean properties

`<Text>Hello {username}!</Text>` supplies the existing writable String `text`
property; native Button and imported EstragonButton support the same syntax.
Interpolation requires String, with explicit `str(value)` for other types.
`<HBox wrap>` supplies true only to writable native Bool metadata. Ordered
spreads retain precedence; text-body versus explicit/spread text conflicts and
invalid complete descriptions reject before commit. [Whitespace, validation and
examples](UX01.md#ggx-text-and-boolean-syntax).

### U02 inherited scrolling

`<VBox vertical_scroll>` and `<Grid vertical_scroll>` use the same writable native
Bool metadata as other attributes, with normal direct Element children.
The obsolete UX01 ScrollView public class/script and one-root rule are removed.
[Current properties and intentional source migration](SCROLLING.md).

S04 adds inherited native `corner_radius` and individual corner Length overrides,
nullable `background_texture: Texture2D`, `background_texture_mode` stretch/tile,
and bare Bool `clip_content`. Native GradientTexture2D Resources are ordinary
property values/preloads, never Element children. [Styling contract](STYLING.md#s04--opt-in-native-surfaces)
defines local border-box percentage radii, defaults, source validation and
rectangular child clipping. Normal aliases, Dictionary spreads and retained
description preflight apply without special style syntax.

## Lexical layout declarations (EL02)

`layout const <Name>...</Name>` and `layout var`, optionally module-scope `export`,
create reusable exact-case component definitions over native Grid. Matrix rows
and repeated names describe named areas, never mounted children. Ordinary GGX
uses instantiate definitions with normal instance overrides. Sequential hygienic
rebinding composes prior bases without mutating them. See [the complete grammar,
lexical/export rules, defaults and native lowering](LAYOUT_DECLARATIONS.md).

UI-03 extends the same implicit value path contract to the typed String [Input](INPUT.md): `value={self.model.text}` is two-way only for matching writable/observable String endpoints. String locals and computed values remain one-way. Bool and String do not cross-convert; source metadata, typed writers and the current mounted projection guard apply. [Binding contract](TWO_WAY_BINDINGS.md).

## Typed data and observable collections (CORE-02)

Class-level `@bindable` plain-data models support typed Dictionary hydration and generated recursive `to_data()`. Optional `ArrayCollection[Item]` fields hydrate plain Arrays, observe typed items/deep children, and expose ordered mutation/traversal. Ordinary Arrays/Dictionaries keep native in-place semantics. See [the complete typed-data contract](TYPED_DATA.md) and `examples/data`; the live #200 PR determines merge status.
