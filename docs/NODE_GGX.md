# C2 Node-native GGX in normal Gogo builds

[ADR-0015-C2 #79](https://github.com/resistdesign/Estragon/issues/79) integrates
Node composition into the bundled GDScript-native frontend/compiler and normal
Godot addon save/Play transaction. The end user needs Godot plus the addon only.
This is not B1's opt-in proof build and does not change the legacy runtime into
Nodes. [C1](NODE_RUNTIME.md) supplies the real runtime; C3 widget parity and C4
legacy retirement remain separate. Strict C01 release is still **BLOCKED**.

## Compatibility selection

Selection is intrinsic to each expression tree, not a pragma or configurable
child protocol. The shipped short tags `VBox`, `HBox`, `Rect`, `Text`, `Button`
retain their original RefCounted classes, typed literals, leaves, expression
children, Error-returning attachment and historical Button/lambda behavior.
Other tags resolve as Node types. Legacy and native expressions may coexist in
separate methods/expressions of one Gogo module; mixing their tree children is
rejected (expression-valued legacy children still undergo native semantic type
checking). Existing Counter/Mixed/Compiled source and checked generated output
remain unchanged. No blanket inline-function ban applies to legacy events.

Native GGX requires a GDScript-first module. Each tree item is a newly declared
Node; resources/models/other Objects are property/expression values, never tree
children. Borrowed/expression Node children are explicitly rejected until their
adoption/owner contract has a separate reviewed specification. This is not an
implicit ownership transfer or a claimed function-valued child feature.

## Deterministic type and import resolution

Supported native tags resolve through:

1. An unambiguous top-level `const Alias = preload("res://...gd")` (optional
   `Script`/`GDScript` annotation), scanned with the existing lexer, not regex
   rewriting. Only a lexer-proven literal is decoded by Godot. Relative paths
   resolve from the **generated script's directory**, matching ordinary Godot
   preload semantics. Absolute `res://` imports are recommended.
2. Registered project script class names, including C1's `Estragon2D`,
   `Estragon3D`, components and adapters. A normal project import registers these;
   explicit preload aliases also work before indexing.
3. Constructible ClassDB Node classes, including ordinary Node/Node2D/Node3D,
   Timer, Polygon2D, MeshInstance3D, Marker2D and native Controls.

Preload aliases cannot ambiguously shadow native/registered names or reserved
legacy tags. To compose a native Godot Button while `Button` remains legacy,
preload an explicitly named custom script deriving from native Button. Duplicate
aliases, unknown/non-Node/non-constructible types and required constructor
arguments fail at original Gogo spans. Aliases must target GDScript Node scripts
that accept zero constructor arguments. Inner classes, dynamic `load` aliases,
dotted/namespace tag resolution, UID-only imports, cross-Gogo missing-output
import bootstrapping and constructor argument syntax are not guessed or claimed.
Use a supported explicit authored `.gd` alias. Existing source language limits
(e.g. inner-class markup restrictions) remain documented in GOGO_LANGUAGE.

Compiler analysis loads native script metadata but never constructs authored
instances, uses EditorInterface, renders, starts a SceneTree or invokes external
processes. Metadata loading has ordinary Godot resource-loading semantics. It
does not replace an application's cached Script or reload its bytecode during
analysis. If an externally edited `.gd` differs from its cached source, compilation
fails closed with an original-tag diagnostic requesting a normal Godot Script
reload; after reload it recovers with the same Script identity. This explicit
boundary avoids stale metadata or cache takeover. Native editor handling of
ordinary script edits remains Godot's; automatic transactionally refreshing
arbitrary disk-edited external script dependencies is not added here. Tests
exercise stale detection, unchanged cache, native reload and recovery on both
approved engines. A trial CACHE_MODE_IGNORE metadata load changed GDScript's
internal cache, so it was rejected rather than used as a hidden fallback.

## Properties, signals and emission

Native + inherited script property/signal metadata supplies types. Quoted native
attribute literals are strings/StringNames only; other values use `{GDScript
expressions}`. Unknown/duplicate/reserved owner/script and read-only properties
are rejected; unsupported metadata types fail explicitly. Godot then performs
actual semantic typing, required for expression/property/handler validity.
No compile-time success bypasses the existing semantic publication gate.

Native event attributes use named handlers/Callable references:

```gdscript
extends Node
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")

func make() -> Node:
    return <Entry gap={12.0}>
        <Timer name="Pulse" one_shot={true} timeout={on_timeout} />
    </Entry>

func on_timeout() -> void:
    pass
```

Inline anonymous `func` declarations in native event attributes fail; ordinary
Gogo functions/Callable variables remain allowed. Any referenced Godot Object can
supply a signal through normal authored code: the demos connect/disconnect a
Gradient.changed signal in their `.gogo` enter/exit methods. This is not a new
resource-as-child syntax. Native Callable validity/connect checks remain, with
ordinary Godot signal invocation/arity behavior; C2 does not claim general
compile-time Callable body/arity proof on older engines.

The emitter reuses lexical composition, typed static factories and range maps.
Attribute expressions are evaluated once at the authored call site in source
traversal order; function conditionals remain lazy. Factories assign native
properties, create nested Nodes, call only inherited **void** Node.add_child,
then set expression-created descendants' owner to the new expression root and
connect native signals with CONNECT_PERSIST. Invalid dynamic Callables free the
new root and return null with an authored error; ordinary semantic failures block
publication. No foreign Node is adopted. The expression root's owner remains
null until authored code explicitly assigns it after attachment. Native lifetime,
spatial transforms, reparent/free and cleanup remain Godot's, not legacy dispose.
Persisting a host scene requires assigning valid owners explicitly; tests pack/
reload a complete authored host and prove one restored signal graph without
reconstruction. Scoped external Object subscriptions are authored explicitly.

Legacy emission remains unchanged. Small validator extension hooks preserve its
original recursion depth: adding a wrapper per legacy node exhausted debug stack
at the existing 256-level corpus, and that rejected development approach was
fixed without reducing the supported nesting limit or filtering engine errors.

## Normal editor, transaction and demos

`Compiler.compile()` and `Frontend.analyze()` now select native/legacy trees
through the same entry points. Hybrid mode and source map format remain stable.
The existing build service still compiles all sources, stages code/maps, validates
at actual generated paths, refreshes cached Scripts in place and rolls back on
failure. On 4.0.4 isolated preflight remains unavailable; actual-path transactional
validation is mandatory. On 4.7 independent preflight/maps remain available.
Native semantic diagnostics retain the measured older-engine location difference.

The normal plugin source discovery, highlighter, save/open and latest-buffer
F5/F6 gate apply to GGX. Unsavable/invalid buffers block both Play modes; repair
recovers, with code/map/UID/timestamp/cache identity preserved after failures.
The 4.0 editor can normalize generated text on first import; a normal native build
restores canonical output, then unchanged builds preserve bytes/maps and cache
identity. Neither source compile determinism nor semantic validation is waived.

Runnable authored examples and instructions: [examples/ggx/README.md](../examples/ggx/README.md).
Scenes are `res://examples/ggx/TwoD.tscn` and `ThreeD.tscn`; source roots include
`examples/ggx`. They use native/custom Nodes, C1 layout/adapters, resource values,
Timer named events and authored Object subscriptions. Press Enter to grow a fixed
allocation and reflow retained Nodes. Checked generated code is native-built;
normal users save/Play through Godot, with no manual compiler/build command.
The old cold missing-generated scene restoration defect remains a separate C01
release blocker; delivered generated outputs provide initial scene references.

Optional historical TypeScript transpile/build reference tools retain the legacy
subset; they are not the native GGX product compiler and must not be used as a
fallback for these new sources. Bun reference checks still validate legacy
fixtures. New contributor orchestration is TypeScript/Yarn; runtime/compiler are
GDScript/Gogo only. B1/B2/B3/C1 demos/APIs remain separately exercised.

## Evidence and remaining scope

`tools/check-ggx.ts` isolates a fresh addon/project/editor, verifies official
binaries, removes external compiler tools from child PATH, runs normal native
builds, native runtime/negative/map/identity/owner tests, actual editor F5/F6
failure/recovery and real graphics captures. Isolated editor/child Play uses
headless execution and explicit Dummy child audio, as in C01; separate runtime
and graphics stages use the native renderer. This avoids testing nonexistent CI
audio hardware/embedded X11 windows while retaining actual editor APIs, child
execution and independent visual proof. Expected semantic-error diagnostics
are matched only at the authored fixture/generated paths; unexpected errors,
failed assertions, missing markers, timeouts and leaks fail the check. Exact
commands/provenance, PASS/FAIL evidence and inspected captures are recorded under
`tests/compatibility/c2`. Only official 4.0.4 and pinned 4.7.0 are used. No physical
keypress requirement or all-minor/platform certification is implied.

C3 native widgets/parity, C4 retirement, generalized borrowed children/import
namespaces/construction and external-script dependency refresh are not silently
implemented. The small C2 migration contract was posted on #79 before code;
review this concrete implementation and recorded limits. No C3 starts while the
sole C2 PR is open; do not merge automatically.
