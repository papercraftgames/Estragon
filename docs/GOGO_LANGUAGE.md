# Gogo and GGX — one description composition contract

Gogo is a GDScript-like language in `.gogo`; GGX is its namespace-free syntax for describing native Godot Nodes. The bundled Godot compiler/editor emits typed, source-mapped GDScript. Normal editing and Play require only Godot and the addon.

[F04 #98](https://github.com/papercraftgames/Estragon/issues/98) cuts over all supported consumers to this contract after merged F01–F03. The live issue/PR records acceptance/review; F05-A is merged (#100); F05-B (#101) adds the bounded controlled bool binding below, with verification/review in its live issue/sole PR; F06 is merged in #105 (`55156fb`); [profiling evidence](F06_PROFILING.md). See the [cutover/removal/parity report](F04_CUTOVER.md) and [architecture](REACTIVE_COMPOSITION_ARCHITECTURE.md).

- **Every GGX expression returns an Element description**, including ordinary helpers/lambdas, conditional branches and for/map callbacks. No eager native factory mode or target-owned binding helpers remain. Use an explicit `Element` preload alias from `runtime/composition/element.gd`.
- A Node host automatically composes its zero-argument `build_view() -> Element`. Typed Gogo bindable getter reads, including reads in helpers or external models, register dynamic dependencies. Their native signals queue only interested functions. One external parent-first manager reconciles retained native Nodes; no per-frame render, hooks or manual refresh.
- Tags resolve constructible native Node types, registered script classes, normal explicit preload aliases, or unique eligible project Gogo source names (see E07 below). Use canonical EstragonRect/Text/Button/HBox/VBox or explicit aliases. `Button` is Godot's Button. Resources/models are values, not native hierarchy children.
- Attributes use native property/signal metadata. Strings use quoted literals, typed expressions use braces. Events use named handlers/Callables; inline anonymous GGX event declarations reject. Unknown/duplicate/read-only/reserved props, invalid native types or required constructors fail with authored diagnostics and actual-path semantic validation before Play. Native Godot imperative constructors/scene operations remain valid outside declarative output.
- Child expressions accept Element/null/nested Arrays, flatten left to right, and preserve authored positional slots and null holes. For/map use native GDScript syntax. Optional sibling-scoped `key` accepts int or nonempty String and never becomes a native property/metadata. Duplicate keys and bad dynamic entries preflight before commit. See [F02](F02_CONDITIONALS.md), [F03](F03_LISTS.md).
- `@bindable var count: int = 0` generates ordinary typed native getters/setters and per-property change signals in Gogo only. Code-only non-Node models remain valid. See [bindable semantics](BINDABLE_PROPERTIES.md). Raw Array/Dictionary mutations do not inherently notify; reference reassignment does. External native fields require a real signal adapter for automatic observation.
- Helpers are repeatable description computations. Effects belong in events/lifecycle methods. Nullable model expressions use native conditionals/fallbacks. Old Node-returning `build_view` GGX rejects; description values passed to native Node APIs reject through typed semantic validation. There is no compatibility wrapper or second renderer.
- Managed output is transient `owner=null`. Native scene ownership persists authored hosts/foreign objects; the view reconstructs once on mount/reload. Commit retains compatible IDs, native state/animation and unchanged desired props/handlers. Existing composed layout and transform authority remain; #88 is separate.

F05-A class-wide `@bindable` (#90) is a standalone preamble marker before `extends`/`class_name`, expanding eligible owned typed instance fields through the existing property lowering. Native exports are retained; inherited/untyped/inferred/static/local/inner fields stay ordinary. Typed custom/deferred accessors reject; explicit class+property coverage is idempotent. See [exact eligibility/grammar](BINDABLE_PROPERTIES.md#class-wide-annotation-f05-a) and live issue/sole PR for verification/review. F05-B supports `bind:value={self.model.enabled}` for typed Gogo bool bindables and native controlled inputs; see [exact grammar/timing/ownership](TWO_WAY_BINDINGS.md). Broader input types, observable in-place collections, serialization remain future scoped work; bounded F06 profiling/optimizations are merged. No `.gd` custom annotations or `.bgd`, mandatory Repeater or immutable data tree.

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

Explicit preload aliases choose their declared resource and are never rewritten or redirected. Duplicate filenames, local declarations, and different native/global symbols with the same unqualified name are ambiguity errors at the tag; there is no nearest-directory or first-match rule. A global `class_name` and project name pointing to the same generated Script are one identity. Missing global-script cache entries cannot reserve names or supply stale executables. Native class constants such as `const NativeGroup = Node2D` provide an explicit native spelling when a project filename collides. `Button` continues to mean the native Godot class; a colliding project source requires disambiguation, not remapping.

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
