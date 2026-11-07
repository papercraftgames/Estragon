**F04 single-runtime cutover:** [Current contract, removal inventory and parity](F04_CUTOVER.md), [#98](https://github.com/resistdesign/Estragon/issues/98). Every GGX expression now builds Element descriptions, including ordinary helpers/lambdas. Eager factories and per-target binding helpers are removed. F01–F03 are merged; live issue/sole PR records F04 verification/review. F05/F06 remain future. Earlier stage text below records that stage’s original scope.

# Current native-addon verification

> **ADR-0016 verification:** current-addon groups cover F01–F03 getter/description/conditional/keyed reconciliation. F04 retargets compiler/GGX/UI/model consumers to the same engine and audits replaced eager/binder removal without dropping strict groups. F05/F06 remain future and are not certified by these checks. Exact current source/engine evidence lives in #98/PR #99.


Only official **4.0.4** and pinned **4.7.0**, on Linux in CI. No other-version/platform sweep, Python, physical keypress gate or standalone-application export requirement. Run focused checks while developing, then one relevant two-engine acceptance. Historical nine-engine/macOS/C01/B1–C3 reports remain truthful archives, not rerun instructions or perpetual blockers.

Normal addon authoring needs only Godot. Contributor runners are TypeScript; new orchestration uses Yarn/Node. Existing Bun manifest/typechecking remains optional developer tooling (no compiler implementation or end-user dependency).

~~~sh
bun install --frozen-lockfile
bun run check
~~~

CI01 [routine budget / release certification](CI_PERFORMANCE.md): routine PR and main push checks are limited to static/policy tests and one tiny headless native smoke, within60seconds. Docs-only omits Godot. Full73-stage acceptance on BOTH approved engines is mandatory before publication, through certify.yml and independent exact-current-run artifact verification. Fast main CI cannot authorize publication. The commands below are explicit certification/development tools, not routine CI.

~~~sh
# From a contributor environment; output directory must be new and absolute.
xvfb-run -a corepack yarn@1.22.22 node --experimental-strip-types tools/check-native-addon.ts \
  --engine 4.0.4=/absolute/verified/linux/godot \
  --engine 4.7=/absolute/verified/linux/godot --output /tmp/new-addon-acceptance
~~~

Use the workflow's LIBGL_ALWAYS_SOFTWARE=1, verified lavapipe VK_DRIVER_FILES/VK_ICD_FILENAMES and isolated XDG_RUNTIME_DIR. Xvfb supplies X11, not Vulkan; the workflow verifies the software ICD rather than hiding Vulkan initialization errors. tests/compatibility/linux-engines.json pins official archive/executable hashes and versions; the downloader additionally authenticates 4.0.4 against its official SHA-512 manifest. Engine copies and editor settings are isolated and native child PATH has no external tools.

Required coverage:

- Native compiler lexical composition, deterministic code/maps, ordinary lambda factories, code-only models, Node-only/type/child/signal negative diagnostics and actual-path publication/dependency/cache/rollback/fresh failure.
- Shared mathematical layout plus native 2D/3D bounds, identity, reparent/free, subscriptions, branch invalidation, batching, native owner packing and real-editor reopen.
- Gogo-authored 2D/3D runtime/signals/type failures and normal editor source-map/save/unsaved main/current Play failure/repair.
- Native Counter geometry/input/resize/cache/identity, native highlighter and real editor Play; real graphics captures for UI and dimensional demos, visually inspected separately from headless assertions.
- Canonical UID pairing/uniqueness and clean import stability, including measured first-import asset defaults on 4.0.4. Research/evidence-only roots are Godot-ignored; there is no known-Logger-error exception in current product import.
- Cache-free fresh addon installation and native scene execution without contributor tooling; remove generated outputs and .godot, rebuild via bundled native API and execute current source; create/load a native resource pack in a separate bare process. Native addon code is the tested artifact, not a standalone application executable.

## Release policy

The runner hashes execution logs/results/provenance and assembles addon-evidence.json. tools/assert-release.ts requires every current stage PASS, clean matching source, exact approved engine identity, hashed execution reports/logs and summary/report agreement. Missing, dirty, mismatched, forged or unexpected-failure evidence fails closed. There are no automatic legacy development exceptions; development-policy.ts uses the same requirement policy. Policy tests exercise these negative paths. Each artifact assesses one approved engine; actual two-engine release review requires both matching candidate-source reports:

~~~sh
corepack yarn@1.22.22 node --experimental-strip-types tools/assert-release.ts \
  /evidence/4.0.4/addon-evidence.json /evidence/4.7/addon-evidence.json
~~~

Standalone executable export, the deleted surface/JSON scenes, RefCounted helpers/callbacks and obsolete raw-string fixtures are no longer product requirements (#83). Their archived FAIL/BLOCKED/UNTESTED outcomes remain unchanged. Any genuine current native-product failure remains a blocker until fixed or explicitly scoped by owner decision; do not suppress native errors or label them PASS. Green checks do not authorize automatic publishing/merging or certify untested minor/platform support. No publisher exists.

Current C4 issue/PR records exact source/engine provenance, commands, actual outcomes and captures. [C3 archival evidence](../tests/compatibility/c3/README.md) records the prior native slice under transitional paths; it is not fresh C4 evidence.

## Native addon pack format / Godot 4.0 exporter bridge

The sample project explicitly sets `editor/export/convert_text_resources_to_binary=false`. The pack retains native textual scenes/resources (and generated GDScript), then tests them from a separate bare process. In official Godot 4.0.4, `_export_customize` instantiates scene roots for binary conversion without freeing them; verbose output identifies leaked Counter/2D/3D roots, GDScript/SceneState resources and a canvas RID. The [official 4.0.4 source](https://github.com/godotengine/godot/blob/4.0.4-stable/editor/export/editor_export_platform.cpp#L742) shows that path; the early-return supported text-resource path avoids it. This is a small project export-setting bridge, not an engine patch or error exemption. Consumers exporting with 4.0.4 should retain this setting for Estragon scenes until their own export/cleanup evidence supports another format. Both approved engines verify actual editor pack export and runtime with this explicit format. Binary-conversion export is not claimed fixed or certified; its original #65 failure remains archival evidence.

## T09-A observable-property acceptance

`tools/check-bindable.ts` runs normal Godot-only builds/import, typed code-only base/derived models, ordinary/internal/external/compound/reentrant writes, initialization/equality/reference behavior, actual callbacks/disconnect/free, lexical annotation/declaration negatives and mapped semantic failures. A real isolated editor exercises saved/unsaved main/current Play, current model execution, invalid annotations/types, unsavable source, output/map/UID/timestamp/cache rollback and repair. It is a required group in the strict native-addon evidence gate. Normal Counter/native runtime/GGX/graphics/metadata/fresh/cold/pack checks remain required.

Focused Linux development: workflow mode `bindable`, one approved selected engine, or `corepack yarn@1.22.22 node --experimental-strip-types tools/check-bindable.ts --engine 4.7=/absolute/official/linux/godot --output /tmp/new-bindable-check`. Final normal acceptance runs both approved Linux engines only. The data demo needs no graphics to prove observability; existing native visual demos retain real captures. Exact outcomes/provenance and manual-graphics limitations live on #43 and its sole PR. See [contract/demo](BINDABLE_PROPERTIES.md).

## T09-B reactive property/layout acceptance

`tools/check-reactive.ts` runs native build/import, retained UI/runtime/geometry/cache/batching/lifetime/PackedScene and source-map tests, real saved/unsaved main/current editor failure/rollback/repair, and graphics-backed initial/changed/resized captures. It is required by the strict addon gate. Focused workflow mode `reactive` selects one approved Linux engine. Final acceptance uses official 4.0.4 and pinned 4.7.0 only; exact source/engine hashes, commands, logs and actual outcomes live on #86/its sole PR. Manual interactive smoke status is reported separately from automated editor/rendering proof. See [bounded contract](REACTIVE_GGX.md).

## F01 native function composition proof

`tools/check-composition.ts` is the strict addon group for native getter scopes, typed source descriptions, coalesced observing-component reruns, retained IDs/desired snapshots/handlers, lifetime/foreign children, real editor saved/unsaved main/current rejection/rollback/repair and rendered Counter evidence. Workflow mode `composition` is focused development; full acceptance uses only official Linux 4.0.4 and pinned 4.7.0. Fresh/cold native addon/pack tests include the F01 Counter. Exact commands/provenance/results and manual-smoke status live in #92/its sole PR. See [bounded contract](F01_COMPOSITION.md); F02–F04 cutover remains unimplemented.

## F02 conditional/nested composition

`tools/check-conditional.ts` / workflow mode `conditional` tests single Element/null conditional child results, nested scopes/parent-first cancellation, stable slot IDs, real native writes/layout/lifetime/foreign boundaries, compiler/type/map negatives, real saved/unsaved main/current editor rollback/recovery, and rendered initial/changed/resized captures. It is part of the strict addon and cold/pack acceptance on official Linux 4.0.4 and pinned 4.7.0 only. Exact outcomes/provenance and manual smoke status live on #94/its sole PR; see [contract](F02_CONDITIONALS.md). No F03 keys/lists or F04 cutover claim.

## F03 native mapped/keyed lists

`tools/check-lists.ts` / focused workflow mode `lists` covers loop/map/native Array child sequences, key diagnostics, actual native IDs/state/operation counts, nested model observers, atomic rejection/repair, real editor main/current Play and four rendered inventory captures. It is required by the strict addon and cold/pack gates. Only official Linux 4.0.4 and pinned 4.7.0; exact evidence and manual-smoke status in #96/its sole PR. See [contract](F03_LISTS.md). F04–F06 remain future work.

## F04 cutover acceptance

Focused workflow mode `cutover` runs existing compiler/GGX/native-UI/model groups on one approved Linux engine. Final strict evidence still requires every prior stage, including bindables, nested conditionals/keyed lists, saved/unsaved editor failure/repair, fresh/source-only cold build and bare exported pack execution. Source audit rejects removed compiler/runtime/binder paths and generated readers/attachments. See [removal/parity report](F04_CUTOVER.md) and live #98/its sole PR for exact commands, hashes, captures, outcomes and manual-smoke status. F05/F06 are not included.

## F05-A class-wide annotation

The existing strict bindable group now proves class-scope grammar, idempotent explicit/class markers, generated signals/equality/initialization/reentrancy/lifetime, native exports/maps, scope exclusions, mixed inheritance and class annotation editor rollback/repair. Existing conditional/keyed proofs use class-wide host/model/row declarations and retain IDs/state/subscription boundaries, including an unread class-wide host field. No observer runtime or extra strict group is added. Final acceptance remains only official Linux 4.0.4 + pinned 4.7.0 with existing fresh/cold/source-only/pack/graphics regressions. Exact results and manual-smoke status live in #90/its sole PR; F05-B is excluded.

## F05-B controlled boolean acceptance

`tools/check-twoway.ts` / workflow mode `twoway` adds build/import/runtime/editor/visual evidence to the existing strict gate. Native pointer, one model transition, quiet projection, reentrancy, replacement/stale callbacks, nested/keyed retained controls, lifecycle/foreign owner/pack reload, deterministic maps and compiler rejects are scoped in [the contract](TWO_WAY_BINDINGS.md). Real saved/unsaved main/current Play and unsavable/invalid rollback/repair remain mandatory. Native distribution cold source-only/editor/pack runtime includes the new Gogo demo. Only official Linux 4.0.4 + pinned 4.7.0; exact results and manual smoke status in #101/its sole PR. F06 is excluded.

## F06 native profiling/invariants

`tools/check-profiling.ts` / focused workflow mode `profiling` adds build/import/runtime evidence to the strict addon gate without removing any prior group. Two warmups and seven samples use current Gogo HUD/conditional/inventory/2D/3D/toggle scenes; keyed sizes 8/64/128. Idle/selectivity/identity/minimal native moves/layout caches/lifetime are deterministic assertions, while timings and approximate process memory are descriptive. [Boundaries, exact workloads and evidence](F06_PROFILING.md). Strict final acceptance remains only official Linux 4.0.4 and pinned 4.7.0. Raw samples, source/engine/log hashes, failures/repairs and manual-smoke status live in #103/its sole PR. No physical keypress gate or broad UI completion claim.

## P01 package consumer

`tools/check-package.ts` / focused workflow mode `package` adds pack/install/build/import/runtime/editor/visual evidence to all prior native-addon groups. The curated local npm tarball is dry-run audited, reproducibly packed twice, unpack-hashed, installed with Yarn in a fresh consumer, used directly in node_modules without copy/symlink/ignore, with separate nonstandard relocation and standard-path consumers per [install contract](PACKAGING.md), then exercised by native compiler/real saved+unsaved main/current editor Play, invalid/unsavable rollback+repair, actual pointer input and rendered Counter initial/changed/resize captures. No repository generated scripts or Assets enter that consumer; test harness files are not package contents. Official Linux 4.0.4/pinned4.7 only. npm pack is a local publishing-tool operation, never publication; manual release workflow is preview by default and requires separate owner setup/authorization. All 11 live scene paths are included in distribution cold/pack acceptance; no prior stage removed.
