# Architecture: Node-native composition and layout-first components

**Accepted target: ADR-0015; not implemented.** [Owner #68](https://github.com/resistdesign/Estragon/issues/68), [formalization #69](https://github.com/resistdesign/Estragon/issues/69), [staged proof/migration](NODE_MIGRATION_PLAN.md). Target requirements below supersede conflicting independent-tree/no-Node/render-everything direction; existing runtime contracts remain in force until reviewed migration.

## Target responsibilities and boundaries

Gogo is the GDScript-like language; GGX is its embedded XML-like general-purpose Node composition syntax. GGX constructs Node-derived hierarchy elements using only inherited **Node.add_child(Node)** (void), with native typed properties and named-handler/Callable signal connections. No pragmas or configurable/type-specific child adders. Resources/models/other Objects may be values, never hierarchy children. Any referenced Object with a signal may supply it; signals are not restricted to Estragon Nodes. No inline anonymous function declarations in target GGX event attributes; ordinary functions may contain GGX. Function-valued children are not required.

Estragon provides Flex-inspired 2D UI replacing Control UI for its intended uses, and analogous 3D layout. Godot provides SceneTree lifetime, transforms, native rendering, physics and platform/window events. Ordinary Nodes, including native UI Nodes, are valid GGX elements; they do not thereby become Estragon layout participants or define Estragon's UI semantics.

2D visual participants derive from Node2D; 3D participants derive from Node3D. Both compose one mathematical measure/arrange core. No shared plain Node visual base is imposed. Explicit entries (working Estragon2D/Estragon3D names) establish layout roots. An ordinary Node boundary stops automatic layout; nest an explicit entry to re-enter. Specify native spatial chains and conversion boundaries, including any future 2D overlay in 3D, rather than assuming transforms propagate across arbitrary Node types.

Working Native2D/Native3D adapters expose explicit bounds/position with optional suitable measurement/observation. Native children retain rendering/behavior. Generic Node/Node3D has no universal size; choose authored bounds, rect/geometry or mesh AABB providers deliberately. Specify native versus layout authority, cache bounds, coalesce affected-branch invalidation and suppress feedback from Estragon's own writes. Animation may use fixed/deferred snapshots or opt-in observation; no compulsory per-frame polling.

Retain actual Node identities and subscriptions through event-driven measure → arrange. Inputs include state/collection/native signals, child changes, explicit invalidation and viewport resize. Treat relevant Window DPI/scaling separately; theme changes use observable/bound data. No virtual DOM, full-tree rebuild or global poll. 2D pixel units stand; 3D width/height/depth units, axis/wrap/layer order, constraints and overflow require focused specification. Parentage, PackedScene owner persistence, reparent/free and native signal cleanup are distinct proof obligations.

## Current implementation and preserved contracts

Today EstragonDisplayObject extends RefCounted; EstragonContainer owns a private child list and returns Error from add_child; EstragonSurface is a Node with one RenderingServer canvas item. Existing generated code targets those APIs. A separate [B1 compiler proof](NODE_COMPOSITION_PROOF.md) now exercises bounded native Node composition/signals/persistence. A separate [B2 proof](NODE_LAYOUT_PROOF.md) adds explicit Node2D/Node3D entries sharing one composed X-row measure/arrange core. A separate [B3 proof](NODE_ADAPTER_PROOF.md) adds bounded native geometry/mesh adapters for review. [C1 runtime](NODE_RUNTIME.md) now adds explicit entry/component/native adapter APIs alongside legacy, reusing the shared math/native bridges with proof compatibility paths. [C2](NODE_GGX.md) integrates native GGX with normal compiler/editor builds and preserved legacy paths; widget parity, retirement and reactivity remain planned; bounded foundation defaults are not a universal layout policy. Do not mechanically rename superclasses or reinterpret old ownership tests as Node-lifetime proof.

The compiler/editor sections and T02–T08 runtime descriptions below document current implementation and historical development, not future no-Node constraints. Existing examples and measured evidence remain valid for their stated scope. C01 release certification stays **BLOCKED**; merged development infrastructure is not authorization to publish.

## Compatibility principle: pragmatic progressive enhancement

Preserve functionality across Godot 4.0 and later supported engines; enhance
validation, diagnostics and performance when newer APIs permit. Bridge missing
capabilities with simple, reliable public APIs when maintainable. Prefer
capability detection where available; isolate any necessary version gate.
Avoid brittle reflection, elaborate adapters and extensive backports merely to
recreate optional diagnostics. When no practical equivalent exists, omit only
the optional enhancement and allow normal engine compile/runtime errors to
report incompatible operations. Never hide errors or reject otherwise valid
inputs because optional introspection is absent. Keep other semantic, ownership
and lifecycle guarantees intact; test both paths and document their difference.
See the [accepted owner refinement](DECISIONS.md#compatibility-engineering-amendment--progressive-enhancement-2026-10-30).

C01-C uses a small 4.3+ version gate because Callable is a value type without
Object.has_method-style capability detection. Only the proactive arity query is
gated; typed inputs, validity/disposal/connection checks and cleanup are shared.
The compiler remains independent of rendering and editor APIs.

## Godot-native compiler migration (ADR-0012; native compiler and editor implemented)

N03 replaces the former T08 external build with the **bundled GDScript-native compiler**: Gogo source → native lexer/parser/typed model (N01) → native GDScript emission/source maps (N02) → direct EditorPlugin build/validation on F5/F6 (N03) → generated ordinary `.gd` → Estragon's independent runtime.

No Bun/Node is required to **use** the final addon, and no runtime XML/JSON interpreter, engine fork or native extension dependency is introduced by the current compiler migration. ADR-0015 separately approves Node-based target components. Keep compiler logic separate from editor UI, scene tree and renderer; retain current supported syntax and generated signal semantics. Fresh-project Godot-only editor tests exercise Play with tools absent, error blocking and recovery. Existing TypeScript tests may remain optional CI/reference tooling.

N01 lives entirely in `addons/estragon/compiler/`: `source.gd` indexes source,
`lexer.gd` scans tokens at explicit offsets, `parser.gd` composes balanced GDScript
ranges with recursive component islands, `validator.gd` resolves built-in
contracts, and `model.gd` carries typed frontend data. `frontend.gd` coordinates
these layers and returns structured diagnostics without engine error logging.
They use RefCounted data only and have no EditorInterface, scene-tree, renderer,
resource-import or process dependency. GDScript strings/comments are scanned,
not rewritten; Unicode regular expressions classify identifier characters only.
N02 consumes this model in `emitter.gd` through `compiler.gd`; `source_map.gd`
tracks copied/generated ranges. `script_validation.gd` uses synchronous native
GDScript.reload(). On Logger engines a scoped, thread-safe adapter captures
generated-line errors and maps them back to Gogo; older engines retain native
errors and explicitly report unavailable authored locations. Failed validation
exposes no executable. On 4.4+ a tested cache-only/ordinary path setter pair
establishes relative resources and registered class identity without taking over
application scripts. On 4.0–4.3 isolated path validation is explicitly unavailable;
the owner-approved native build transaction instead requires actual-path native
validation before success, with file/cache rollback on failure. N03's native build service adds tool-mode loading, source discovery, transactional
publication and explicit state-preserving editor resource reload. The standalone
validation API never substitutes a cached application Script for an isolated
candidate. Publication synchronizes cached Scripts even when source bytes match,
because source equality alone cannot prove bytecode freshness. See
[C01_E_VALIDATION.md](C01_E_VALIDATION.md) and [GOGO_LANGUAGE.md](GOGO_LANGUAGE.md).

## Target pipeline and layer responsibilities

`Gogo + GGX → native lexer/parser → typed model → GDScript + source maps → Godot semantic validation → retained native Nodes and model Objects`

The compiler uses an internal typed model, never runtime markup interpretation. Analysis/codegen are independent of EditorInterface, rendering and a running SceneTree; generated applications use native Nodes normally.

| Layer | Responsibility / current boundary |
| --- | --- |
| Native compiler/editor | Implemented parser, typed built-ins, code/maps and fail-closed actual-path transactions; general Node type/property/signal resolution needs reviewed migration. |
| Bindings/models | Planned Gogo-only lowercase @bindable, non-Node typed models, observable collection/item events and scoped subscriptions. |
| Layout | Current RefCounted fixed/auto/fill stacks; target composed mathematical 2D/3D measure/arrange with event-driven invalidation. |
| Visual components | Current display-list text/rectangle primitives and primary pointer dispatch; target native Node2D/Node3D participants using Godot presentation. |
| Entries/adapters | Current surface host; target explicit spatial entries and native bounds/authority adapters, with no automatic layout through ordinary Nodes. |
| Godot | Native scene ownership/lifetime, transforms, physics, rendering and platform/window services. |

[REACTIVITY_PLAN](REACTIVITY_PLAN.md) preserves lowercase Gogo-only annotations and data-model requirements while adapting layout/lifecycle/repeaters to retained Nodes. The earlier RefCounted Box target is superseded; share future box behavior through composition. No new reactive behavior is implemented.

### Historical rendering implementation and research

Stage-0 and the current surface use RenderingServer canvas primitives, with one surface canvas item and ordered display commands. This remains tested implementation, not an obligation to build a competing renderer. Earlier proposals for a universal versioned display list, RenderingDevice/GDExtension backend and optional-only Node adapters are superseded as architectural requirements by ADR-0015; backend-specific optimizations can be proposed later with measurements. Godot-native visual components may choose appropriate drawing/presentation APIs without a universal per-Node drawing requirement.

### Implemented language/runtime history

The following T04–T08 sections describe supported examples and current RefCounted APIs. Their no-per-component-Node statements describe that implementation only. Preserve tests, code, source maps and archival FAIL/BLOCKED/UNTESTED results until each replacement is reviewed and proved.

## Markup-to-GDScript vertical slice (T04)

The implemented path is namespace-free `.gogo` markup → component-expression
syntax → typed component/literal IR → ordinary generated GDScript extending
`EstragonSurface`. No serialized UI IR is used on this path. The legacy stage-0
compiler/JSON host remain independent and unchanged.

`tools/gogo/parser.ts` is a recursive-descent markup-island parser with source
spans, not an XML document wrapper. `parseMarkupExpressionAt()` can consume one
expression inside a future hybrid parser's source; it does not parse GDScript.
`validate.ts` resolves exactly three runtime component names and validates
literal property types/child rules. `emit-gdscript.ts` emits stable typed
construction, property assignments, add-child calls and surface mounting.
`model.ts` separates syntax from typed literal/component expressions without
inventing unimplemented GDScript constructs. No Godot API is used by the compiler.

`tools/transpile-gogo.ts` is the explicit Bun CLI; `tools/check-gdscript.ts` checks
the committed example bytes. The Godot runner recompiles into its temporary
project before import, so its runtime suite tests actual new compiler output.
The generated surface uses T03's lifecycle; application code never disposes UI
components. `examples/compiled/Compiled.tscn` is the runnable example.

This section describes T04 only; T05 hybrid composition is described below.
T07 adds Button callbacks below; T08 adds editor build hooks. Binding generation remains future work. The markup-only parser/IR does not define
the whole language. See [GOGO_LANGUAGE.md](GOGO_LANGUAGE.md) for exact grammar,
properties, commands and limitations.

## Hybrid GDScript/markup composition (T05)

`hybrid-parser.ts` lexes GDScript strings/comments/identifiers/operators and
balanced delimiters, dispatching only expression-position markup to the extended
T04 parser. GDScript source ranges and component AST nodes coexist in one module.
Braced props/children recursively contain GDScript ranges and markup. This is a
lexical composition frontend; Godot still parses and typechecks the resulting
GDScript. It does not replace the GDScript language implementation.

`validate.ts` reuses component/property rules and distinguishes literals from
GDScript expressions. `emit-hybrid.ts` copies authored ranges and emits typed
static factory calls/methods for component construction. Dynamic arguments are
evaluated at the authored call site, preserving local/member scope and native
operators/control flow. Values are eager once per construction in source traversal
order; conditionals inside expressions remain native/lazy. No binding polling,
closure capture transformation or runtime markup interpretation is introduced.

`source.ts` provides UTF-16 indexing; `source-map.ts` emits a versioned range map
with source content and copied/generated spans. The CLI writes hybrid `.gd` and
`.gd.map.json`; validation annotates generated Godot diagnostics with original
Gogo coordinates. This is sufficient for source tracing, not a complete editor
source-map/breakpoint service. Literal-only T04 fixture bytes remain unchanged.

`examples/mixed/Mixed.gogo` extends EstragonSurface, mounts `build_view()` in its
ordinary `_init`, and exposes explicit rebuild. Surface ownership automatically
cleans old trees. Helper modules can remain RefCounted and return components.
No new runtime classes, widget Nodes, signal wiring or subscriptions are needed.
See [GOGO_LANGUAGE.md](GOGO_LANGUAGE.md) and ADR-0009 for the exact minimal grammar,
type/evaluation limits and unsupported nested named-class markup.

## Independent runtime (T02/T03)

`EstragonDisplayObject` and `EstragonContainer` are typed `RefCounted` objects.
`EstragonVBox`, `EstragonHBox` and `EstragonRect` build on them. Components have
no Godot Node, Control, CanvasItem or RID. These runtime classes can be authored
in GDScript today; T04 also compiles a minimal markup subset to these classes. The legacy JSON
host is unchanged and remains the main scene. `examples/layout/Layout.tscn` is a
separate runnable demonstration.

### Identity, ownership and automatic lifecycle

- `get_instance_id()` is identity for the object's lifetime; moving a component
  preserves it. Authored IDs, reconciliation and persisted identity are future work.
- Containers strongly own ordered children with weak parent links. Enumeration
  returns a shallow snapshot. `add_child(child)` appends or transfers an existing
  child after validation; **move directly to the new owner, without removing first**.
- `remove_child(child)` unmounts and recursively cleans the child automatically.
  `replace_child(old, new)` preserves the old slot and cleans the replaced tree.
  An invalid replacement leaves the original tree intact. Replacing with itself
  is a no-op. An existing descendant may be moved out before its old tree is cleaned.
- One `EstragonSurface` Node owns a root and one renderer. `set_root(component)`
  mounts/replaces; `set_root(null)` unmounts. Replaced roots, surface tree exit,
  and surface destruction automatically clean their owned subtree. The framework
  disconnects root/viewport subscriptions and releases the canvas RID. The same
  host may re-enter with a fresh root. External references to unmounted components
  remain terminal/disposed; they cannot be remounted. Live roots have one surface
  owner and cannot simultaneously be container children.
- **Application developers do not call disposal during normal component usage.**
  `_dispose()` is an internal, idempotent mechanism. Subclasses release resources
  in `_dispose_owned_resources()`; container subclasses call super to preserve
  recursive cleanup. Transfers skip cleanup. Adoption from a disposing ancestor
  is rejected, including from cleanup hooks.
- Raw, never-mounted RefCounted trees can be constructed/tested independently;
  dropping references uses Godot reference counting, not a virtual cleanup hook.
  Resource/subscription lifecycle starts with framework ownership. Always mount
  application UI in a surface; callers need no manual component cleanup. The
  framework does not depend on unsafe RefCounted final-deletion method calls.

Tree operations return `Error`: `OK`, `ERR_INVALID_PARAMETER` (null, cycle or
terminal additions), `ERR_ALREADY_EXISTS` (same-parent add), `ERR_DOES_NOT_EXIST`
(non-child removal/replacement), `ERR_UNAVAILABLE` (disposing owners), or
`ERR_ALREADY_IN_USE` (dual surface ownership). Internal underscore fields and
methods are not application mutation APIs. This deliberately corrects T02's
remove-without-cleanup/manual-dispose convention; see ADR-0008.

### Minimal sizing and layout rules

- `width`/`height`: `-1` means intrinsic auto; finite nonnegative values are fixed
  sizes (zero is valid). `fill_width`/`fill_height` opt into the allocated space
  when that dimension is auto. Fixed dimensions take precedence over fill.
- `measure()` recursively computes natural sizes; `get_layout_rect()` reports
  arranged local coordinates. Plain containers overlay children at `(0, 0)` and
  naturally measure the maximum child dimensions.
- VBox/HBox sum natural main-axis sizes and gaps, and take the largest natural
  cross-axis size. `gap` is finite and nonnegative; empty stacks have no gap.
  Main-axis fill children equally divide the nonnegative space left after fixed
  or intrinsic children and gaps. Cross-axis fill uses the allocated cross size.
  Fill alone contributes no extra natural size. Fixed/intrinsic content may
  overflow; flexible sizes clamp to zero. There is no shrink, clipping, wrapping,
  percentage sizing, padding, alignment catalog or Flex/CSS compatibility claim.
- The surface allocates viewport dimensions to auto root dimensions; explicit
  root dimensions win. Geometry uses Godot `Vector2`/`Rect2`, without GUI layout.
  Invalid dimensions/gaps/arranged geometry emit engine errors and leave the
  previous value unchanged; the validation runner rejects such errors.

### Invalidation, paint boundary and rendering

New components start dirty. Tree/layout/paint flags propagate to ancestors;
property setters invalidate the affected phases automatically. Root invalidation
and viewport `size_changed` schedule one coalesced deferred surface update.
There is **no per-frame polling**. Layout runs for tree/layout dirtiness, while
color-only changes repaint without remeasurement. Local acknowledgement does
not clear descendants implicitly; traversal clears completed work.

`EstragonPaintList` contains typed ordered fill-rectangle and text-run commands
in absolute surface coordinates. Containers accumulate local offsets; zero-area rectangles
produce no command. This is an in-memory paint boundary, not serialized Gogo IR
or a general/versioned display-list format. `EstragonCanvasRenderer` alone uses
RenderingServer, clearing/redrawing one canvas item per surface. Backend ownership
and cleanup belong to the surface, not individual components. RenderingServer
remains a provisional backend; other backends are still research topics.

`tests/godot/components.gd` tests the foundations. `tests/godot/layout.gd` tests
nested geometry, paint output, real SubViewport resizing, renderer allocation and
automatic lifecycle paths. See [TESTING.md](TESTING.md) for error probes and visual
verification limits. T06 adds text and buttons below; binding graphs and a broader
widget suite remain planned.

## Text, buttons and primary-pointer input (T06)

`EstragonText` extends DisplayObject; `EstragonButton` extends Text. Both remain
RefCounted logical components. `text`, `font_size` and `font` invalidate layout
and paint; `color` invalidates paint only. Text measures complete shaped strings
using Godot's low-level [Font resource](https://docs.godotengine.org/en/4.7/classes/class_font.html),
not a Label or Control. Default font is `ThemeDB.fallback_font`, size 20. Explicit
`\n` lines use maximum line width and summed font heights; empty text reserves
one line height. There is no wrapping, ellipsis, rich text, clipping or advanced
localization API. Font resources are shared, treated as immutable inputs; reassign
`font` (even the same resource) after editing its data to invalidate measurements.
Font must be nonnull and size positive; rejected assignments preserve prior values.

Button adds fixed padding `(14, 8)` per side to intrinsic text size; normal sizing
rules still apply. The label is centered in positive extra allocation. Normal,
hover, down-inside and disabled states have minimal fixed colors, exposed through
`get_visual_state()` / `get_background_color()`. `disabled` cancels any active
interaction. This is a small component contract, not a theme/style system.

The authoritative paint list is `commands`, interleaving FillRect and TextRun
snapshots in traversal order; `rectangles` is retained as a compatibility inspection
view. TextRun stores baseline, complete string, Font reference, size and color.
Only the renderer issues `Font.draw_string()` / RenderingServer calls to the same
surface canvas item. No component owns a Node, CanvasItem or graphics RID. Font
resources manage shared glyph data; no Estragon per-component glyph atlas exists.

### Targeting and gesture contract

The surface adapts Godot `_input` to `dispatch_pointer(event)` and marks a handled
event on its Viewport. Input is already in viewport coordinates; Estragon's
current surface is at the viewport origin. It synchronously resolves pending
layout before hit testing, so changes and resizes apply to the next input event.
`get_surface_rect()` accumulates nested local offsets. Containers traverse
children in reverse paint order. Only buttons are targets; noninteractive text/
rectangles pass through, and disabled buttons occlude buttons below. Bounds are
half-open (right/bottom excluded). Children can overflow/hit beyond parent bounds,
matching existing unclipped painting, but positions outside the viewport cancel.

`EstragonPointerDispatcher` has weak hover/capture references and no per-button
registrations. Its intentionally narrow model handles mouse motion and the left
button; other buttons, wheel, keyboard and touch are ignored. There is no bubbling,
keyboard focus, gesture recognition or public event-object catalog yet.

- A down captures the enabled button under the pointer. Repeated down events
  during that press are ignored. A down outside cannot become an inside press.
- Motion updates hover. While captured, down appearance is present only over the
  captured target; leaving/reentering is permitted within the viewport.
- Release emits the parameterless typed `pressed` signal exactly once **only**
  if the original target is still enabled/live and is the current topmost target.
  Release outside or over a different button activates neither. Unmatched and
  duplicate releases do nothing. Capture clears before application handlers run.
- Window focus loss/mouse exit cancels the gesture. The surface subscribes to
  native Window signals, independently of Godot GUI event routing. Layout updates
  refresh stationary hover without per-frame polling.

### Automatic interaction cleanup

Removal, replacement, root unmount, and surface destruction clear pointer state;
terminal components disconnect incoming direct method and outgoing signal connections (including closures)
and Text releases its Font reference. Disposal hooks in subclasses must call
`super` to preserve framework cleanup. Disposed objects cannot be hit or activated.
Transfers cancel the old gesture before changing parent links, including between
surfaces, but preserve component identity, signal connections and live resources.
Move directly to the new parent; no application disposal call is needed.

Window input subscriptions are removed on surface exit, alongside existing root/
viewport subscriptions and canvas cleanup. Re-entry starts with a fresh root.
Handlers may synchronously replace the root; use Godot's normal `queue_free()`
when destroying a host from its input/signal callback. Queued hosts reject input.

`examples/interactive/Interactive.tscn` uses ordinary GDScript `pressed.connect`
handlers to update text with Add one and Reset buttons. Text changes schedule
layout/redraw automatically; they are not reactive bindings. The Gogo compiler now accepts Text/Button and generates Button.pressed connections
in T07; the earlier ordinary GDScript example remains preserved. See TESTING for the interactive procedure and CI coverage.

## Generated interactive Gogo (T07)

The explicit compiler registry now maps five built-ins: VBox/HBox/Rect/Text/Button.
Text and Button share typed text/font_size/color and inherited sizing; Button adds
disabled and one compiled event, pressed. The hybrid IR uses ordered discriminated
property/signal attributes, preserving eager argument evaluation across both.
Factories receive typed String/int/Color/bool properties and Callable callbacks;
instance/local references evaluate at the original call site. Generated guards
check native validity/zero-remaining arity and reject terminal direct component
targets, then connect the native signal once. All emitted connection/guard ranges
map back to their authored event expression. Older fixtures remain unchanged.

`examples/counter/Counter.gogo` is the first complete interactive authored screen:
its generated connections invoke increment/reset methods, explicit root rebuilds
refresh text and disabled state, and automatic lifecycle disconnects old sources.
Direct target disposal also disconnects incoming method connections; ordinary
reparenting preserves them. Arbitrary lambdas can contain application effects not
visible to metadata checks. Full GDScript semantics remain Godot's responsibility.
No callback wrapper interpreter, per-component Node or new subscription service
is used. See GOGO_LANGUAGE/ADR-0010 for validation limits and TESTING for the gate.

## Historical performance proposal (revisit per native component)

Track independently dirtied state, layout and paint; retain component identities; batch paint primitives; minimize allocations and GPU submissions; manage scissoring/clips and cache glyphs/resources. Measure CPU and GPU cost, startup time, frame pacing and memory on concrete workloads instead of assuming lower-level drawing automatically means faster rendering.

## Godot editor compilation boundary (T08/N03)

The optional EditorPlugin owns native TextFile highlighting, saved-source events,
unsaved-buffer save-before-Play and the diagnostic panel. The scene-independent
native `editor/build_service.gd` handles project discovery, compile-all and semantic
validation, staged/rollback publication and in-place generated Script refresh.
It uses no subprocess, executable setting or reference TypeScript code.

Explicit gogo.config.json roots remain authoritative; absent config scans project
sources excluding addon/dependency/hidden/generated/test directories. Adjacent
outputs/maps preserve resource paths and UIDs. Identical bytes are not rewritten.
All source/path checks precede staging; all semantics pass before a build succeeds.
Rename backups restore output bytes/maps/timestamps after a failure, and the common
F5/F6 `_build` returns false. This is transactional failure handling, not crash
journaling or an application sandbox.

Order native validation/reloads from static extends/preload edges using the
existing lexer; Godot decodes lexer-proven resource string literals, never
application expressions. Refresh each validated dependency in place before its
dependents; on failure restore old disk/cache code. Godot's GDScript cache can
retain bytecode despite resource-filesystem updates or ResourceLoader replace
modes; the explicit reload is tested with changed dependency types and live Script
identity. Filesystem records/class metadata are updated for committed paths. A
fresh game process reads current files; no live game hot-reload is introduced.
All compiler modules are tool-callable but remain independent of EditorInterface,
UI state and rendering. Editor Controls remain tooling only. See EDITOR, TESTING
and ADR-0012 for the verified no-tools workflow and remaining editor features.
