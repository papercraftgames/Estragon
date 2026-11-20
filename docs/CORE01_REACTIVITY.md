# CORE-01 — signal-driven render-call caching

Implementation for [#195](https://github.com/papercraftgames/Estragon/issues/195), following ADR-0031. The live issue/sole PR controls review and merge status. This is the function-memoization slice; implicit two-way controls and CORE-02 collections/typed hydration remain separate.

## Authored functions and calls

A Gogo function containing literal GGX is a reactive render function. Its own getter reads, including locals and conditional tests, invalidate its cached result. The compiler records source-derived method metadata and lowers render calls with source-spanned invocation IDs. Named methods, imported Script/static methods, inherited/super methods and locally declared GGX lambdas retain native execution. Callable.call/callv dispatch uses the same argument cache; native Object.call/callv resolves the actual target method. Per-source metadata constants avoid inherited member collisions and distinguish ordinary overrides from inherited GGX bodies. Native super calls use a sourced adapter with stable lexical cache identity. Native argument checks are preserved in an unexecuted native proof closure; typed return metadata preserves inferred locals. Native constructors, intrinsics and collection traversal retain native semantics. A handler reference is a value; it runs on its actual native event.

Ordinary functions called from render cache explicit evaluated arguments. Their bodies are opaque: hidden bindable reads, including reads through a nested GGX helper, do not become dependencies. A zero-argument ordinary helper stays static until its occurrence is removed. Manually constructing Element objects does not mark a function reactive. Pass changing values explicitly:

```gogo
func label(value: String) -> String:
    return value.to_upper()
func badge() -> Element:
    var caption: String = self.model.title
    return <Text text={label(caption)} />
```

This deliberately changes the previous dynamic observation through ordinary helper bodies. The composition Counter now passes its title explicitly. There are no independent live recipes for individual markup properties.

## One manager, bounded ownership

Each native host has one external Computation under the existing State manager. Each logical call occurrence holds one last argument/result record, weak observed sources and parent/child invocation links. Scalars compare by typed value; Array/Dictionary arguments compare by identity, Object arguments by weak identity. An observable argument subscribes to its real `changed`, per-property `*_changed` and Node `tree_exiting` signals, so same-identity data can invalidate without a revision number. Raw Array/Dictionary in-place edits emit no change event and keep their cache until the reference changes. CollectionProbe is a native Resource protocol fixture, not an ArrayCollection implementation.

Distinct authored sites are independent. Repeated keyed Element-returning calls match argument identity across reordering; explicit keyed GGX scopes establish the key before nested arguments execute, including zero-argument helpers. Unkeyed occurrences use lexical position. Preset defaults have their own invocation scope. Child invalidation propagates to enclosing render invocations; clean nested calls reuse results when a parent reruns. Owner subscriptions deduplicate each source/event even when several entries observe it.

Descriptions are values. The existing normalizer snapshots them for each mounted tree, preserving independent native Nodes when one cached description is used twice. Native type/position/key reconciliation, declared-property writes, native input and affected-branch layout remain authoritative.

## Notifications, failure and lifetime

1. A bindable setter updates synchronously and emits its native change signal only under the bindable equality contract.
2. The owner callback marks interested invocation records dirty and queues the owner once. State drains deferred work parent-first; removed descendants are cancelled.
3. The owner enters render and recomputes the root. Arguments are evaluated before cached calls; dirty reactive bodies observe actual executed paths. New reads connect immediately, so a write after a first read cannot disappear during first render or a reentrant pass.
4. Desired output is snapshotted and completely preflighted before native mutation. Failure retains the previous native tree and committed subscriptions, plus only the latest desired repair sources; earlier rejected attempts disconnect. Successful preflight prunes obsolete reads, then commits native changes and schedules existing layout work.
5. One-shot render-side writes receive a later bounded pass, never recursive SceneTree mutation. Repeated self-invalidation retains the existing bounded fail-closed guard; render helpers should be pure.

Branch removal prunes entries; successful changed conditions disconnect old sources. Model replacement releases weak argument/read references. Exit suspends and disconnects caches/subscriptions; reentry rebuilds scopes over retained native output. Free removes the host record and pending work. No metadata, helper Node, alternate scheduler, polling or effects engine is added to user objects.

## Evidence and limits

`tools/check-core-reactivity.ts --editor` builds one reproducible development Yarn tarball and installs it directly under node_modules for both approved Linux engines. It verifies actual compiler semantics/maps, runtime cache/lifetime invariants, 128/256 keyed rows, profiler counters, idle-zero work, rendered native input/geometry, current/main invalid-source rollback and repair, editor restart and unchanged installed bytes/UIDs. Expected native errors are bracketed and counted; all other errors/leaks fail. See [test commands](TESTING.md) and [evidence](evidence/CORE01_REACTIVITY.md).

The 128-row case covers reversal and all retained IDs; 256 covers one-row selectivity, same-order reference replacement and host suspend/reentry/free; branch removal is proven at128. Development 256-row reversal and in-place large subtree removal timed out on 4.0; it is not reported as a pass or a throughput guarantee. Existing F06 large native reorder costs remain. Timing reports separate profiler work from the frame-settling interval. No manual interactive smoke, extra engines/platforms, release certification or publication is implied.
