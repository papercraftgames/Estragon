# AGENTS.md — Working on Estragon

> Repository-wide instructions for AI coding agents and automated contributors. Read this before editing code or opening a PR. These instructions distinguish the **current repository** from owner-approved future architecture; target approval is not implementation evidence.

## Standing authorization: local repository cleanup

The repository owner explicitly authorizes resetting the local Estragon checkout
and clearing its Git stash whenever necessary. Changes caused by opening or
testing the project in Godot are disposable, including generated indentation
edits. Agents may use `git reset --hard`, `git clean -fd`, `git stash clear` and
synchronize with `origin/main` without requesting permission or preserving those
Godot-only changes in a stash. The previously preserved indentation stash may
be discarded.

Inspect status and history first to distinguish editor artifacts from unfinished
implementation work. This authorization applies only to the local Estragon
checkout: **do not destroy unfinished Codex implementation work, committed work
on remote branches, or anything in unrelated repositories.** It does not authorize
force-pushing, remote branch deletion or merging PRs.

## Mission and accepted architecture (ADR-0015)

**Estragon provides Flex-inspired, layout-first 2D UI components and extends the same model to 3D.** Its intended UI suite replaces Godot Control UI for its uses. Godot supplies the SceneTree, Node lifetime, transforms, rendering, physics and platform/window events. Estragon is not a competing renderer or virtual DOM.

**Gogo** is the GDScript-like language in `.gogo`; **GGX** is its general-purpose embedded XML-like **Node composition syntax**, not just Estragon markup. Compile to typed native GDScript using the bundled Godot-only compiler, source maps and fail-closed validation. Read [ADR-0015](docs/DECISIONS.md#adr-0015--ggx-node-native-composition-and-layout-first-estragon) and [the staged migration plan](docs/NODE_MIGRATION_PLAN.md), derived from [owner architecture #68](https://github.com/resistdesign/Estragon/issues/68).

**Present implementation is different:** `EstragonDisplayObject extends RefCounted`, containers own private child lists, and `EstragonSurface extends Node` draws through a RenderingServer canvas item. T04–T07 compile five Estragon built-ins; N01–N03 provide the native compiler/editor. Basic text/buttons and pointer input work. Separate experimental [B1 composition](docs/NODE_COMPOSITION_PROOF.md) and [B2 composed 2D/3D layout](docs/NODE_LAYOUT_PROOF.md) proofs work through explicitly selected APIs. General Node-native compiler/component migration, B3 native layout adapters, bindable properties and repeaters remain **not implemented**. Preserve existing examples/evidence during reviewed migration. The namespaced XML/JSON demo remains stage-0 legacy.

## Target authoring and runtime contract (planned, not shipped)

- No mandatory namespaces, JSX/GGX pragmas or configurable/type-specific child-adder protocols. Every GGX tree item must derive from Godot `Node`; the **only attachment API is inherited `Node.add_child(Node)`**, which returns void. Do not retain the old Error-returning EstragonContainer convention for Node code. Non-Node resources/models/Objects belong in property/expression values, never tree children.
- Typed native properties and native signal connections apply to ordinary Nodes too. Any referenced Godot Object may be a signal source. GGX event attributes refer to named handlers/Callable values; do not introduce inline anonymous function declarations there. Ordinary functions may contain GGX; function-valued children are not required. Preserve historical callback support until a reviewed migration explicitly replaces it.
- Visual 2D components derive from Node2D; 3D participants derive from Node3D. Share mathematical measure/arrange through **composition**, not a plain Node visual base or multiple inheritance. Working entry-point names are Estragon2D/Estragon3D; exact names remain open.
- An ordinary Node may appear anywhere in GGX but does not automatically participate in layout. Re-enter layout below it using another explicit 2D/3D entry point. Specify spatial/coordinate boundaries and 2D overlays explicitly; arbitrary Node ancestry may interrupt transforms.
- Native2D/Native3D adapters (working names) expose explicit bounds/position, with optional suitable native measurement. Generic Nodes have no universal size. Specify layout/native authority, cached measurements, affected-branch invalidation, batching and transform-write feedback guards. Animated geometry uses explicit opt-in observation or fixed/deferred snapshots, never compulsory per-frame polling.
- Retain Node identity and subscriptions across layout; use event-driven measure → arrange, not full-tree rebuilding or virtual DOM. Native signals, child changes, bindable/collection changes, explicit invalidation and viewport resize are inputs; consider Window DPI changes only where relevant. Observable theme data drives theme updates.
- Lowercase `@bindable` remains **Gogo-only**, including code-only non-Node models; no ordinary `.gd` annotations or `.bgd`. Collections/repeaters use retained keyed Nodes and incremental updates. 2D pixel units remain; 3D units/axes/wrapping/overflow require a focused specification.
- Native lifetime, reparenting, signal cleanup and PackedScene `owner` persistence require explicit proofs. Never mechanically rename RefCounted superclasses or assume current disposal rules equal Node removal/freeing.

## Highest priority: native Godot Gogo compiler and editor (N01–N03 implemented)

**Owner decision, 2026-10-28, ADR-0012:** Estragon users must compile and run Gogo with **Godot and the bundled addon alone**. No Bun, Node.js, TypeScript, external compiler processes, shell setup, separate language server or GDExtension binary may be required for normal editing or Play. The former T08 Bun bridge has been replaced by direct native compilation/validation in N03.

**N01/N02/N03, R01 #38 and the narrow E01 #40 fix are merged.** R01's unsupported ordinary-`.gd` requirement is superseded by ADR-0013. The C01 compatibility and release track is defined by [the measured evidence](docs/C01_COMPATIBILITY.md), [current work status](docs/WORK_STATUS.md) and **live scoped GitHub issues**, not stale task assignments in this standing file. The E01-F hidden-tab exception is an [accepted decision](docs/DECISIONS.md) rather than a corrected hidden-tab test. Follow the current task issue and one-PR handoff procedure. The native compiler/editor must stay independent of Bun/Node.

- **N01:** GDScript-native lexer/parser/typed component and event validation, original source spans and diagnostics, with native Godot tests. Never implement mixed syntax with regex substitutions.
- **N02:** GDScript-native emitter, source maps, full current Gogo semantic parity and an interactive native-generated Counter; use Bun/TypeScript only for optional reference checks.
- **N03:** Replace editor Bun subprocess and executable setting with direct bundled native compilation/validation, preserving highlighting, saved/unsaved edits, F5/F6 fail-closed checks, diagnostics and recovery. Prove use in a fresh Godot project **without Bun installed or available**.

Preserve the native editor workflow; never reintroduce a Bun fallback. The native compiler may use Godot core string/array/value APIs but **must not depend on EditorInterface, rendering, or a running scene tree**; keep parsing, typed model, codegen and source maps separate. Preserve supported Gogo syntax, callback order and automatic lifecycle. No runtime XML/JSON interpreter; GGX targets Node composition under ADR-0015. Existing TypeScript/Bun scripts/tests may remain as **optional developer/CI tools**, never as the app's required build process or fallback.

Do not modify the accepted architecture or silently reduce Gogo's language features to simplify the port. Checkpoint progress in issues/PRs, run Godot-only positive/negative tests, and leave durable session handoffs.

## Minimum supported Godot: 4.0+ (owner decision, 2026-10-29)

**Accepted product requirement:** The end-user Estragon addon, editor workflow, native Gogo compiler/codegen/validator, generated GDScript, runtime/layout/renderer and sample projects must work on **Godot 4.0 and every subsequent Godot 4.x minor**. The existing **4.7-only tests do not certify this**, and the current code is **not yet verified 4.0-compatible**. Track the compatibility audit and version matrix in [C01 #41](https://github.com/resistdesign/Estragon/issues/41); treat it as a baseline before claiming T09/Estragon cross-version support. The owner has not approved raising the minimum engine version.

- **Audit before extending:** `ScriptEditor.save_all_scripts()`, `ScriptEditor.get_unsaved_files()` and `Resource.set_path_cache()` are used today but absent from the published 4.0 public APIs. The 4.7 syntax-highlighter association also uses an undocumented `_get_edited_resource()` plus native editor ItemList path/metadata. None may be assumed to function on 4.0 without equivalent tested compatibility behavior.
- Prefer documented, stable Godot **4.0** public APIs. Isolate any indispensable version-specific editor adapter behind tested capability/version checks rather than depending on fixed UI hierarchy. Never silently sacrifice correctness, unsaved-buffer fail-closed F5/F6, script identity, cached resources, or syntax highlighting on older versions.
- **Prove on the two approved engines only:** official Godot **4.0.4** (oldest supported) and pinned **4.7.0** (current baseline). Never schedule all-minor/nine-engine local or CI matrices. Keep native negative diagnostics and no-Bun workflow; manual graphics evidence stays separate. Audit feature declarations and generated formats against the 4.0 minimum.
- E01's normal highlighter behavior and the accepted narrow hidden-tab limitation have separate measured evidence; see [E01 compatibility](docs/E01_COMPATIBILITY.md) and the [accepted decision](docs/DECISIONS.md). The C01 release gate controls claims of overall Godot 4.0+ distribution support. Preserve ADR-0013 Gogo-only lowercase `@bindable` while designing T09 against the 4.0 baseline. **Do not auto-merge or silently downgrade support claims.**

## Non-negotiable toolchain: native Godot/Gogo + TypeScript ONLY (2026-11-02)

**Never add Python to Estragon, anywhere.** Production framework,
compiler, runtime and editor integration are native **GDScript and Gogo**.
Contributor scripts, test orchestration, evidence collectors, report
formatters and CI logic must be **TypeScript**, using **Yarn** for future contributor tooling. Existing Bun manifests/scripts are historical tooling, not a product dependency; converting them requires a separate scoped task, not incidental architecture changes. No Python source files,
Python test suites, Python inline shell snippets, Python setup actions,
or Python runtime dependencies. Keep native Godot fixture/tests in GDScript.
Small shell entrypoints may invoke engine or TypeScript tools, but must not
hide a Python fallback. Prefer existing TypeScript tooling; do not
introduce a new scripting language for convenience.

The owner explicitly rejected Python on 2026-11-02. If old research
docs describe historical Python evidence, preserve their facts but
**use only the TypeScript replacements** for current work. No Codex
session may reintroduce it, regardless of what an older issue says.

## Owner test and CI budget — strict two-version cap (2026-11-02)

**Applies everywhere:** Codex/local development, pre-PR verification, CI,
release checks, research and handoffs. Test at most **two distinct Godot versions**
per effort: official **4.0.4** and pinned **4.7.0**. These are the only routine
versions. Do **not** test 4.1–4.6, 4.7.2 or any complete 4.x matrix locally
or in CI. Do **not** download, launch or schedule extra engines as an
"optional" sweep or completion gate. Only the owner can explicitly change this
budget; a bug-specific substitution requires prior owner approval and must
**replace**, not add to, the two-version selection.

**Keep verification proportional:** run focused checks while developing, then
the relevant two-version acceptance once for review, not full suites after
every change. Do not demand hundreds of repeated cross-version assertions,
repeated full-matrix logs or all-minor test evidence from agents. CI runs 4.0.4
on macOS and the established 4.7.0 baseline on Linux; no redundant macOS
4.7.2 or repeated push+PR workflow. Keep existing narrower single-version
unit, runtime and native checks where useful.

**Preserve historical evidence:** Old nine-version reports/manifest entries
remain truthful archival research, **not instructions to rerun**. New snapshots
can contain one or two versions; retain actual PASS/FAIL/BLOCKED/UNTESTED.
Product target remains Godot 4.0+ without inventing full per-minor
certification. Never claim untested minor versions were freshly verified.

## Compatibility engineering: pragmatic bridges and progressive enhancement

Owner refinement, 2026-10-30 ([C01-C #46](https://github.com/resistdesign/Estragon/issues/46#issuecomment-6534935109)):
bridge older-engine gaps when supported APIs offer a clean, safe solution with
reasonable implementation and maintenance cost. Prefer small compatibility
bridges over fragile introspection, custom infrastructure or extensive backports.
When a bridge is disproportionately complex or brittle, preserve valid behavior
and use the older engine's normal error path; reserve improved or earlier
diagnostics for engines exposing the capability. Missing optional introspection
must not reject otherwise valid inputs or raise the engine minimum. Keep all
available safeguards, document the precise diagnostic difference and test both
paths. C01-C applies this to proactive Callable arity checks only; validity,
disposal, connection and automatic lifecycle checks remain mandatory.

For current compatibility work, consult the live task issue and
docs/WORK_STATUS.md for the delivery queue and handoff. Keep transient task
status out of standing agent rules. The owner-approved native validation
contract in docs/C01_E_VALIDATION.md still applies: actual-path semantic
validation and rollback are mandatory before build success. Optional
diagnostic degradation does not permit stale source or cache takeover.

## Non-negotiable architecture

1. **Follow ADR-0015.** Use native Node composition and Node2D/Node3D visuals for the target; Estragon owns measurement/layout/component semantics while Godot supplies rendering and native services. GGX can compose native Controls as ordinary Nodes; that does not make them automatic Estragon participants or replace Estragon's UI suite with stock Controls.
2. **One child rule.** Only inherited Node.add_child(Node); no pragmas or type-specific adders. Treat owner/persistence separately from parentage.
3. **Separate layers.** Keep parser, typed model, emitter/maps, bindings, mathematical layout and native visual/adapters independently testable. Compiler analysis/codegen must not depend on EditorInterface, rendering or a running SceneTree.
4. **Compile source.** Generate deterministic valid GDScript; no runtime XML/JSON interpreter, regex mixed-language rewriting, ignored attributes or stale-source fallback.
5. **Preserve the present.** Existing RefCounted ownership, lifecycle and RenderingServer evidence describe current code. Replace them only through scoped compatibility-tested migration; do not erase history or claim the target shipped.
6. **Real reactivity and retained identity.** Scoped subscriptions and event-driven affected-branch measure/arrange; no compulsory polling, full-tree refresh or virtual DOM.
7. **Explicit boundaries.** Ordinary Nodes do not tunnel Estragon layout. Specify entry points, native adapters, coordinates, native/layout authority and feedback prevention.
8. **No accidental decisions.** Follow [DECISIONS](docs/DECISIONS.md) and live task scope. Open 3D units/wrapping, transforms and ownership questions require reviewed specifications. No automatic merge or release claims.

## Reality check: what exists today

**Implemented:**

- `addons/estragon/layout_proof/`: experimental B2 Node2D/Node3D entries/participants sharing one pure row-layout core and native event coordinator. See [B2 contract](docs/NODE_LAYOUT_PROOF.md) and 2D/3D `examples/layout_proof` demos. Bounded proof defaults are proposed for review, not a full component migration or B3 adapters.

- `addons/estragon/compiler/node_proof/`: opt-in ADR-0015-B1 compiler proof, separate from default frontend/editor builds. See [B1 contract/evidence](docs/NODE_COMPOSITION_PROOF.md) and `examples/node_proof/Main.tscn`; no B2/B3 layout or adapters.

- `addons/estragon/compiler/`: N01 native GDScript lexer, hybrid parser, typed built-in validation and source diagnostics, independent of editor/runtime/Bun. N02 adds native emission/maps and explicit Godot semantic validation; N03 uses them directly for native editor builds, transactional publication and Script refresh; no executable setup is needed. See GOGO_LANGUAGE and the Godot-only `sh tools/check-native-frontend.sh` and `sh tools/check-native-generation.sh` harnesses. Native compile API: `compiler.gd`; semantic validation: `script_validation.gd`; no external process or file publication is involved.

- `tools/transpile-gogo.ts` + `tools/gogo/`: T04/T05 namespace-free component parser, GDScript lexical composition, typed factories and range source maps. Mixed methods/expressions and generated Button.pressed callbacks work within GOGO_LANGUAGE; bindings remain future work.
- `tools/gogo.ts`: **stage-0** strict, namespace-aware TypeScript Gogo compiler and deterministic JSON IR generator, executed with Bun. Its syntax is temporary.
- A `View` document root containing zero or more `Rect` leaves at explicit canvas coordinates; no nested containers or component registry.
- `addons/estragon/runtime/gogo_view.gd`: a single Godot host `Node` drawing rectangles via `RenderingServer.canvas_item_add_rect()`.
- A checked-in Gogo example plus generated IR, Bun test coverage, strict TypeScript typechecking, and GitHub Actions compiler checks.
- An optional editor plugin with native `.gogo` highlighting, saved-source builds, diagnostics and failure-blocking compile-before-Play. See docs/EDITOR.md and gogo.config.json.
- `EstragonDisplayObject` / `EstragonContainer` RefCounted foundations: ordered ownership, weak parent links, disposal and dirty flags; plus minimal fixed/auto/fill VBox/HBox layout, rectangle paint commands and a RenderingServer surface, alongside the unchanged JSON host. T06 adds independent Text/Button, ordered text/rectangle paint and surface-owned primary-mouse capture; T07 adds generated Gogo Button.pressed wiring with native Callable guards and automatic connection cleanup.

**Not implemented:**

- General ADR-0015 Node-native GGX/compiler/component migration and B3 native layout adapters. B1/B2 prove bounded native composition and explicit spatial entries with composed row measurement/arrangement only.

- Reconciliation, generalized layout beyond the minimal stack rules, general styling, keyboard/touch input, focus, accessibility, or a broader widget catalog.
- Gogo-only lowercase `@bindable` compilation, code-only bindable model classes, one-/two-way Gogo bindings, ArrayCollection-like observable collections, keyed list reconciliation, reactive position/layout properties or a dependency graph.
- A `.bgd` frontend, Gogo language server, completion/navigation, live preview, debugger remapping, or a `RenderingDevice` backend.

Do not write new examples, PR descriptions, or documentation that imply these proposed capabilities already work. `docs/ROADMAP.md` and tracking issues describe **desired outcomes**, not shipped behavior.

## Repository map

| Path | Responsibility |
| --- | --- |
| `tools/gogo.ts` | Legacy stage-0 parsing, strict validation, canonical JSON IR, CLI |
| `tools/transpile-gogo.ts`, `tools/gogo/` | T04/T05 markup/hybrid syntax, typed IR, validation, GDScript emission and source maps |
| `examples/compiled/`, `tests/godot/generated_gogo.gd` | Generated Gogo surface example and actual Godot runtime verification |
| `tests/gogo.test.ts` | Compiler behavior, negative cases, and checked-in example consistency |
| `examples/hello/Main.gogo` | Authoritative source for the stage-0 demo |
| `examples/hello/generated/Main.gogo.json` | Generated, versioned example IR; checked into Git |
| `addons/estragon/runtime/gogo_view.gd` | Experimental Godot host and low-level drawing |
| `addons/estragon/runtime/display_object.gd`, `container.gd` | Independent component ownership, disposal and invalidation foundations |
| `tests/godot/components.gd` | Standalone component contract tests through T01 validation |
| `examples/hello/Hello.tscn`, `project.godot` | Minimal Godot application host |
| `addons/estragon/editor/` | Native highlighting, project discovery, transactional builds, resource refresh and F5/F6 gate |
| `tools/build-gogo.ts` | Optional historical TypeScript build/reference tool; never used by the addon |
| `docs/GOGO_LANGUAGE.md` | Implemented Gogo subset vs speculative syntax |
| `docs/ARCHITECTURE.md`, `docs/VISION.md` | System boundaries and direction |
| `docs/BINDING.md`, `docs/EDITOR.md` | Planned reactivity and editor work |
| `docs/DECISIONS.md`, `docs/ROADMAP.md` | Accepted/provisional decisions and milestones |
| `docs/DESIGN_DIRECTION.md` | Target Gogo/GGX Node-native composition, layout and unresolved Godot boundaries |
| `docs/NODE_MIGRATION_PLAN.md` | ADR-0015 serial proof/migration tasks, acceptance, dependencies and open specifications |
| `docs/EXECUTION_PLAN.md` | Stable scoped Codex tasks, dependencies, acceptance criteria and gates |
| `docs/WORK_STATUS.md` | Reviewed task status snapshot and cross-session handoff/resume template |
| `docs/REACTIVITY_PLAN.md`, `docs/BINDING.md` | Accepted Gogo-only bindable/data/collection/layout contracts and staged T09 scope |
| `docs/TESTING.md`, `CONTRIBUTING.md` | Verification and contribution standards |
| `Assets/` | Project-owned visual/source assets; preserve originals |

## Required execution planning, tracking, and cross-session continuation

### Repository-wide limit: one open PR total

The owner requires **at most one open pull request across this entire repository**,
including drafts, documentation, research and agent-created PRs. Check the complete
open-PR list before starting delivery. Resume the existing PR/branch; never open a
replacement, stacked or competing PR while it is open. Future features, bugs,
research and dependencies stay in durable GitHub issues until the current PR is
merged or closed. Finish or close it before opening the next PR. A blocked PR
must record evidence and be presented for an owner decision; do not bypass it with
another PR. **Never merge automatically.** Every task requires an issue,
actionable plan, implementation checkpoints, exact verification evidence and a
cross-session handoff. Follow the active issue and staged Node migration queue in
[EXECUTION_PLAN](docs/EXECUTION_PLAN.md); C01 release blockers remain separate.
Do not start a successor while the current review PR is open.

**This protocol is mandatory for Codex and other contributors working on planned features.** Session/chat context is temporary; **GitHub issues/PRs and committed repository files are the durable team memory**.

### Four different sources of truth

1. **Product direction:** `docs/DESIGN_DIRECTION.md` and accepted `docs/DECISIONS.md` entries. These define what Estragon should be; an execution shortcut must not override them.
2. **Delivery scope/dependencies:** `docs/EXECUTION_PLAN.md`. It defines stable work IDs (`T01`–`T10`, **`N01`–`N03`**, `R01`/`R02`), acceptance criteria, ordering, boundaries and the milestone definition.
3. **Live work state:** the **task's GitHub issue, PR, branch and CI**. The issue/PR contains the current short plan, owner/branch, checked steps, links, blockers, evidence and **latest session handoff**. Actual merged source/tests are the authority for what is implemented.
4. **Reviewed status snapshot:** `docs/WORK_STATUS.md`. It indexes ready/queued/completed work and explains how to resume. It is a *snapshot*, not a substitute for checking the live issue/PR. Update it in task-completion or plan-change PRs; avoid conflicting mid-session edits to a centralized status file.

**Never infer progress from an old chat or from the existence of a branch.** A task is `Done` only after its acceptance criteria are verified **and its PR is approved and merged**. `Ready`, `Queued`, `Active`, `Blocked`, `In review`, `Done` and `Deferred` have the meanings specified in `WORK_STATUS.md`. Do not turn `Blocked` into a changed product requirement without a recorded decision.

### Session startup / resuming work (before editing)

1. Read this file, `docs/EXECUTION_PLAN.md`, `docs/WORK_STATUS.md`, relevant language/architecture docs and the task's issue/PR. Check the **current** `main` and open PRs; do not assume the snapshot is current.
2. Inspect the branch and working tree (`git status --short --branch`, recent commits, uncommitted changes and tracking branch) before pulling, switching branches or changing files. Apply the standing local cleanup authorization above to disposable Godot changes; preserve unfinished implementation work and never force-push over it.
3. **Resume an existing issue/branch/PR** if that work ID is already active; read its **latest handoff comment**, failing checks and remaining acceptance items. Do not start a competing implementation.
4. If unclaimed, choose exactly **one Ready work ID** whose prerequisites are satisfied. Reuse a properly scoped existing issue or create a narrow issue with that ID; distinguish older umbrella issues from a task-specific assignment. Record issue link, branch and dependency state before coding.
5. If an architectural/interface choice is genuinely unresolved, capture options and a proposed decision in the issue. Do not treat a tentative syntax or Godot extension mechanism as implemented.

### Plan before implementation; maintain it as work changes

- In the task issue or linked draft PR, write an **actionable mini-plan**: objective, files/layers touched, steps/checklist, measurable acceptance criteria, validation commands, risks/unknowns, dependencies, and explicit out-of-scope work. Include the work ID and issue link in the PR.
- Keep the plan **small enough for one PR**. Split unexpected scope into a linked follow-up task instead of broadening the current PR. Work in testable checkpoints; post meaningful progress to the issue/PR as steps actually land, with commit/test links where available.
- If dependencies, task scope or the work sequence must change, propose a **reviewed plan update** to `docs/EXECUTION_PLAN.md` and the related issue, with rationale. Changes to accepted architecture also require an ADR update or explicit review. Don't silently re-plan the project in a chat reply.
- Check current issue/PR before making a new branch, especially when running multiple Codex sessions. Other sessions may maintain issue-only backlog/research while the single PR is active; do not create competing implementation work or PRs.
- Research tasks can end with an **evidence-backed limitation**; R01 did so. The owner has since explicitly chosen lowercase Gogo-only `@bindable` (ADR-0013). Never revert to the superseded ordinary-`.gd` promise or select `.bgd` without a new decision.

### Progress checkpoints and honest verification

- Record at least **task start**, **meaningful completed checkpoints**, **any blocker/decision**, and **end-of-session handoff** on the task issue or PR. Update checkboxes only for steps actually completed; link branch/commit/CI and describe what failed or was not tested.
- Use `bun install --frozen-lockfile` and `bun run check` for existing tooling. After `T01` lands, use the documented Godot headless checks for Godot-facing changes. Also state whether a **manual Godot 4.7 visual smoke test** ran; headless parsing is not visual proof.
- Do not report “tests passed” without specifying which tests and evidence. Don't advance a dependent task just because code was drafted: check prerequisite merge/review/CI and end-to-end acceptance.
- An **implementation PR** must include **one work ID**, linked issue, scope vs non-goals, test evidence, limitations and remaining follow-ups. A **planning/docs-only or ADR PR** may have no implementation ID, but must clearly identify itself as such and contain no disguised feature work. **Do not auto-merge without the user's explicit request**.
- Update `docs/WORK_STATUS.md` in the PR completing a work item (the `Done` entry becomes part of `main` only upon merge). The **live issue/PR** records `Active`/`Blocked`/`In review` while work is not yet merged. Reconcile stale status snapshots instead of trusting them blindly.

### Owner testing policy (2026-11-01)

**Physical/manual keyboard-keypress tests, including pressing F5/F6 by hand,
are not acceptance or release requirements.** Do not schedule them, ask the
owner to perform them, or treat their absence as a blocker or outstanding
verification task. Verify F5/F6 and other editor behavior through automated,
isolated real-Godot editor/game tests instead; continue required native
graphics/visual evidence and all other scoped tests. The owner will report
real-world interaction bugs through GitHub issues if encountered. Preserve
historical test records, but update future task criteria and verification
gates so physical-key checks are not required.

### Mandatory handoff at session end or interruption

Before ending **any session with work started**, including one that is blocked or has an open PR, post a durable handoff comment to the **task issue or PR** using the template in `docs/WORK_STATUS.md`. It must include:

- Work ID, issue/PR, state, active branch and **latest commit SHA/base**, plus whether the working tree has uncommitted or unpushed work.
- What changed (specific files/steps), **exact verification commands/results/CI links**, and explicit untested items.
- Remaining acceptance checklist, any blocking question/decision with supporting evidence, and the **next exact action** another session should take.
- Whether the PR is awaiting review/merge or still needs implementation; never claim “done” for an unmerged PR.

If the GitHub issue/PR cannot be updated, commit a handoff note on the task branch if possible and **report that the handoff was not published**. Do not claim seamless continuation if the only record is ephemeral model/chat context.

### Reviewer / continuation checklist

A fresh session should be able to answer, **from GitHub + repository files alone**: Which work ID is claimed? What merged or failed? What is next? Where is the branch/PR? What does the user need to decide? If any answer is missing, **repair the record before doing new feature work**.

## How to approach a task

1. **Inspect and resume first.** Follow the required execution protocol above; read the selected work ID, existing branch/PR, last issue handoff, affected source/tests, `docs/VISION.md`, `docs/ARCHITECTURE.md` and `docs/DECISIONS.md` before structural changes.
2. **Classify the work.** Is this a change to the implemented stage-0 contract, an experiment, or a proposed future capability? Say which; do not collapse those categories.
3. **Make the smallest coherent change.** Follow the selected task's acceptance criteria, mini-plan and dependencies. Avoid unrelated refactors, speculative scaffolding, extra documentation, dependency churn, or changes to supplied assets.
4. **Preserve a working vertical slice.** Source, compiled IR, Godot consumer, tests, and docs must agree whenever their shared contract changes.
5. **Verify and leave a durable handoff.** Run the relevant checks, name unrun checks, update the issue/PR progress and end with an actionable handoff. Never say Godot behavior was tested when only compiler tests ran.

Use ordinary engineering judgment for routine implementation details. Surface genuinely undecided architectural choices rather than assuming approval for a new language, backend, engine fork, or incompatible IR format.

## Stage-0 Gogo contract (temporary legacy compatibility; do not break accidentally)

- **Stage-0 only:** current XML components require URI `urn:estragon:gogo:1`. **The planned Gogo language uses no XML namespace prefixes/declarations.**
- Exactly one root `View`; required `width` and `height` are finite positive numbers; optional `id`.
- Only `Rect` leaves below `View`; required positive finite `width` and `height`, required `fill`; optional finite `x` and `y` default to `0`; optional `id`.
- IDs are unique and nonblank. Text content, unknown elements/attributes, nested `View`, and children of `Rect` are rejected.
- Colors accept `#RRGGBB` or `#RRGGBBAA`, normalized to lowercase `#rrggbbaa` (opaque alpha added when omitted).
- Invalid input raises `GogoError` with a useful diagnostic. Do not turn an error into a warning or silent default without an explicit specification change.
- IR currently uses `format: "estragon.gogo.ir"`, `version: 1`, and a `root` object with `type`, `props`, optional `id`, and `children` where applicable. The JSON emitter is deterministic and ends with a newline.
- IR is **not** a Godot `PackedScene` and should not include a Godot node type for every UI element.

If an IR change is incompatible, deliberately define/version the new contract and update its compiler, consumer, fixtures, tests, and docs **together**. Do not simply mutate version 1 and hope old consumers still work.

## Area-specific implementation rules

### Gogo compiler and language

**Native migration:** The TypeScript/Bun compiler below is existing reference/test tooling; N01/N02 implement the same supported Gogo language in native GDScript, and N03 makes that the editor's only compiler. Do not make Bun a developer requirement after N03.

- Legacy work uses `tools/gogo.ts` / `tests/gogo.test.ts`; T04–T07 use `tools/gogo/`, `tools/transpile-gogo.ts`, `tests/transpile-gogo.test.ts`, `tests/hybrid-gogo.test.ts` and `tests/signal-gogo.test.ts`. Keep both compilers independent of the running Godot editor.
- Preserve strict schema/type validation and deterministic output. Test both valid examples and malformed/unsupported input.
- Prefer minimal, pinned dependencies and strict TypeScript for contributor tools. The legacy XML reference needs its namespace-aware parser; GGX uses the real native mixed-language parser. Keep compiler analysis/codegen independent of editor/runtime state.
- For syntax changes, update `docs/GOGO_LANGUAGE.md`, any example `.gogo`, and checked-in generated IR. Mark proposed syntax as non-executable until it actually compiles.
- Do not implement expressions with JavaScript `eval`, `new Function`, ad-hoc string substitution, or regex rewriting of GDScript. Parser/source-location and type semantics matter.

### Runtime, components, and rendering — preserve current contracts during migration

- Application code must never need manual disposal in normal usage. Surface/container owners automatically clean unmounted/replaced components and renderer resources; reparent directly to transfer ownership without cleanup (ADR-0008).
- Keep model state and mathematical layout testable without drawing; target visual components use native Nodes. Native lifecycle/transforms require real SceneTree tests.
- The current host allocates one `RenderingServer` canvas RID, clears it before redraw, and frees it in `_exit_tree()`. Preserve resource ownership and cleanup.
- Treat `RenderingServer` as a backend adapter. Do not spread direct canvas calls through future layout/binding/component layers.
- ADR-0015 accepts Node-based visual components. Do not impose one RID or universal drawing implementation per Node; use native rendering and measure performance.
- For visual/runtime changes, include a repeatable Godot smoke test. A green compiler CI run does not prove rendering works.

### Reactive state (future work)

- R01's Godot 4.7 findings live in `docs/BINDABLE_FEASIBILITY.md` and `sh tools/check-bindable.sh`; they explain why native `.gd` annotations are not supported. The owner has settled the authoring boundary: `@bindable` **only in Gogo**, transpiled to typed GDScript; there is no approved `.bgd` alternative. See ADR-0013 and `docs/REACTIVITY_PLAN.md`.
- Implement reactive visual/layout properties as well as model data properties. `x`/`y` do not yet exist and require explicit parent-layout semantics; bindable data models and observable ArrayCollection-like contents (including item mutations) are required. No per-frame polling or full-tree refresh for routine property changes. E01 #40 is merged; preserve the accepted E01-F hidden-tab limitation.
- Before implementation, establish observable-property semantics, typed setters, initialization/equality behavior, and inheritance/custom-accessor behavior. Adapt T09 to retained Nodes and a composed layout core; the older RefCounted Box inheritance target is superseded by ADR-0015.
- Account for nested path replacement, subscriptions and disposal, collection mutation, cycles, two-way feedback protection, and batched invalidation.
- Keep observable models usable without inheriting from a Godot `Node`. Test state changes independently from drawing.

### Editor integration (T08/N03; native Godot only)

- The plugin calls the bundled compiler and semantic validator directly; no subprocess, Bun discovery/configuration or fallback is allowed. Explicit gogo.config.json remains authoritative; without it scan project sources with documented exclusions. See EDITOR.
- Stage/validate multi-file outputs and restore old code/maps/timestamps on failure. Preserve no-op bytes/UIDs. Explicitly refresh generated GDScript resources in place; filesystem records alone do not guarantee current cached bytecode. Test dependent scripts and class identity.
- Before both Play paths save native Gogo buffers; unsavable or invalid source must block stale execution. Keep automatic highlighting, diagnostics, saved/external-source notifications and clean disable/re-enable/restart behavior.
- The text-extension editor preference is **global and persists after disabling the plugin**. Never erase existing values, force-enable the plugin in the owner's checkout, or silently change user preferences in tests. Real-editor tests use a copied self-contained binary/project and empty executable PATH.
- Keep editable Gogo accessible. Completion/navigation, debugger remapping and live preview remain future work. Target GGX composes native Nodes; preserve current runtime contracts until reviewed migration.

### Documentation, examples, and assets

- Distinguish **implemented**, **experimental**, **proposed**, and **unverified** claims. Update docs only where behavior or a decision actually changed.
- Preserve original user-supplied assets byte-for-byte unless the requested task explicitly calls for transforming them.
- Do not add policy essays, attribution pages, reexports, or new asset organization that the user did not request.
- A settled design choice belongs in `docs/DECISIONS.md`; a speculative idea belongs in a proposal or issue, not silently in the supported language contract.

## Verification commands (repository root)

For documentation/planning-only tasks, use proportional document/link/scope checks and report runtime/visual suites not run. Do not install dependencies or launch engines solely for prose changes. The commands below apply when their implementation layers change.

**Historical existing contributor/test workflow (not a new tooling prescription):** Bun 1.4.4 runs existing TypeScript tools and tests. These may remain optional CI/reference tools; normal Gogo compilation/editing/Play is already Godot-native under N01–N03. The TypeScript compiler checks do **not** require Godot:

```sh
bun install --frozen-lockfile
bun run typecheck
bun run test
bun run verify:ir
```

When intentionally changing the legacy example, regenerate the committed IR from its source, then rerun the checks:

```sh
bun run gogo examples/hello/Main.gogo --output examples/hello/generated/Main.gogo.json
```

For Godot-facing changes, also perform or explicitly request a **manual Godot 4.x visual smoke check**: open the root `project.godot`, run `examples/hello/Hello.tscn`, confirm the dark background, purple block, and teal stripe, and inspect the remote scene tree for one Estragon host rather than per-element widgets. If you cannot run Godot, say **not tested** rather than claiming success.

For the T04 example, regenerate and verify GDScript instead:

```sh
bun run transpile examples/compiled/Layout.gogo --output examples/compiled/generated/Layout.gd
bun run verify:gdscript
```

For the T05 hybrid example, generate code and its source-map sidecar:

```sh
bun run transpile examples/mixed/Mixed.gogo --output examples/mixed/generated/Mixed.gd
bun run verify:gdscript
```

Godot is the GDScript semantic/type authority; do not claim the TypeScript
composition frontend fully typechecks expressions. See GOGO_LANGUAGE/ADR-0009.

For Godot-facing changes, also run the pinned Godot 4.7 headless checks:

```sh
bun run check:godot
bun run test:godot-harness
bun run test:editor
# Independent native compile/runtime proof, with Bun/Node unavailable:
sh tools/check-native-generation.sh
# Independent fresh-project native editor/Play/restart proof:
sh tools/check-editor.sh
```

See `docs/TESTING.md` for `GODOT_BIN`, version pinning, isolation and failure detection. Editor integration tests must use the self-contained isolated harness; never force-enable the plugin or alter user editor settings in tests.
GitHub Actions (`.github/workflows/ci.yml`) typechecks TypeScript, runs Bun tests,
verifies example IR, and runs Godot import, every-script parsing, runtime smoke
and harness failure probes. Headless checks do **not** certify visuals.

## Definition of done / PR hygiene

Before calling work complete, check:

- [ ] An implementation PR identifies **one work ID** from `docs/EXECUTION_PLAN.md`, linked issue and latest handoff; a planning/ADR-only PR explicitly states its non-implementation scope.
- [ ] The issue/PR plan, checkpoints, blockers and next action are current for the next Codex session.
- [ ] `docs/WORK_STATUS.md` is updated when completion or plan change is being merged (or status changes are explained in the linked live issue).

- [ ] The change matches the user's request and does not introduce unrelated churn.
- [ ] ADR-0015 Node-native target and current-runtime compatibility boundaries are respected.
- [ ] Existing implemented behavior is preserved, or a deliberate compatibility change is described.
- [ ] New behavior has positive, negative, and edge-case tests where appropriate.
- [ ] Example source and committed IR agree whenever either changes.
- [ ] Relevant documentation states what really works, without promoting proposals to features.
- [ ] The exact commands run and their results are reported; manual/runtime checks not run are called out.
- [ ] The PR has a concise purpose, change summary, verification, and any open design or compatibility questions.

Prefer a focused, reviewable PR over a sweeping rewrite. Do not merge it yourself unless explicitly requested. Avoid false confidence, unrequested side quests, and work that merely *looks* complete.

## Source of truth

- **Implemented behavior:** the relevant source code and passing tests.
- **Accepted architecture:** `docs/VISION.md`, `docs/ARCHITECTURE.md`, `docs/DESIGN_DIRECTION.md` and accepted entries in `docs/DECISIONS.md`.
- **Language specification:** `docs/GOGO_LANGUAGE.md` (read its supported/proposed labels).
- **Delivery plan and status:** `docs/EXECUTION_PLAN.md` defines work IDs/dependencies; issues/PRs hold live state; `docs/WORK_STATUS.md` is the reviewed snapshot and handoff protocol.
- **Broader planned work:** `docs/ROADMAP.md`, `docs/BINDING.md`, `docs/EDITOR.md`, and related research issues.
- **Contributing and verification:** `CONTRIBUTING.md` and `docs/TESTING.md`.

If sources disagree, do not paper over the discrepancy. Identify whether it is a code bug, documentation drift, or an unresolved design decision, and resolve only what the task authorizes.

## Development CI versus publishing authorization

Ordinary PR/development CI verifies regression and evidence integrity; it is not
release authorization. `tools/assert-release.ts --mode development` preserves
the truthful release verdict and permits only the exact engine/stage/outcome
expectations documented in `tools/development-policy.ts` and the scoped issue.
Known release blockers may coexist with green development checks; unknown
failures, changed diagnostic fingerprints, missing evidence and source/engine
mismatch must fail. Updating development expectations requires explicit review;
never blanket-ignore failures or relabel observed FAIL/BLOCKED/UNTESTED as PASS.

Actual release/publishing/support certification must first run the strict
`tools/assert-release.ts` command (default, or `--mode release`) on matching clean
source/engine artifacts and require exit zero with every required release stage
PASS. Development success, a merged infrastructure PR or collection exit zero
cannot authorize publishing. Manual workflow dispatch `verification_mode=release`
selects this fail-closed boundary in both approved-engine jobs; no publishing
step exists yet. Any future publisher must depend on the strict results for both
approved engines and may not use development mode to authorize delivery.
