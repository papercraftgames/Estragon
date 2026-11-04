# Roadmap and milestones

This is product direction, not a live implementation claim. [EXECUTION_PLAN](EXECUTION_PLAN.md) defines work packages, [WORK_STATUS](WORK_STATUS.md) records the reviewed snapshot, and live issues/PRs hold current ownership and evidence.

## Existing baseline

T01–T08 and N01–N03 are merged: minimal RefCounted component ownership/stack layout, rectangle/text/button rendering, primary pointer input, hybrid Gogo-to-GDScript and generated pressed connections, native highlighting and fail-closed compile-before-Play without external tools. R01 is merged research; lowercase Gogo-only `@bindable` is accepted but not implemented. The old namespaced XML/JSON demo remains legacy.

C01 gate infrastructure and scoped helper fix #67 are merged; **strict release remains BLOCKED**. Normal development success is not publishing authorization. Retain raw-syntax, cold-scene, #65 export cleanup, standalone executable/platform and other required release boundaries under #51. Historical nine-engine findings are archival; live verification uses only 4.0.4 and pinned 4.7.0.

## Architecture and native proof — planned

[ADR-0015 / #68](DECISIONS.md#adr-0015--ggx-node-native-composition-and-layout-first-estragon) replaces the old independent-tree/no-Node/self-render-everything future direction. Gogo is the language; GGX is general-purpose Node composition. Estragon focuses on layout-first 2D UI and analogous 3D components, with Godot retaining native services.

1. **ADR-0015-A #69:** docs-only formalization merged in PR #70.
2. **B1 #71:** [bounded opt-in proof/example](NODE_COMPOSITION_PROOF.md) merged in PR #72: native composition, typed values/named signals, transforms, lifecycle and scene/editor persistence; default compiler/runtime unchanged.
3. **B2 #73:** [shared spatial entry/row-layout proof](NODE_LAYOUT_PROOF.md) submitted for review, with proposed bounded units/authority, retained identity and event-driven reflow. B3 remains unstarted.
4. **B3:** Native2D/Native3D adapter bounds/authority, optional measurement, branch-local invalidation and feedback prevention.

Exit: the complete minimal native proof is reviewed with actual automated runtime/editor and native graphics evidence where relevant. Partial proof is not migration. [NODE_MIGRATION_PLAN](NODE_MIGRATION_PLAN.md) defines per-PR acceptance, dependencies and open decisions. No successor is started by #69.

## Core migration — queued behind proof

Separate reviewable slices introduce native component/lifecycle foundations, general GGX compiler rules, minimal component/example parity and eventual RefCounted retirement. Use only inherited Node.add_child for hierarchy elements. Ordinary Nodes do not tunnel Estragon layout; explicit entries and native adapters define participation. Do not rename superclasses mechanically or remove existing examples before proved replacements.

Resolve 3D units/axes/wrapping/overflow and coordinate/overlay policies in focused specifications. Native drawing remains component-specific; R02 universal-renderer research stays deferred rather than a mandatory milestone. T10 legacy JSON retirement needs consumer audit and equivalent working replacement.

## Reactivity and useful components — still planned

T09 preserves lowercase Gogo-only annotations, typed non-Node models, scoped nested subscriptions, observable collection/item events, retained keyed Nodes and eventual two-way/cycle hardening. Rebase its Node lifecycle/layout dependencies before pickup; compatibility blockers remain. L01 pixel padding/margin maps onto the composed 2D core after proof; #54 conversion helpers remain deferred and do not define 3D units.

Broader text/fonts/localization, styles/images/clipping, keyboard/focus/IME/touch/scroll and accessibility require their own scoped contracts and demos. Native metadata completion/navigation, preview and debugger mapping follow proven compiler/editor interfaces. No full Flex, TSX or React compatibility is promised.

A feature requires documented supported behavior, meaningful layer-specific automated tests, native graphics evidence where relevant, a working example, exact compatibility limitations and owner review. One open PR total, no automatic merge and no physical keypress acceptance gate.
