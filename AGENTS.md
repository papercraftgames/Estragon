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

## Shipped architecture and scope — ADR-0015 / C4

Estragon is a **Godot addon**, providing layout-first native Node2D UI and bounded Node3D layout/adapters. Godot owns SceneTree lifetime, transforms, rendering, physics and platform events. Gogo is the GDScript-like language; GGX is its general-purpose Node composition syntax. Read [ADR-0015](docs/DECISIONS.md#adr-0015--ggx-node-native-composition-and-layout-first-estragon), [migration record](docs/NODE_MIGRATION_PLAN.md) and live issue/PR before edits.

C4 #83 replaces the former parallel RefCounted UI with **one native production architecture**. Canonical widgets are EstragonRect/Text/Button/HBox/VBox under runtime/node. No old surface/paint/input tree, stage-0 JSON interpreter, reserved short-tag factories, Error-returning child adders or transitional *2D widget aliases remain. Historical reports are archival, not supported executable paths. Use canonical native class tags or normal explicit preload aliases. Godot's Button remains Button; EstragonButton is the framework widget. No magical remapping.

Only inherited void Node.add_child(Node) attaches GGX children. Every tree item derives from Node; non-Node resources/models remain values. Native typed properties and named handler/Callable signal connections apply to ordinary Nodes too; any referenced Object can supply signals. No inline anonymous declarations in GGX event attributes. Ordinary functions/lambdas may contain GGX. Parser/model/emitter/maps remain independent of EditorInterface, drawing and a running SceneTree; never parse mixed syntax using regex substitutions or runtime XML/JSON.

Native components use Node2D/Node3D and the **same composed mathematical core**, retained identity/subscriptions and affected-branch event-driven measure/arrange. The **current shipped** T09-B pipeline has no Virtual DOM. The **approved next architecture ADR-0016 explicitly introduces a small Virtual DOM/description-based reconciler**, triggered by Gogo bindable signals, **not by per-frame render loops**. Node2D/Node3D identity and the composed layout core remain authoritative. Explicit entries re-enter layout below plain-Node boundaries. Native adapters expose bounded providers/authority; generic Nodes have no universal size. Scene owner persistence is separate from parentage. Preserve native removal/reparent/free, signal/resource cleanup and pack/reload proofs. Never recreate disposal/Error-child compatibility shims.

The bundled Godot-only compiler/editor is mandatory: no Bun/Node/external compiler process, separate language server or native extension is required for normal editing or Play. Save current Gogo buffers before both Play paths; reject unsavable/invalid source, validate actual-path semantics, transactionally restore code/maps/timestamps/cache identity, preserve stable UIDs and diagnostics, and recover after repair. Isolated preflight is unavailable on 4.0.4; actual-path validation remains mandatory. Native keep_state reload does not promise running-app initialization of new inherited fields. Tests must use isolated editor settings and never force-enable the addon or change user preferences in this checkout.

Target support remains **Godot 4.0+**. Fresh proof uses **official 4.0.4 and pinned 4.7.0 on Linux only**, without claiming untested minors/platforms. Use documented 4.0 public APIs; isolate tested version/capability bridges. Preserve valid behavior on older engines and exact fail-closed guarantees; optional introspection must not reject valid inputs. The narrow hidden never-associated tab highlighter limitation remains owner-accepted (#44), not fixed/PASS. Read current native-addon acceptance and release evidence; old C01 gate failures describe a retired product slice, never an automatic current verdict.

T09-A provides lowercase Gogo-only @bindable on explicitly typed top-level instance properties, including code-only non-Node data models, with native per-property change signals; read docs/BINDABLE_PROPERTIES.md for initialization, equality, reentrancy, inheritance and rejected accessor forms. T09-B adds bounded reactive self paths in GGX properties with native subscriptions and layout invalidation; read docs/REACTIVE_GGX.md. Broader widgets/style/focus/accessibility, collections/repeaters, two-way cycles and 3D wrapping remain unimplemented. Follow ADR-0013 and the reactivity plan; no .bgd or ordinary .gd custom annotations. Keep supplied Assets byte-for-byte. Do not infer future architecture has shipped.

## Owner-approved next architecture — ADR-0016 (2026-11-05)

**Authoritative design:** [Reactive Composition Architecture](docs/REACTIVE_COMPOSITION_ARCHITECTURE.md) and [ADR-0016](docs/DECISIONS.md#adr-0016--signal-driven-function-recomposition-with-retained-native-nodes). This *supersedes earlier no-VDOM, static-GGX-only and no-recomposition policies* without undoing real native Nodes, Godot physics/transforms, the shared layout engine or bundled compiler/editor. **The full architecture is an accepted target; F01's bounded native getter/description/static-shape proof is documented in docs/F01_COMPOSITION.md and its live issue/PR. F02 conditional/nested ownership is documented in docs/F02_CONDITIONALS.md and its live issue/PR; F03 mapped/keyed child sequences are documented in docs/F03_LISTS.md and live issue #96/its sole PR; F04–F06 are not shipped.** Read it and the issue #89 before preparing successor implementation plans.

The user model is **React-like readable Gogo functions automatically reexecuted by Flex-like `@bindable` signals**, without hooks or explicit invalidation. The function returns **lightweight desired element descriptions**; a **real but small Virtual DOM/reconciler** reuses native Nodes by type/position/optional key. Reconciliation records, key identity and subscription bookkeeping live **outside user Nodes, models and Resources**: no `set_meta`, injected fiber fields or binder/helper Node on each user component. The T09-B static dependency helper Node path is a **temporary production implementation** to remove after the new one replaces it. Never add a second permanent reactive system.

The repo is **unreleased**. There is **no obligation to preserve backwards compatibility** for earlier Gogo/GGX runtime/compiler APIs or tests. Once the new product slice is tested, remove obsolete code, generated assets, compatibility shims and old consumers; preserve historical evidence truthfully. Only one runtime/compiler API is supported after cutover. [Class-level `@bindable` #90](https://github.com/resistdesign/Estragon/issues/90) is a separately tracked future ergonomic feature. Ordinary external Node/Resource and raw Array/Dictionary mutations are not automatically observed without a real signal adapter/observable owner.

**Implementation order:** F01 small native dynamic-read/signal/descriptor/reconciler proof → F02 conditionals/deep ownership → F03 list mapping/keys → F04 full single-runtime cutover/removal → F05 class-level models/two-way binding → F06 measured optimization. Scope and exact acceptance are in the architecture document; one reviewable PR at a time, never auto-merge. Do not claim these features work before their tests/PRs merge.

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
repeated full-matrix logs or all-minor test evidence from agents. Owner #81 (2026-11-04) requires Linux-only CI for both 4.0.4
and pinned 4.7.0; no macOS jobs, extra platforms or repeated push+PR workflow. Keep existing narrower single-version
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

## Current code and verification

- addons/estragon/compiler: native lexical parser, typed Node metadata validation, deterministic GDScript/maps and semantic validation. compiler/native/resolver.gd performs static native/import resolution without instantiating authored Nodes.
- addons/estragon/runtime/node: canonical native UI, entries, participants, adapters and shared internal mathematical/layout/bounds/input services.
- addons/estragon/editor: native highlighting, saved/unsaved compile-before-Play, transactional publication and resource refresh.
- examples/counter: authoritative native Gogo Counter and default scene; examples/ggx: source-authored 2D/3D; examples/node_runtime: bounded adapter/boundary demos.
- tests/native_compiler, bindable, native_ui, ggx, node_runtime, metadata, distribution: current acceptance. tests/compatibility and tests/research are explicitly Godot-ignored archival research/evidence (TypeScript policy tests still execute with Node).
- tools/check-native-addon.ts: proportional acceptance and exact-source/engine evidence; tools/assert-release.ts: strict native-addon gate. No standalone-app export requirement. Missing/failed/mismatched/dirty evidence and unexpected errors fail closed; no legacy development exemptions.

Read docs/GOGO_LANGUAGE.md, docs/NODE_UI.md, docs/NODE_RUNTIME.md, docs/EDITOR.md and docs/TESTING.md for actual contracts. Run bun install --frozen-lockfile and bun run check for the retained contributor typechecking/policy tests. New automation is TypeScript/Yarn; use corepack yarn@1.22.22 node --experimental-strip-types tools/check-native-addon.ts with only approved Linux engines, a new absolute output directory, and Xvfb/software graphics as documented. Focused runs during development, then one relevant two-version acceptance; no physical F5/F6 keypress requirement. Native editor/game tests and actual rendered captures are separate evidence; state whether a manual interactive smoke session ran.

Preserve stable .gd.uid sidecars for every committed script (including generated/tests) and real asset .import settings, pair deleted/renamed files and UIDs, audit uniqueness and clean imports. Never blanket-ignore either suffix or copy arbitrary temporary runner UIDs. Narrow .gdignore entries may exclude audited evidence/research only, never live fixtures. Only .godot and documented caches are disposable. Leave exact commands/results/provenance, explicit limitations and a durable issue/PR handoff. A PR is In review until the owner merges; never auto-merge or start a successor.
