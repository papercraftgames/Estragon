# F01 — native signal-driven function composition spike

[F01 #92](https://github.com/resistdesign/Estragon/issues/92) implements the first bounded vertical path of [ADR-0016](REACTIVE_COMPOSITION_ARCHITECTURE.md). Exact acceptance/review/merge state and provenance are on the live issue/sole PR. F02 conditional/deep composition, F03 keys/lists and F04 final eager/helper removal remain future work. This is a deliberate spike, not the complete ADR-0016 renderer or a permanent second API.

## Authoring

```gdscript
extends Node2D
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
@bindable var count: int = 0

func build_view() -> Element:
    var caption: String = "Count: %d" % count
    return <EstragonVBox>
        <EstragonText text={caption} />
        <EstragonButton text="+" pressed={increment} />
    </EstragonVBox>

func increment() -> void:
    count += 1
```

The exact initial convention is a top-level zero-argument instance `build_view` with an explicit return alias preloaded from `runtime/composition/element.gd`. The compiler recognizes its lexical function range; its GGX returns typed lightweight **desired descriptions**, not eagerly allocated Nodes. Locals, ordinary helper calls, native operators and normal readable GDScript remain valid; expression children/keyed lists/nested component composition are not supplied. Each description contains constructible type identity, evaluated declared props, named Callables, ordered child descriptions and source location. Typed factory parameters and existing metadata/native validation enforce property types; maps retain authored expression spans. There are no regex source substitutions, runtime XML/JSON or external product compiler.

The host must derive from Node. F01 reserves the generated `_notification` lifecycle hook; authored `_notification` explicitly rejects, while `_ready` and event methods remain ordinary. It automatically schedules the first view computation after ready. Author code does not mount, invalidate, refresh, subscribe or rebuild the root. Run `examples/composition/Counter.tscn`; the existing T09-B Counter remains separately operational until the F04 parity/removal gate. No long-term dual API is promised.

## Getter observation and scheduling

All compiler-generated Gogo bindable getters now return their normal typed backing values and register (`Object identity`, native property-change signal) in the active computation scope. Outside that scope they are ordinary getters. Reads in helpers, bare/self/external property accesses and inherited Gogo getters use the same native path; no explicit-path dependency parser or per-property binder Node is used by F01. Only instrumented Gogo properties are observed. Arbitrary native/.gd fields, raw Array/Dictionary mutations, and transforms do not acquire automatic signals.

A framework-owned preloaded Resource holds the scope stack and external computation records. This uses supported 4.0 Resource/script APIs without requiring static variables or an autoload added to consumer projects. It is internal framework state, never a user model/resource/Node metadata field. Scope push/pop isolates nested computations; repeated reads dedup to one source/signal connection. Sources and host references are weak. Each successful computation replaces its subscriptions with the new actual read set, disconnecting stale model dependencies.

Data setters/signals remain synchronous and retain T09-A equality/reentrancy semantics. An observing component queues one deferred safe-phase composition; several writes before it runs produce one function rerun with current values. Unread bindables and equal writes do not schedule. Unaffected components do no work, and idle frames never compose. Composition/commit must not mutate source data; finite notifications while active schedule a later pass, with a bounded error for runaway self-invalidations. No generalized F02 parent-first scheduler or F05 cycle solver is claimed.

Tree exit disconnects and suspends commits; reentry recomputes and reuses the mounted subtree. Deletion invalidates queued work and removes external records. An explicit runtime unmount removes only the managed record Nodes, preserving foreign application children outside the managed region (foreign descendants move back to the host). User code normally relies on native host lifetime. Godot still owns parentage. F01 managed view Nodes intentionally have no scene `owner`: they are runtime output, while authored host/foreign child owner persistence stays separate. PackedScene reload recomposes the managed view once instead of serializing/adopting its old live Nodes. Foreign descendant transfer preserves an existing owner when it remains a valid ancestor. Complete F02 nested foreign-branch conflict handling and later persisted-region adoption are deferred.

## Retained static-shape reconciliation

Initial mount creates each actual Godot Node exactly once; descriptions are RefCounted values, not a second SceneTree. Subsequent compatible type/position descriptions reuse the same actual Nodes. F01 validates the entire static shape before a commit and rejects changed type/child shape/property or event sets, retaining the previous tree. General conditional branch replacement, nested component ownership and keys belong to F02/F03.

External mounted records hold previous desired values, actual weak Node identity, children and handlers. Only a newly declared desired value differing from the previous **desired snapshot** writes the native property. Unchanged desired values preserve game/animation changes on the actual Node; bookkeeping is not stored on that Node. Handler diffs disconnect/reconnect changed Callables without duplicate connections. No set_meta, hidden fiber/key property, extra tracking Node or throwaway candidate native Node is introduced.

Existing native setters distinguish redraw/input changes from text/dimensions/gap/fill invalidation; the same composed affected-branch layout handles actual geometry changes. Recomposition itself does not rewrite unchanged layout inputs. Static root placement remains native; F01 does not expand layout-controlled transform authority or resolve deferred #88.

## Verification and boundaries

`tools/check-composition.ts` runs isolated Godot-only build/import, native getter/description/reconcile/lifetime/type/map tests, a real editor with saved/unsaved main/current Play, invalid/unsavable-source rejection, transactional code/map/UID/timestamp/cache rollback and repair, plus rendered Counter captures. It is included in strict current-addon evidence and fresh/cold/pack distribution. The framework `runtime/composition/state.tres` is a required runtime dependency; selective resource-pack exports must include it along with the scripts. The native pack fixture explicitly selects this resource and verifies the exported pack in a separate bare process. Focused workflow mode `composition` selects one approved engine; final acceptance uses official Linux 4.0.4 and pinned 4.7.0 only. Exact commands, hashes, outcomes and manual-smoke status live on #92/its PR. Native semantic diagnostics retain C01-E's measured capability difference without weakening actual-path validation or rollback.

Remaining: F02 conditional expression children/deep component ownership/parent-first scheduling, F03 mapped/keyed arrays, F04 single-renderer cutover and deletion of eager/property-binding paths, F05 class-wide bindability/two-way, F06 profiling/optimization. No hooks, new transport, per-frame recomposition, second layout core or untested engine/platform promises.
