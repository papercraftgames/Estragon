**Current C4 #83:** C3 PR #82 merged at ef1d713. C4 is the active review work package: retire all old production classes/shims/paths/tests and stage-0/T10 consumers, promote canonical native widgets, use native Counter main scene, and replace legacy/standalone-app release requirements with current-addon checks. See the [completed removal mapping](NODE_UI.md#c4-removal-inventory), current [language](GOGO_LANGUAGE.md) and [test/release policy](TESTING.md). Historical proof acceptance and old blockers below preserve earlier scope/results; #83 owner decisions supersede requirements to retain old examples/compatibility or always report BLOCKED because of discontinued functionality. A current native failure still blocks. Do not start successors or merge automatically.

# ADR-0015 staged Node-native migration

**Staged plan:** ADR-0015-A merged in PR #70; B1 #71 merged in PR #72 with its bounded [composition proof](NODE_COMPOSITION_PROOF.md). [B2 #73](https://github.com/resistdesign/Estragon/issues/73) merged in PR #74 with the [shared spatial layout proof](NODE_LAYOUT_PROOF.md). [B3 #75](https://github.com/resistdesign/Estragon/issues/75) merged in PR #76 (`457f6b9`) with the [native adapter/metadata proof](NODE_ADAPTER_PROOF.md). [C1 #77](https://github.com/resistdesign/Estragon/issues/77) merged in PR #78 (`fd90c5e`) with the [working native runtime foundation](NODE_RUNTIME.md). [C2 #79](https://github.com/resistdesign/Estragon/issues/79) merged in PR #80 (`d023d9d`) with [normal Gogo-native GGX compilation](NODE_GGX.md). [C3 #81](https://github.com/resistdesign/Estragon/issues/81) supplies the [native 2D slice and Counter](NODE_UI.md); C4 remains queued until its review/merge. [ADR-0015](DECISIONS.md#adr-0015--ggx-node-native-composition-and-layout-first-estragon), owner [#68](https://github.com/resistdesign/Estragon/issues/68), formalization [#69](https://github.com/resistdesign/Estragon/issues/69). This is the successor work breakdown incorporated by [EXECUTION_PLAN](EXECUTION_PLAN.md). IDs below identify narrow proposed tasks, not shipped features or newly claimed assignments. Create/reuse a scoped GitHub issue on pickup and link its plan before code. Each arrow means predecessor reviewed and merged, not merely drafted. One open PR total; never auto-merge.

## Sequence and gates

`ADR-0015-A (#69) → B1 composition proof → B2 shared layout proof → B3 native adapter proof → C1 runtime foundation → C2 compiler migration → C3 components/examples → C4 legacy retirement`

B1–B3 together satisfy the minimal native proof; do not call a partial proof the migrated framework. Keep proof fixtures isolated and retain existing paths during C3 only as necessary migration regressions. Owner #81 requires C4 to remove replaced production classes, shims, obsolete paths and tests; preserve historical evidence, not a permanent dual API. B1 may add a narrowly bounded native compiler proof path only with explicit selection and no pragma/child-protocol mechanism; it must not prematurely replace existing built-in semantics. C2 is the general compiler migration after the complete proof. No broad runtime/component migration before B3 is accepted.

C01 #41/#51 remains the release gate for both existing and migrated products. Owner #68/#69 authorizes this planning/proof sequence before the broader migration; it does **not** resolve current release failures. Before any successor starts, its scoped issue must record which current failures are relevant and whether they block that proof. If a failure prevents meaningful proof, stop with evidence for owner disposition; do not waive it or expand the PR into C01 repair. Unrelated C01 repair proceeds only as a separately selected serial task, never a second PR.

## Proof tasks — each one reviewable PR

### ADR-0015-B1 — GGX native composition, signals and persistence

**Tracking:** [#71](https://github.com/resistdesign/Estragon/issues/71); [bounded implementation/evidence](NODE_COMPOSITION_PROOF.md). Merged PR #72; scope remains bounded.

**Prerequisite:** #69 merged; current main/open PRs/handoffs checked. **Layers:** isolated native compiler/type-resolution proof, fixtures, native tests and source maps. No new layout library or component migration.

- Prove authored GGX creates nested ordinary/custom Node2D and Node3D subtrees using inherited void-returning Node.add_child. No custom adder, pragma, Error-result check or runtime markup interpreter. Verify typed property assignments and exactly-once authored evaluation order.
- Connect a named native signal handler on an ordinary Node and verify it fires once. Also prove a referenced non-Node Object can supply a signal and resources can be property values. No inline anonymous handler declarations.
- Reject non-Node hierarchy children, unknown/invalid props/signals and invalid handler types with original-source diagnostics/native semantic failures. Preserve deterministic code/maps and existing T04–T07 cases.
- Record and test parentage versus owner policy: owner-valid PackedScene pack/save/reload retains intended nodes, properties and connections without accidental ownership of external nodes. Verify native freeing, reparenting and connection cleanup; do not copy remove-to-dispose semantics.
- Show expected Node2D/Node3D transform inheritance and a plain-Node boundary explicitly; do not assume cross-dimensional transforms. No 2D overlay feature is implied.

**Acceptance:** automated actual runtime values, tree types/order, connection counts, instance IDs before/after native moves, cleanup and saved/reloaded scene assertions on 4.0.4/4.7.0; isolated editor persistence test; fresh Godot-only compile/validation with tools absent. Attach exact commands/logs/provenance and relevant negative outcomes. Native graphics evidence is separate when the fixture presents visuals. Existing release verdict remains unchanged.

### ADR-0015-B2 — Explicit entries and composed measure/arrange

**Tracking:** [#73](https://github.com/resistdesign/Estragon/issues/73); [bounded proof contract and evidence](NODE_LAYOUT_PROOF.md). Proposed X-row/local-space/authority defaults were recorded before code; B2 merged in PR #74.

**Prerequisite:** B1 merged; reviewed bounded coordinate/authority contract in the task issue. **Layers:** pure mathematical layout core plus minimal Node2D/Node3D entry/participant proof; no broader widgets, bindings or wrapping engine.

- Choose proof entry names (working Estragon2D/Estragon3D), local coordinate inputs and output sizes. One common mathematical measure → arrange algorithm via composition drives both spatial branches; no shared plain Node visual superclass.
- Demonstrate simple 2D and 3D layout with width/height/depth, using a documented temporary 3D unit policy limited to the proof. Do not settle volumetric wrapping by accident.
- Ordinary Nodes are allowed children but excluded from automatic layout. A nested explicit entry re-enters Estragon; demonstrate that sizing does not tunnel across the boundary.
- Change a layout property and viewport size; only affected branches remeasure/arrange, updates coalesce and unaffected measurements stay cached. Retain Node instance IDs and signal subscriptions. No full-tree reconstruction, virtual DOM or `_process` polling.

**Acceptance:** pure layout input/output tests plus native SceneTree/transform tests on the two approved engines. Counters prove no idle layout work, one coalesced scheduled reflow, unaffected-branch cache retention and stable identity. Include native graphics captures of both dimensions, resize and entry boundaries; headless results alone are not graphics proof. Check relevant window/DPI capability separately without assuming viewport resize. Keep full 3D wrapping/units design deferred.

### ADR-0015-B3 — Native2D/Native3D bounds and authority

**Tracking:** [#75](https://github.com/resistdesign/Estragon/issues/75), [bounded contract/evidence](NODE_ADAPTER_PROOF.md). B2 PR #74 merged at `5921e96`; B3 merged in PR #76 before C1 pickup.

**Prerequisite:** B2 merged; reviewed bounds-provider, transform-write and ownership rules. **Layers:** two minimal adapters, native examples and native tests; not a universal measurement framework.

- Place one native visual child through each working Native2D/Native3D adapter. Show explicit controllable size/position and one appropriate optional native bounds provider per dimension (e.g. rect/geometry or mesh AABB). Generic Nodes never acquire magical size.
- Specify layout-controlled versus native-controlled axes/size/position, local bounds origins, transformed bounds and parent space. Native rendering/physics behavior remains Godot's.
- Demonstrate explicit/native-signal invalidation, cached bounds, branch-local reflow and batching; distinguish external native updates from Estragon writes. Assert bounded notification/reflow counts and no feedback cycle. Animated geometry may use fixed/deferred snapshots or explicit opt-in observation; no compulsory polling.
- Prove reparent/free/subscription cleanup, stable identity after reflow, and editor save/reload ownership and transforms for both adapters.

**Acceptance:** both-engine positive/negative runtime, bounds/authority/loop-count assertions, isolated editor persistence and visual captures. Record the complete B1–B3 proof checklist and remaining limitations before authorizing C1. No global observer or full-tree transform cascade.

## Migration after the complete proof

**C1 tracking:** [#77](https://github.com/resistdesign/Estragon/issues/77), [runtime API/contract](NODE_RUNTIME.md), runnable `examples/node_runtime/TwoD.tscn` and `ThreeD.tscn`. Public entry/participant/native adapter code is separate from the experimental proof fixtures; shared internals are reused, not copied by dimension. C1 merged in PR #78 before C2 pickup. C2 uses the existing compiler/editor transaction, explicit supported type imports and preserved legacy tree rules; see its linked contract.

| Task / one PR | Prerequisites and scope | Measurable acceptance / non-goals |
| --- | --- | --- |
| **ADR-0015-C1 runtime foundation** | B3; reviewed lifecycle/coordinate contract. Introduce Node2D/Node3D component participants, entry ownership and composed core alongside old runtime. | Native add/remove/reparent/free and signal lifetime tests, stable IDs, transforms and serialization on both approved engines; existing examples stay functional. No wholesale superclass rename or forced legacy retirement. |
| **ADR-0015-C2 general GGX compiler** ([#79](https://github.com/resistdesign/Estragon/issues/79), [contract/evidence](NODE_GGX.md)) | C1 and B1 lessons; explicitly specify type/import resolution and legacy syntax transition. Generalize native properties/signals and Node-only child generation; preserve editor transactions/maps. | Positive ordinary/custom Node and Object-signal cases, non-Node child/type/handler failures, deterministic source-ordered emission, actual-path rollback/cache identity and isolated Godot-only editor Play/recovery. Explicitly review handling of historical inline lambda attributes and old leaf rules rather than silently rejecting shipped syntax. No pragmas, child-adder registries or external compiler. Split resolution from emission if it cannot fit one PR. |
| **ADR-0015-C3 minimal components/examples** | C2; port only the current 2D Rect/Text/Button and simple HBox/VBox slice to native visuals/composed layout. | Counter interaction, native signals, resize, identity, layout and graphics parity; preserve published old results and mark newly measured outcomes. Full widgets, focus and advanced styling remain separate. Split components and example cutover into serial PRs if needed. |
| **ADR-0015-C4 RefCounted retirement** | C3 merged and all active old consumers inventoried/replaced with proved equivalents. | No consumer relies on private-child/Error-add/dispose semantics; remove obsolete runtime only after source/example/editor/lifecycle regression proof. Keep archival evidence truthful. Execute the [C4 removal inventory](NODE_UI.md#c4-removal-inventory), including obsolete compiler paths/shims/tests and stage-0 consumers; coordinate T10 JSON retirement explicitly. No permanent dual API. |

Each implementation issue chooses exact focused test commands from existing harnesses plus native tests added by that task. Run targeted checks during development and one relevant acceptance pass on **official 4.0.4 + pinned 4.7.0 on Linux only (owner #81)**. TypeScript/Yarn for new contributor orchestration, native GDScript fixtures, no Python. Do not launch all-minor suites, require physical keypresses or label untested platforms PASS. Native visual evidence and automated isolated editor/game tests remain distinct requirements where relevant.

## C01, T09 and L01 dependencies retained

- **C01 #41/#51:** PR #66 gate infrastructure and PR #67 scoped helper fix are merged. #61 is closed completed for that scope, not full raw-string grammar/release acceptance. Raw-syntax/hybrid runtime findings, cold 4.0.4 missing-generated scene restoration, [#65 export cleanup](https://github.com/resistdesign/Estragon/issues/65), standalone executable/platform disposition and other strict required stages remain under #51. E01-F's hidden-tab exception remains observed FAIL with accepted scope, never PASS. No architecture task changes gate fingerprints, evidence or publishing authorization. Require strict matching-source/engine release PASS before certification, even if development CI is green.
- **T09-A #43 / umbrella #5:** merged in PR #85 (`b13ffe0`) after C4. **T09-B #86** implements bounded explicit GGX dependencies on the native lifecycle/layout core; see [contract](REACTIVE_GGX.md) and live issue/sole PR. T09-C collections/repeaters and T09-D two-way/feedback hardening remain queued. Position bindings explicitly defer to #88; static native placement remains supported. No old Box refactor is a prerequisite.
- **L01 #55:** pixel padding/margin box-model work stays queued and needs a reviewed mapping onto the composed 2D core after B3/C1. Preserve its prior acceptance intent; do not silently ship or obsolete it. [#54 pixel helpers](https://github.com/resistdesign/Estragon/issues/54) remain deferred until geometry dependencies and normal bindings are defined. Neither determines 3D world units.
- **T10:** legacy JSON retirement needs proved replacement parity and current consumer audit. Serialize it with C4 as appropriate; do not delete working examples in a proof PR. **R02** standalone renderer research stays deferred; no mandatory competing-renderer milestone.

## Open specifications and decision owners

The owner/reviewer must approve a bounded specification in the relevant task issue before implementation relies on it. Approval of this architecture is not approval of every detail below.

| Question | Decision/proof boundary |
| --- | --- |
| Coordinates and overlays | B2 specifies entry/local/native spaces, plain-Node boundaries and conversion authority. An eventual 2D overlay in 3D needs its own supported integration contract. |
| 3D units, constraints and wrapping | B2 records a limited proof policy. A later focused spec must choose axes, row/column/layer order, spacing, world units, width/height/depth constraints and overflow before volumetric boxes. No pixel-to-world assumption. |
| Adapter measurement | B3 chooses providers, bounds origin/transform handling, invalidation and fixed/deferred animated snapshots. No universal Node size or compulsory observation. |
| Transform/size authority | B2/B3 define layout/native-controlled fields, external versus self writes, batching and feedback termination; no transform-event cascade. |
| Scene ownership | B1 then C1 specifies runtime versus persisted owner, detached/borrowed nodes, reparent/free and signal cleanup. Parentage alone never promises PackedScene persistence. |
| Resolution and syntax migration | B1 uses a bounded explicit type set; C2 specifies imports/custom types/native metadata and transition from current factories/events. Named handlers/Callable references are target; existing lambda behavior is preserved until a reviewed migration. |
| Theme, DPI and reactivity | T09 specifies observable theme/model geometry dependencies and lifecycle; entry work distinguishes viewport resize from relevant window scaling signals. No new global layout poll. |

At every handoff record merged prerequisites, active branch/SHA/base, actual evidence/untested items, remaining acceptance and the next exact action. Architecture approval does not authorize automatic merging or starting another task within #69.
