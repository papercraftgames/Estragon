# ADR-0015-B1: bounded native GGX composition proof

**Work ID:** ADR-0015-B1, [#71](https://github.com/resistdesign/Estragon/issues/71). Implements only the first proof from [ADR-0015](DECISIONS.md#adr-0015--ggx-node-native-composition-and-layout-first-estragon) / [owner #68](https://github.com/resistdesign/Estragon/issues/68) and [NODE_MIGRATION_PLAN](NODE_MIGRATION_PLAN.md). It does not migrate Estragon's RefCounted runtime or implement B2 layout entries, B3 native layout adapters, bindings or general native type/import resolution.

## Explicit native compiler selection

The experimental API is separate from ordinary `compiler.gd` / `Compiler.compile`:

```gdscript
const NodeProof = preload("res://addons/estragon/compiler/node_proof/compiler.gd")
var result = NodeProof.compile(source, "res://Example.gogo", {
    "Probe2D": preload("res://examples/node_proof/probe_2d.gd"),
    "Probe3D": preload("res://examples/node_proof/probe_3d.gd"),
})
```

Callers explicitly supply any custom script aliases and declare the same preload constants in the authored module. This is type resolution, not an attachment protocol. Built-in tags are **Node, Node2D, Node3D, Timer, Polygon2D and MeshInstance3D**; custom aliases must be preloaded GDScript deriving directly from a native Node2D/Node3D base (script inheritance is allowed). They must support zero-argument construction. No arbitrary native-class registry, automatic imports or pragma is introduced. Only GDScript-first modules are supported by this proof.

The shared native lexer/parser retains GDScript and parses real GGX expression islands. The separate proof validator reads ClassDB/Script property and signal metadata without instantiating authored scripts or entering a SceneTree. Native property types supported here are bool, int, float, String/StringName, Vector2/Vector3, Color, PackedVector2Array/PackedVector3Array, Variant and Object-derived references. Other metadata types produce explicit diagnostics. Quoted values are strings only; other values require GDScript braces. Unknown/duplicate properties/signals, unsupported types, reserved `owner`/`script` attributes, non-Node tags and borrowed/expression children are rejected with original source spans. Namespace/pragma support is not added.

The specialized emitter reuses existing typed static factory calls and range maps. Expressions evaluate exactly once in source traversal order, in authored scope, before construction. Factories construct native Nodes, assign typed properties and use **only inherited, void-returning Node.add_child(Node)**. There is no runtime markup interpreter or Error-returning child-adoption test. Descendant ownership is assigned only after the complete newly declared subtree exists.

GGX native signal attributes accept named handlers/Callable expressions, including bound Callables. Inline anonymous `func` declarations in these attributes are rejected lexically. Generated native connections use CONNECT_PERSIST and are established once; invalid dynamic Callables/connection failures free the new subtree and return null with an authored diagnostic. Godot remains responsible for native argument/signature/conversion semantics at compile or invocation time; B1 does not claim a complete signature checker. Referenced non-Node Object signals use ordinary Gogo/GDScript signal expressions, demonstrated by `palette.changed.connect(on_palette_changed)`. No new Object-child or event-dispatch syntax is needed.

`Compilation.ok` means frontend/emission success, not semantic validity. The example's explicit native builder validates at the **actual output path** through the existing semantic-validation API. It stages code/map, preserves unchanged bytes/timestamps, backs up old files by rename, and rolls disk/maps/timestamps plus cached Script bytecode/state back on failure. Failed builds expose no executable. No isolated path preflight substitute or external process is used. On 4.7, Logger diagnostics map native failures to original authored lines; 4.0.4 retains native diagnostics and reports original source identity with explicit unavailable exact location, as in C01-E.

## Ownership, persistence and native lifecycle

A factory returns a detached new root. Its newly declared descendants have `owner = root`; the root has no owner. B1 rejects expression children, including existing Nodes, so generation never silently adopts a borrowed/external Node or traverses its subtree. Ordinary Node removal detaches without disposing; freeing a native parent recursively frees children, and freeing a native signal target removes its connections. Reparenting by native remove/add preserves instance identity; layout/reconciliation is not involved.

The sample hosts a newly constructed subtree beneath an authored Node2D script instance. Its explicit `persist_new_subtree` method assigns the newly built Nodes to that hosting scene root before PackedScene packing. This demonstrates the distinction between parentage and scene ownership; it is not a universal adoption helper or an automatic editor-wide owner policy. Pack the owning scene containing both native signal source and handler target to preserve internal connections. Arbitrary external endpoints are not promised persistent identity. Non-exported runtime state is not promised serialization.

The referenced Gradient is a property value, not a GGX child. Its native `changed` subscription is established on tree entry and explicitly disconnected from the observed Resource on exit, with no CONNECT_PERSIST flag. Reentry reconnects once. Native target freeing is also tested with a still-live source. An unrelated unowned Node attached outside GGX is excluded from the saved scene; no external owner is silently changed.

Native transform assertions demonstrate Node2D and Node3D chains and their interruption by plain Nodes. The example does not assume pixels are 3D world units, share 2D/3D transform ancestry, add an overlay conversion, or define 3D wrapping/measurement. Those decisions remain B2/B3/focused specifications.

## Runnable example

See [the example instructions](../examples/node_proof/README.md). Scene: `res://examples/node_proof/Main.tscn`; source: `examples/node_proof/.proof/Composition.gogo`. The hidden `.proof` directory deliberately opts out of default Gogo source discovery. Normal editor builds and the repository's explicit roots continue to use the existing compiler, with no fallback or mode inferred from a tag.

The example shows a native Polygon2D and a nested custom/native 2D/3D hierarchy. Press Enter/Space to start a native Timer; its generated timeout connection changes the polygon from teal to purple. Inspect the Remote tree for actual Nodes. There is no Estragon layout or 3D camera/rendered 3D demonstration in B1.

## Verification and limitations

Use the existing TypeScript runner without installing new packages or changing repository manifests:

```sh
# Run from outside the repo because its historical packageManager is Bun.
cd /tmp
corepack yarn@1.22.22 node --experimental-strip-types /absolute/Estragon/tools/check-node-proof.ts \
  --engine /absolute/official/godot --output /new/absolute/evidence-directory
corepack yarn@1.22.22 node --experimental-strip-types /absolute/Estragon/tools/check-node-proof.ts \
  --engine /absolute/official/godot --output /same/absolute/evidence-directory --phase visual
```

Run once per approved engine, official **4.0.4** and pinned **4.7.0**, never any other minor. `--phase build|runtime|negative|editor|visual` supports focused development. `all` requires a new output directory. The runner copies a self-contained editor/project, checks native version (and official original binary SHA on macOS), ad-hoc signs only the macOS copy, and gives engine children an **empty executable PATH**. Existing native class indexing is reused. Runtime tests verify actual behavior rather than reload success alone. Two graphics-backed editor sessions reopen/save the PackedScene through EditorInterface. Tests and example use native GDScript/Gogo; contributor orchestration uses TypeScript/Yarn only, no Python.

Graphics-backed stages require a desktop/display. Linux CI uses Xvfb and software OpenGL in the existing 4.7 job; macOS uses native graphics for the existing 4.0.4 job. Dummy audio avoids host audio requirements. No physical keypress gate or global editor setting change is required. The new checks add no engines or parallel implementation PRs.

The negative harness permits only the exact expected type/name errors and invalid-Callable diagnostic and requires all rejection markers. Unexpected errors/leaks/assertions still fail even if Godot exits zero. Initial focused headless attempts exposed a 4.7 dummy-renderer thumbnail error and a 4.0.4 dummy-mesh cleanup error. They were not suppressed or relabeled PASS: persistence and negative recovery now run against actual graphics. The 4.0 editor driver uses a process state machine to avoid suspended continuations across native editor script reloads. These are isolated harness choices, not C01 framework fixes.

Final measured results are preserved in [4.0.4 evidence](../tests/compatibility/b1/4.0.4/provenance.json) and [4.7.0 evidence](../tests/compatibility/b1/4.7.0/provenance.json), with adjacent build/import/runtime/negative/editor-1/editor-2/visual logs and before/after PNG captures. Both engines passed 51 runtime assertions, two native editor save/reopen sessions and native visual Timer activation; negative assertions were 72 on 4.0.4 and 75 on 4.7.0 (the extra three check Logger authored-line mapping). Existing `bun install --frozen-lockfile` and `bun run check` passed: 202 tests, 671 expectations, typecheck and legacy/generated example consistency. The existing suites use historical Bun tooling; the new proof runner uses Yarn.

Local command prefix: `cd /tmp && corepack yarn@1.22.22 node --experimental-strip-types /Users/ryan/Projects/Estragon/tools/check-node-proof.ts`. 4.0.4 used `--engine /Users/ryan/Library/Caches/Estragon/compatibility-engines/4.0.4/godot --output /tmp/estragon-b1-acceptance40`; 4.7 used `--engine /Applications/Godot.app/Contents/MacOS/Godot --output /tmp/estragon-b1-preflight47`. Each full run was followed by the same command with `--phase visual`. Commands, original binary SHA, pre-commit base and per-file source hashes are recorded in provenance. These working-tree runs truthfully report `sourceDirty: true`; they are B1 development evidence, never clean-source release authorization.

Compiler determinism is asserted before editor persistence. The 4.0.4 editor may normalize generated script indentation while saving its isolated copy; this is disposable editor output, not a compiler output difference or permission to edit the checked-in generated fixture by hand. Manual legacy Hello/editor/key interactions were not performed; inspected B1 native captures are separate evidence from automated runtime/editor assertions.

The existing full pinned regression command `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot bun run check:godot` also passed: project import, every-script parse (including proof scripts), native frontend/runtime/layout/interaction/signals and mapped negative cases. Its exact log is [existing-regression.log](../tests/compatibility/b1/4.7.0/existing-regression.log).

Raw Godot logs retain engine-emitted trailing whitespace; source/docs hygiene uses `git diff --check origin/main...HEAD -- . ':!*.log'`. Logs are not rewritten merely to satisfy whitespace checks.

## Release boundary and next task

Strict C01 release remains **BLOCKED**. Raw-string/hybrid findings are outside this proof's bounded syntax; cold missing-generated scene restoration is not fixed (the explicit builder runs before scene loading); #65 resource-pack exporter cleanup is not certified by PackedScene serialization; standalone executable/platform scope remains open. Existing C01 fingerprints, results and release gates are unchanged. Development/PR success does not authorize publishing or claim full Godot 4.0+ certification.

Only B1 is submitted. B2/B3 and the broader C1–C4 migration remain queued until separately selected, scoped and owner-reviewed. Do not auto-merge or start them from this PR.
