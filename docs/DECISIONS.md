# Architecture decisions and open questions

This file is a lightweight decision log. Decisions marked **provisional** are not settled by the code scaffold.

## ADR-0001 — Own the UI stack

**2026-11-02 supersession note:** The self-rendering mandate and prohibition on per-component Nodes are superseded by ADR-0015. The paragraph below records the original decision.

**Status: accepted. 2026-10-25.**

Estragon is **not** a declarative generator for Godot `Control` nodes. Estragon manages its own components, layout, styling, input handling, observable state and graphics rendering. Godot provides hosting, platform/window/input facilities and graphics APIs. A small host node is acceptable. Per-component node adapters, if they are ever introduced, must be **optional**.

## ADR-0002 — Naming

**Status: accepted. 2026-10-25.**

Estragon names the framework. Gogo names the language and its compiler; markup files end in `.gogo`. Inspiration comes from Adobe Flex's MXML and bindability, but the actual markup is a new language, not MXML compatibility mode.

## ADR-0003 — Graphics API and backends

**2026-11-02 supersession note:** The requirement to choose a framework-wide competing renderer is superseded by ADR-0015. RenderingServer implementation and historical research remain factual.

**Status: provisional. 2026-10-25.**

The initial proof uses `RenderingServer` canvas primitives to render pixels without `Control` nodes. This is not a selection of the final engine backend. Investigate `RenderingDevice`, custom shaders, batching and native/GDExtension implementation when we have representative UI workloads. Keep IR, component tree, layout and binding independent of the graphics interface.

## ADR-0004 — Bindable syntax strategy (historical proposal)

**Status: superseded by ADR-0013 on 2026-10-29.** Original R01 research premise retained below as history.

The desired experience is `@Bindable` in ordinary user-authored `.gd`, transformed into typed getters/setters and notifications. **Stock GDScript does not accept arbitrary addon-defined annotations**, and a simple `EditorPlugin` cannot register them. Explore real pre-parse source transformation/editor integration before considering a separate source extension (`.bgd`) or engine/parser modification. None of these mechanisms is confirmed; do not silently replace the requested `.gd` experience with `.bgd`.

**R01 evidence, 2026-10-29:** [Feasibility report](BINDABLE_FEASIBILITY.md) records native runtime, loader/cache/remap/import/language and real ScriptEditor experiments. Fixed generated setters work, but native authored-buffer validation rejects `@Bindable`. **The owner subsequently chose Gogo-only lowercase `@bindable` in ADR-0013; the old `.gd` requirement is no longer an open blocker.**

## ADR-0005 — Edit the original Gogo source

**Status: provisional. 2026-10-25.**

Favor Godot's editable text-file workflow plus editor plugin first; do not convert Gogo source to a `.tscn` tree. Later, add semantic editing, build integration and a preview backed by the actual Estragon renderer.

## ADR-0006 — Project license

**Status: accepted. 2026-10-25.**

Estragon is distributed under the [MIT License](../LICENSE).

## ADR-0007 — Gogo generates GDScript with TSX-like authoring

**2026-11-02 supersession note:** ADR-0015 broadens component expressions to general-purpose Node composition named GGX; native generation and namespace-free authoring remain accepted.

**Status: accepted direction. 2026-10-26.**

Gogo (`.gogo`) should support **XML-like component expressions directly mixed with GDScript**, borrowing TSX's compositional authoring model and Flex 4's runtime/component principles. Component tags are **unprefixed** (`<VBox>`, `<Button>`); mandatory XML namespace prefixes and `xmlns` declarations are rejected as the product direction. The transpiler generates valid GDScript for typed Estragon components, automatic event/signal wiring, and later bindings. The first prototype's JSON output and namespaced XML are **temporary scaffolding**, not the final language contract.

The *experience* is accepted; precise grammar, imports, binding semantics, parser architecture, editor integration and GDScript class organization remain implementation decisions. ADR-0013 settles the annotation spelling and authored `.gogo` boundary. See [design direction](DESIGN_DIRECTION.md).


## ADR-0008 — Framework-owned automatic component lifecycle

**2026-11-02 supersession note:** ADR-0015 supersedes the target RefCounted surface/dispose ownership model and no-Node rule. This remains the current runtime lifecycle contract until reviewed migration; native Node lifetime/persistence must be proved separately.

**Status: accepted user requirement, 2026-10-26; T03 implementation reviewed in its PR.**

Application developers must not call `dispose()` during normal Estragon usage.
A surface owns its root and renderer; unmounting/replacing a root or leaving the
scene tree automatically cleans components, subscriptions and rendering resources.
Container removal/replacement likewise unmounts and cleans; direct adoption into
a new parent transfers ownership without disposal. Live surface roots cannot
have another owner. Internal cleanup remains idempotent and terminal.

This explicitly supersedes T02's manual-dispose/remove-to-detach convention.
The user requested this correction for T03; it is not a compiler or binding change.
Keep root/child transfer checks separate from cleanup so moving a subtree does
not destroy it. Deterministic cleanup executes in live owners, not RefCounted
final-deletion callbacks (calling instance cleanup there failed in Godot 4.7).
Raw unmounted values remain reference-counted data; normal application UI is
mounted in a surface. No Node or graphics resource per component is introduced.

T03 uses deliberately narrow fixed/auto/fill sizing and stack gaps, documented
in ARCHITECTURE. These are the first tested rules, not automatic Flex/CSS semantics;
broader sizing/alignment remains an open future design.

## ADR-0009 — Minimal GDScript-first hybrid composition

**2026-11-02 supersession note:** ADR-0015 replaces the target Estragon-only factory/child and surface-mount assumptions. The implemented T05 semantics below remain compatibility evidence.

**Status: T05 implementation contract, reviewed with its implementation PR.**

T05 composes lexically retained GDScript with parsed component expressions and
balanced braced GDScript property/child expressions. No XML document wrapper,
script block or mandatory code-behind is introduced. T04 standalone markup
continues unchanged. The full future language is not fixed by this initial slice.

Lower markup AST nodes to typed static factories within the authored module.
Arguments are evaluated once in authored scope/source traversal order before
construction; nested native conditionals remain lazy. This preserves local/member
references without rewriting variable names or depending on Callable Variant
return inference. Helper names avoid module identifiers and indentation follows
authored GDScript. Application surfaces mount explicitly with set_root; existing
automatic lifecycle remains intact. No reactive expression reevaluation is implied.

Godot supplies GDScript syntax/type authority; the TypeScript frontend supplies
markup/type compatibility, expression boundaries and range maps. Dynamic types
and runtime constraints are not falsely advertised as statically proven.
Range-map sidecars and mapped Godot checks provide traceability without claiming
editor/debugger integration. Named inner-class markup, collection expansion,
bindings, widget/signal features and full semantic analysis remain outside T05.

## ADR-0010 — Minimal generated Button signal connections

**2026-11-02 supersession note:** ADR-0015 broadens target signal sources and requires named handlers/Callable references rather than inline anonymous GGX handler declarations. The implemented T07 callback/lifecycle contract below is preserved pending migration.

**Status: T07 implementation contract, reviewed with its implementation PR.**

Gogo resolves Text/Button to the existing independent runtime classes. In hybrid
modules only, `Button pressed={expression}` accepts a native GDScript Callable.
Ordered typed signal/property attributes retain construction-time evaluation
order. A typed Callable factory argument preserves authored scope; ordinary
synchronous signal connection code is generated exactly once per new component.
No string-handler dispatch, runtime markup interpretation or new event framework
is introduced. Godot owns GDScript syntax/types; generated validity/arity guards
require zero remaining arguments (including optional parameters in metadata).
Bound argument types and arbitrary closure effects remain native runtime concerns.

T06's automatic teardown disconnects outgoing connections. T07 also disconnects
incoming direct method connections on terminal components so live sources cannot
invoke retained disposed targets. Transfers preserve connections/identity. Counter
uses explicit root rebuilding with framework-owned cleanup; reactive bindings and
editor integration remain T09/T08. See GOGO_LANGUAGE for supported props, callback
limits, mapped diagnostics and the runnable no-handwritten-connection example.

## ADR-0011 — Native editor authoring and synchronous compile-before-Play

**Status: T08 foundation; its external compiler contract below is superseded by N03/ADR-0012. TextFile/highlighter contracts remain implemented.**

Use Godot 4.7's native TextFile/ScriptEditor and registered EditorSyntaxHighlighter
with `gogo` extension association. Pinned engine source and isolated real-editor
tests demonstrate automatic selection for new tabs; no replacement IDE or source
importer is needed. **E01 correction:** registration alone misses existing tabs,
and native cached Plain Text state can override extension selection on restore.
An event-driven deferred association pass repairs open/restored `.gogo` tabs;
non-Gogo highlighters and preferences are preserved. The resource-path adapter's
version-sensitive native-list fallback and test coverage are documented in EDITOR.
Disable detaches active Gogo highlighters and owned hooks; re-enable repairs tabs.

The project declares strict source roots in gogo.config.json. Output is adjacent
`generated/<name>.gd` plus hybrid maps, preserving existing scenes and UID files.
Exclude tests/dependencies/legacy explicitly; never rewrite authored Gogo. Reuse
the existing TypeScript pipeline, compiling every source before writing outputs.
Unchanged files are not rewritten. No automatic source deletion migration occurs.

Saved-resource/filesystem notifications coalesce a build. Both native Play modes
share EditorPlugin._build; save buffers and synchronously gate execution on the
bounded direct Bun subprocess and native Godot script validation. No shell is
used; configure an absolute Bun executable when GUI PATH discovery is insufficient.
Any frontend/process/semantic error aborts Play and appears with authored source
locations. Successful output paths update the resource filesystem; fresh game
processes execute current code. Running games are not hot-reloaded.

This intentionally accepts a brief editor pause for the boolean build gate.
Incremental/background compilation, completion/navigation, debugger integration
and live preview remain future work. Tests use a copied self-contained editor
with isolated project/settings, never the user's persistent editor configuration.
See EDITOR/TESTING for setup, API evidence, guarantees and manual procedures.

## ADR-0012 — Gogo compilation must run natively inside Godot

**2026-11-02 supersession note:** ADR-0015 supersedes only the prohibition on per-component Godot Nodes and the independent-runtime target. Bundled native compilation, parser separation, source maps and fail-closed validation remain mandatory.

**Status: accepted owner decision, 2026-10-28; N01–N03 native compiler/editor implemented.**

**Decision:** Users installing and working with Estragon in Godot require **only Godot and the addon**. The Gogo compiler must be bundled and authored in **GDScript**, supporting native lexical/semantic markup processing, GDScript generation, source maps and editor build/Play diagnostics **without Bun/Node/TypeScript installed, configured or spawned**. No new external compiler process, runtime markup/JSON interpreter, engine fork, GDExtension binary or per-component Godot Node/Control is an acceptable substitute without another explicit decision.

**Why:** T04–T07 prove Gogo with a Bun/TypeScript compiler. T08 PR #29 proves the Godot editor can automatically build on save and before F5/F6 through a bounded Bun subprocess; the user personally verified a font-size Gogo edit and Play on 2026-10-28. They explicitly reject Bun as a required developer tool. Therefore **T08/ADR-0011's Bun subprocess and executable configuration are transitional**, not the chosen final architecture.

**Execution:** N01 native GDScript lexer/parser/typed frontend → N02 native emitter/maps, T04–T07 parity and interactive Counter → N03 no-Bun native editor cutover with real F5/F6 failure/recovery tests in a fresh Godot-only project. These tasks move **ahead of T09/T10**. Preserve existing working T08 behavior until N03 passes; do not silently fall back to Bun once cut over. TypeScript/Bun may remain **optional developer/CI reference tests**, never user-facing editor dependencies.

**N01/N02 implementation:** The addon now includes a scene-independent native lexer, hybrid parser, typed built-in validation and source-located diagnostics. Godot-only tests consume checked reference transcripts with Bun unavailable. N02 adds deterministic native GDScript emission, version-1 range maps and explicit native semantic validation. Godot-only Counter/fixture tests prove input, evaluation and lifecycle parity with external tools unavailable. Validation uses a scoped Logger/reload window and Resource.set_path_cache() with the actual output path (including class_name identity), never taking over cached application scripts; Godot reports lines rather than exact columns. N03 directly integrates the compiler/validator into the editor, with no Bun fallback or executable setting. See GOGO_LANGUAGE for API and parity boundaries.

**N03 editor contract:** All compiler modules are tool-callable. Explicit configured roots remain authoritative; absent config scans project sources with addon/dependency/generated/hidden/test exclusions, enabling a setup-free fresh addon. Stage all changed code/maps with rename backups; reject/restore on failure before authorizing Play. Order validation/state-preserving reloads from lexer-proven static resource paths, decoded with native Godot string semantics; refresh dependencies before dependents and roll cached code back on failure; filesystem updates alone do not guarantee fresh GDScript bytecode. Preserve no-op bytes/UIDs and native TextFile highlighting/save behavior. Fresh isolated editor/game tests run with an empty executable PATH, no repository toolchain or generated fixtures, and cover both Play modes, failures/repairs, input/layout, cached identity and restart. Physical keyboard/window-manager checks remain distinct from automated run-command evidence.

**Cost/constraints:** Temporary compiler duplication is acceptable to establish semantic parity. Keep codegen independent of EditorInterface, renderer and application scene tree. Preserve accepted Gogo syntax, deterministic output, authored source maps, event/callback semantics, lifecycle and fail-closed builds. GDScript type semantics remain Godot's responsibility. This does not solve arbitrary `@Bindable` annotations in ordinary authored `.gd`; R01/T09 remain separate.

## ADR-0013 — Lowercase `@bindable` belongs to Gogo; observable models, collections and layout

**2026-11-02 supersession note:** ADR-0015 supersedes the no-Node/shared RefCounted Box target and adapts geometry/lifecycle/repeaters to retained native Nodes and a composed layout core. Lowercase Gogo-only @bindable, non-Node models and observable collections remain accepted.

**Status: accepted owner decision, 2026-10-29. Implementation remains planned. Supersedes ADR-0004's authoring-boundary requirement.**

**Source/annotation:** The one official syntax is **`@bindable` (lowercase) in authored `.gogo` only**. Gogo is the developer-facing language, including code-only typed model modules; the bundled native Gogo compiler transforms declarations into ordinary valid GDScript properties, typed accessors and observable change notifications. No custom annotation is registered in native authored `.gd`; no `.bgd`, engine fork or external compiler is required. The [R01 findings](BINDABLE_FEASIBILITY.md) remain research evidence rather than an implementation or a block on this decision.

**Behavior:** Plain assignments (e.g. `count += 1`) to bindable Gogo properties notify dependent bindings without hand-written setters, manual signals or full root reconstruction. Dependency-aware subscriptions update affected typed component props, including text/paint and **layout geometry** when such props are implemented. Explicitly specify `x`/`y` semantics relative to layout-managed parent coordinates; current components do not expose them. Coalesce invalidation, avoid per-frame polling, detach observers on unmount/transfer according to framework lifecycle and preserve identity where possible.

**Data:** Support non-Node bindable Gogo objects/models and an **ArrayCollection-inspired observable collection**. Model property updates, collection reference changes, structural add/remove/replace/move/reset and bindable item-property updates are distinct events. Repeated/list components must eventually react with stable identity and keyed reconciliation. A raw `Array.append()` is not assumed to emit change events solely because its variable is bindable.

**Shared layout hierarchy:** The current implemented chain is `EstragonDisplayObject → EstragonContainer → EstragonStack → EstragonHBox/EstragonVBox`. Owner target is `EstragonDisplayObject → EstragonContainer → EstragonBox → EstragonHBox/EstragonVBox`: centralize shared box sizing/orientation/gap behavior and preserve existing Stack consumers through a tested migration. Do not create a Godot `Control`/`Node` tree.

**Delivery:** Fix automatic Gogo highlighting separately in [E01 #37](https://github.com/resistdesign/Estragon/issues/37). Stage T09 across reviewable property/model, component/layout, collection/repeater, and two-way/cycle-hardening slices. The [T09 live issue #5](https://github.com/resistdesign/Estragon/issues/5) and [REACTIVITY_PLAN](REACTIVITY_PLAN.md) contain the detailed contracts. Do not claim these features implemented or merge automatically.

## ADR-0014 — Support Godot 4.0 and all subsequent 4.x versions

**Status: accepted owner requirement, 2026-10-29. Implementation/verification in progress; 4.0 compatibility is NOT yet established.**

**Decision:** Estragon's distributed GDScript addon, Gogo compiler, native editor integration, emitted code, independent component runtime, layout/rendering and examples must support **Godot 4.0+**, including each later minor release in Godot 4.x. The minimum must not silently rise to the 4.7 version used for current tests. Bun/Node remain optional contributor tools, never a user-side build dependency.

**Current gap:** The published Godot 4.0 `ScriptEditor` API omits `save_all_scripts()` and `get_unsaved_files()` called by N03's F5/F6 build gate; the Godot 4.0 `Resource` API omits `set_path_cache()` used in native Gogo semantic validation. E01 #40 repairs 4.7 restored/highlighting tabs using a bound undocumented `_get_edited_resource()` plus ScriptEditor ItemList path/metadata; this is not evidence of older-version support. The repository's `project.godot` currently carries a `4.7` feature marker. These examples establish the need for a broader audit, not an exhaustive defect list.

**Requirements (2026-10-29 historical verification scope; superseded on 2026-11-02 by the two-version testing amendment below):** Prefer stable public Godot 4.0 APIs; if an internal workaround is unavoidable, version/capability-gate its narrow adapter and test representative supported engines with real editors, without manipulating user preferences or discarding unsaved source. Preserve fail-closed compile-before-Play, source maps, native semantic validation, correct script/class identity, generated GDScript syntax, runtime layout/input/paint, and all E01 new/open/restored Gogo highlighting. Test real 4.0–4.7 engines and maintain a repeatable matrix, including source/scene versioning and plugin load/import evidence. Do not mislabel 4.7 CI green as 4.0+ certification.

**Delivery:** Full cross-cutting compatibility gate [C01 issue #41](https://github.com/resistdesign/Estragon/issues/41). Highlighter E01 PR #40 must receive a specific 4.0+ compatibility review; the Godot-only T09 `@bindable` plan in ADR-0013 remains accepted but implementation must target the 4.0 baseline. No automatic merge, unsupported capability promises or unapproved minimum-version increases.

## Compatibility engineering amendment — progressive enhancement (2026-10-30)

**Accepted owner refinement:** [C01-C #46](https://github.com/resistdesign/Estragon/issues/46#issuecomment-6534935109).
Godot 4.0+ remains mandatory. Implement a compatibility bridge when supported
older APIs provide a clean, safe solution with reasonable ongoing maintenance.
Do not manufacture brittle introspection or elaborate infrastructure solely to
reproduce newer optional diagnostics. Where bridging is disproportionate,
preserve valid behavior, retain all available safeguards, and let incompatible
operations use the older engine's normal error path. Newer engines may provide
earlier or richer diagnostics. Record and test this difference explicitly.

For C01-C, opaque lambda arity cannot be recovered through public 4.0 reflection.
The owner approves skipping only proactive arity checks on 4.0–4.2; invalid and
disposed callbacks, connection errors and automatic cleanup remain guarded.
4.3+ retains early required/optional-argument rejection. Older engines permit
optional-argument invocation and report required-argument errors at invocation.
This does not waive editor freshness, fail-closed Play or other required semantic
behavior, and does not approve unit-helper, Box or reactive implementation.

## Numeric compatibility amendment — native parsing semantics (2026-10-31)

**Accepted owner decision, C01-D #47:** Keep native Godot numeric parsing
semantics. Fix avoidable precision loss, document and test inherent limitations,
and do not implement a full custom decimal parser. Compiler-owned quoted numeric
literals may be normalized into equivalent decimal spellings before conversion;
authored GDScript is copied unchanged. Preserve the native typed value through
emission without an additional lossy formatting round trip. Independent IEEE
oracles remain visible for measured parser discrepancies; native preservation
must not be mislabeled as universally correctly-rounded conversion.
See [C01_D_NUMBERS.md](C01_D_NUMBERS.md). This does not raise the minimum engine,
introduce a runtime numeric adapter, or authorize C01-E/reactive/unit-helper work.

## Unresolved, intentionally not invented

- **Visual implementation:** per-component native drawing/presentation choices and platform proof under ADR-0015; no mandatory competing renderer.
- **Bindable semantics and staged integration:** implement approved Gogo-only `@bindable` in code-only models and UI classes, generated setters/notifications, nested dependencies, observable collections, reactive geometry and lifecycle. See ADR-0013 and [REACTIVITY_PLAN](REACTIVITY_PLAN.md).
- **Gogo language:** TSX-like GDScript/markup grammar, component import/resolution, typed expression/event/binding semantics and optional markup-only shorthand.
- **Node integration:** coordinate boundaries, native adapter authority/measurement, transform feedback and PackedScene ownership under ADR-0015.
- **Layout/style semantics:** borrow selected Flex ideas, establish a new model, or align with modern UI layouts.
- **Text and accessibility:** text shaper/platform integration, IME, screen readers and testable semantics.
- **Editor architecture:** ScriptEditor plugin vs standalone Gogo authoring surface vs language server.
- **Mixed-authoring implementation:** reliable source mapping, parsing GDScript expressions alongside markup, and optional code-behind.

When any of these is decided, record the rationale and tradeoffs here before implementation.

## Semantic compatibility amendment — preflight versus publication (2026-10-31)

**Accepted owner decision, C01-E #48 / PR #60:** Distinguish legacy preflight
from publication. On engines lacking safe isolated script-path assignment
(verified 4.0–4.3), report isolated cached-path checks unavailable/BLOCKED and
return no candidate executable. Require actual-path native semantic validation
inside the file/cache rollback transaction before any build succeeds, including
no-op builds. Do not return a cached application Script as an isolated candidate,
take over its path, hide compile errors or accept stale dependencies/bytecode.
Preserve identity, live state, failure rollback and recovery. 4.4+ retains proved
isolated path validation; Logger engines retain richer mapped diagnostics.
See [C01_E_VALIDATION.md](C01_E_VALIDATION.md) and the live issue for evidence.
This does not authorize C01-F/G startup/Play redesign or reactive/layout work.

## E01-F filtered-tab identity — accepted exception (2026-11-02)

**Status: accepted owner decision.** [Issue #44 approval](https://github.com/resistdesign/Estragon/issues/44#issuecomment-6568383818) and [reproducible nine-engine evidence](E01_F_FILTERED.md).

A never-associated `.gogo` tab hidden by a Script Editor filter may remain Plain Text while Godot exposes no trustworthy edited TextFile identity. Once **revealed and activated**, it must receive normal Gogo highlighting; already-associated filtered tabs retain their colors. Never change the user's filter or preferences, guess path identity, or inject an unstable workaround. This defers only invisible, unidentifiable highlighting. It does not waive Godot 4.0+, normal editor highlighting, native fail-closed Play, or other C01 release gates.

The hidden-tab observation remains FAIL on all nine tested official engines, not PASS; the owner-approved release-scope exception must be recorded separately from test outcomes. C01-H #51 may proceed once the focused evidence/decision PR merges. Reconsider with a new scoped issue if a stable native path API or a concrete interaction bug emerges.

## Godot test matrix cost control — owner decision (2026-11-02)

**Status: accepted.** Mandatory testing is capped at **two distinct engines across both local/Codex work and CI**: official **Godot 4.0.4**, the oldest supported patch, and the existing pinned **Godot 4.7.0** baseline. Do not execute routine nine-engine/all-minor sweeps, including 4.7.2, to support development, PRs, release gates, or evidence collection. No optional third engine is authorized. The owner may explicitly authorize replacing a version for an identified bug, but it still counts against the two-version maximum.

**Reason:** all-minor matrices wasted AI usage, agent time, CPU, CI minutes and review effort without proportionate benefit. Prefer small targeted local checks during implementation and a single relevant two-version review/acceptance pass rather than repeated exhaustive runs. CI must contain only 4.0.4 (macOS) and 4.7.0 (Linux), with duplicate push+PR triggers and superseded runs canceled.

**Scope of proof:** Godot **4.0+ remains the product target** under ADR-0014; this is a **testing-budget change**, not an increase in the supported minimum or a declaration that each untested 4.x minor passed. Historical nine-version results, SHA/provenance, and FAIL/BLOCKED/UNTESTED outcomes remain intact as archive, never relabeled or used to force a rerun. New reports/snapshots accept one or two engines. This decision supersedes the 2026-10-29 requirement to retest every minor in each C01 slice or release check. See `AGENTS.md` and `docs/TESTING.md` for the standing operative policy.

## Native framework and TypeScript-only tooling — owner reaffirmation (2026-11-02)

**Status: accepted and mandatory.** Estragon's product language/framework is
**native Godot/GDScript and Gogo**. Every contributor-side script, test
orchestrator, compatibility runner, evidence validator, report generator, and CI
helper must be **TypeScript**. Python has **no place anywhere in the repository's
source, tests, build scripts, or workflows**, including embedded snippets in YAML.

This is a standing architectural boundary, not a task-specific preference.
Previous C01 test automation violated it. PR #64 replaces the operating
collectors and validators with TypeScript, retains native GDScript fixture
tests and archived factual evidence, removes all Python files, and updates CI.
Do not reintroduce Python as a shortcut for temporary research, compatibility,
or test fixes. For ongoing enforcement see `AGENTS.md` and issue #41.

## ADR-0015 — GGX Node-native composition and layout-first Estragon

**Status: accepted owner direction, 2026-11-02; NOT implemented.** Source: [architecture issue #68](https://github.com/resistdesign/Estragon/issues/68). Formalization: [ADR-0015-A #69](https://github.com/resistdesign/Estragon/issues/69). This documentation decision changes the target; it neither retroactively changes implementation nor certifies compatibility/release readiness.

**Implementation note:** [B1 #71](https://github.com/resistdesign/Estragon/issues/71) adds only a separately selected [bounded native composition proof](NODE_COMPOSITION_PROOF.md). [B2 #73](https://github.com/resistdesign/Estragon/issues/73) adds a separate [composed spatial entry/row-layout proof](NODE_LAYOUT_PROOF.md), using proposed bounded coordinates/authority recorded in its task. [B3 #75](https://github.com/resistdesign/Estragon/issues/75) adds the separately bounded [native adapter/metadata proof](NODE_ADAPTER_PROOF.md) for review. The full architecture remains unimplemented; current default compiler/runtime and release evidence remain distinct.

### Responsibilities and language

Estragon supplies a Flex-inspired 2D UI suite replacing Godot Control UI for its intended uses, extending layout-first measurement, sizing, positioning, reactive changes and composition to 3D. Godot retains its SceneTree, lifetime, transforms, physics, rendering and platform/window events. Visual components use actual Godot drawing/presentation; Estragon need not own all graphics or implement a competing renderer.

Gogo is the GDScript-like language in authored `.gogo`. **GGX** names its embedded XML-like general-purpose Node composition syntax, in the role of JSX/TSX. Keep namespace-free interleaving, deterministic typed GDScript generation, source maps and bundled Godot-only fail-closed compilation. No virtual DOM or React render loop is implied.

### One creation/child contract and native signals

GGX hierarchy elements must be Godot **Node or subclasses**, including ordinary native/custom Nodes and Estragon Nodes. The sole child-attachment API is inherited **Node.add_child(Node)**. No JSX/GGX pragmas, configurable or type-specific child-adder protocols. Non-Node resources/Objects (meshes, materials, shapes, models) may be property/expression values; they are not tree children.

Typed native properties, Gogo bindings and native signals apply beyond Estragon. **Any referenced Godot Object with a signal may be a signal source**, even though only Nodes may be hierarchy elements. Handler attributes refer to named handlers/Callable values; do not introduce inline anonymous function declarations in GGX handler attributes. Ordinary functions may contain GGX; function-valued children are not required.

Node.add_child returns void, unlike today's EstragonContainer Error contract. Native Node parentage, reparenting/freeing, signal cleanup and PackedScene `owner` persistence must be designed and tested deliberately. A superclass rename cannot provide this migration.

### Visual inheritance, layout and boundaries

2D visual Estragon components inherit appropriate **Node2D** types; 3D layout participants inherit **Node3D**. Share the mathematical layout model/algorithms **via composition**; a plain Node base inserted above both spatial branches is not the intended visual hierarchy. Explicit 2D/3D entry points have working names **Estragon2D/Estragon3D**; exact class names remain TBD.

An ordinary Godot Node is allowed anywhere in GGX and retains native behavior, but is not automatically an Estragon layout participant. Re-enter layout beneath it using another explicit entry point. Do not tunnel layout through arbitrary Nodes. 2D/3D spatial chains differ and plain Nodes can interrupt transforms; coordinate conversions, boundaries and any 2D overlay in a 3D scene require an explicit supported approach.

Retain actual Node identity and subscriptions. Measure → arrange operates on affected participants without rebuilding/reconciling the full tree. 2D supports Flex-like rows/columns, sizes, alignment, gap/padding and responsive layout; 3D extends measurement/arrangement to width/height/depth and native spatial transforms. A possible volumetric RowBox/ColBox fills two axes and layers along the third. The overall model is accepted; **axes, wrap order, spacing, units, constraints and overflow need a focused specification**. Existing 2D pixel decisions stand; pixels are not assumed to be 3D world units.

### Native adapters and event-driven updates

Working **Native2D/Native3D** adapters expose explicit bounds/position and optionally measure/observe native children while preserving their native renderer/behavior. Generic Node/Node3D has no universal size; use an appropriate bounds provider, geometry/rect, mesh AABB or authored size. Specify native-controlled versus layout-controlled geometry. Signals, applicable notifications, bindings or explicit invalidation can request remeasurement when desired. Animated geometry may use fixed/deferred snapshots or opt-in observation, never compulsory per-frame polling.

Cache measurements, invalidate affected branches and batch/coalesce updates. Guard Estragon-authored transform/bounds writes against observer feedback loops. Events include bindable/collection changes, native signals, tree/child changes, explicit adapter invalidation and viewport size changes. Treat relevant Window DPI/scaling changes separately; do not assume they always resize the viewport. Theme changes flow through observable/bound theme data. Collections/repeaters update retained keyed Nodes incrementally and need no function-valued GGX children.

### Supersessions, preservation and delivery

This ADR explicitly supersedes the conflicting future requirements of **ADR-0001** (all rendering/no Nodes), **ADR-0003** (mandatory independent renderer direction), **ADR-0008** (RefCounted surface lifecycle as the future model), **ADR-0012** (per-component Node prohibition), and **ADR-0013** (RefCounted Box hierarchy/no Nodes). It also broadens **ADR-0007/-0009** Estragon-only construction/child assumptions and **ADR-0010** target signal/handler scope. Original text and historical tests remain below their supersession notes as evidence of what was decided/implemented then. Compiler separation does not prohibit generated code constructing Nodes; it prohibits compiler dependence on a live SceneTree.

Preserve ADR-0013's **exact lowercase Gogo-only @bindable**, code-only non-Node models, observable collection/item events and scoped dependency tracking. Preserve native-only product compilation, Godot 4.0+ target, live test cap **4.0.4 + pinned 4.7.0**, TypeScript/Yarn-only future contributor tooling, no Python, no physical-key gate, one PR at a time, durable handoffs and owner-controlled merges. Existing Bun scripts remain unchanged historical contributor tooling in this docs-only task; their conversion needs separate scope.

Today RefCounted components/private child lists/RenderingServer surface and the native compiler/editor remain implemented. No Node-native GGX, 3D layout, adapters or reactivity is claimed. All existing examples/evidence and actual FAIL/BLOCKED/UNTESTED results remain. **Strict release remains BLOCKED**; development CI success is not publishing authorization.

First formalize and plan (#69), then prove minimal native composition, shared 2D/3D layout and adapters in small serial PRs before broader runtime/compiler migration. [NODE_MIGRATION_PLAN](NODE_MIGRATION_PLAN.md) defines prerequisites, acceptance and unresolved decisions; C01, #65, L01 and T09 are not silently completed or waived.
