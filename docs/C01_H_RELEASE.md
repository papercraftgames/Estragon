# C01-H distribution evidence and strict release gate

[C01-H #51](https://github.com/resistdesign/Estragon/issues/51). The
distribution/strict release assessment infrastructure **merged as
[PR #66](https://github.com/resistdesign/Estragon/pull/66) on 2026-11-02 UTC**
(merge `ecee892d407c27b0b9c915f80ac589fdc9620b89`). The focused
[4.0.4 macOS](https://github.com/resistdesign/Estragon/actions/runs/41390753704)
and [4.7.0 Linux](https://github.com/resistdesign/Estragon/actions/runs/41390753660)
development CI jobs passed. **Strict release remains BLOCKED** in both reports;
C01-H's overall certification is **not done**, and T09 remains queued. The
only prior approved scope exceptions remain #44/numeric/arity, not additional
waivers.

**Next Ready: [#61 generated lambda-helper compatibility](https://github.com/resistdesign/Estragon/issues/61)**,
to be implemented in a separate review PR. After #61, independently resolve
4.0.4 cold missing-generated scene restoration, [#65 selected-resource pack
export cleanup](https://github.com/resistdesign/Estragon/issues/65), and the
standalone executable/platform release boundary. Archived runs/logs below are
provenance, **not instructions for a fresh full suite**: all future runs
use only the owner's selected 4.0.4 and pinned 4.7.0 engines, TypeScript-only
contributor tooling and Godot-native compiler/Play.

## What changed

The shipped project and native editor fixture declare Godot 4.0. Existing scenes
retain format 3 with script paths; script UID sidecars are retained and hashed.
The distribution collector starts without project caches or contributor tools,
imports actual addon/examples, reloads all 30 shipped scripts in their correct
native **editor** context, and loads/instantiates all six example scenes in a
separate runtime. It checks single hosts and generated Counter behavior.

The obsolete `native_build.gd` import exclusion is removed. The fixture now uses
capability-checked native Logger capture and a baseline directory API; its
existing richer 4.7 error-count verification remains enabled. The established
native editor suite passes 32 transactional build assertions. The collector also
requires independent registered/class/cache, no-op UID/timestamp, dependency,
inheritance, rollback and fresh-publication checks.

`release-policy.ts` requires core, distribution, lifecycle, Play, native graphics,
cold-scene restoration and executable-export outcomes. `assert-release.ts`
rejects missing/dirty/mismatched source or engine evidence and exits nonzero for
unmet requirements. A zero-exit collection is never release certification.
Native numeric conversion/old arity differences and observed filtered-tab FAIL
remain separate from their explicit owner dispositions. Physical keypress
absence is not a required stage. Native graphics remains separately required.

CI retains one 4.0.4 macOS Godot job and the existing 4.7.0 Linux job.
Ordinary PR/push verification invokes **development mode**: it validates all
matching clean-source/engine artifacts and accepts only precisely known release
blocker outcomes. It still writes a truthful **BLOCKED** release report alongside
an independent development-check PASS. This is not release authorization.

The accepted development baseline, derived from CI at head 5a47e3e:

| Engine | Allowed development-only release blockers |
| --- | --- |
| 4.0.4 | HybridEdges FAIL (#61), cold missing-generated scene FAIL, resource-pack export cleanup FAIL (#65), standalone executable export UNTESTED |
| 4.7.0 | Standalone executable export UNTESTED |

Known FAIL allowances require exact diagnostic/error fingerprints and execution
outcomes, with no timeout or extra errors. Missing stage/log evidence, changed
failure outcomes, unexpected required non-PASS observations or provenance mismatch
fail development checks. A blocker fixed to PASS is welcome and remains truthful.
The #44 exception and accepted numeric/arity capabilities remain separate.

**Publishing boundary:** assert-release.ts defaults to strict release mode and
exits nonzero on BLOCKED. Workflow dispatch verification_mode=release selects
that strict command in each approved-engine job; publishing/support certification
must require success for both. There is no publisher in this PR. Future delivery
steps must depend on those strict results, never development CI alone. No blanket
continue-on-error or ignored native exits are used. See permanent AGENTS.md policy.

## Actual local evidence and provenance

Only official **4.0.4** and pinned **4.7.0** were executed. These runs are on
macOS (`darwin 25.6.0`), not new proof for Linux, Windows, intermediate 4.x minors
or other GPUs. [Artifacts](../tests/compatibility/c01-h/), their source revisions,
engine identities and input hashes remain separate; normalized logs retain raw
and published hashes. `.pck` binary payloads are excluded, with export hashes in
reports. Native PNG captures are committed and visually inspected.

| Behavior | 4.0.4 macOS | 4.7.0 macOS |
| --- | --- | --- |
| Frontend, emission/maps, generated import/layout/signals, runtime/input | PASS | PASS |
| Actual-path semantic publication, rollback, identity, fresh defaults | PASS | PASS |
| Six cache-free distributed scenes and 30 scripts in actual editor context | PASS | PASS |
| Source-only native build without pre-existing generated output | PASS | PASS |
| Editor lifecycle, unsaved F5/F6 and restart | PASS | PASS |
| Counter native graphics, primary input, reset and resize | PASS | PASS |
| Corrected selected-resource pack runtime | PASS | PASS |
| Selected-resource pack export without native errors | FAIL (#65) | PASS |
| Cold scene restore referencing missing generated Script | FAIL | PASS |
| HybridEdges runtime / authored raw + generated lambda boundary | FAIL (#61) | PASS |
| Standalone executable export | UNTESTED | UNTESTED |

The frozen main acceptance at **`0df7c24`** runs compiler/runtime, distribution,
lifecycle and Play once per approved engine. All eight lifecycle/fresh-runtime
stages and all four Play phases pass (192 native Play assertions). The same
revision passes the graphical 4.7 editor/main/current-game/transaction/restart
suite, including actual generated input, disposal and resize. Native standalone
Counter captures on both engines show Count 0/1/reset, disabled Reset and wider
800×400 layout; the isolated editor capture shows Gogo colors and a single host.
This is automated visual evidence; no physical/manual keypress test is required.

Three focused corrections retain their original failures:

- `04fad0f` explicitly selects all runtime scripts in the pack. Global class-name
  dependencies were omitted by the initial **test preset**. The original pack
  runtime FAILs remain in `distribution-before`; corrected 4.0.4 runtime passes.
- `c77a72c` checks the **source** baseline separately from Godot's engine-version
  stamp in exported `project.binary`. Corrected 4.7 pack export/runtime pass.
  These distribution-only checks were rerun without repeating graphics or the
  core/lifecycle/Play suites.
- `af2cd06` fixes a migrated TypeScript classifier that counted Logger's mapped
  `Parse Error` repetitions as extra native errors. Original 4.7 collector FAILs
  remain unmodified. The exact saved transcripts contain 20 native semantic
  errors and one baseline negative, with success markers; the corrected pure
  classifier/unit test verifies them. [Reclassification provenance](../tests/compatibility/c01-h/semantic-reclassification.json)
  is separate from execution; no older run is relabeled execution of a new head.

The committed `release-assessment-before.json` rejects the matching clean
`0df7c24` artifacts with exit 1, including the then-unfixed fixture/classifier
failures. It is a before record. Current-head CI artifacts are the authoritative
combined assessment of the corrected harness. Do not mix different source
revisions to obtain a synthetic release PASS.

## Remaining release decisions and dependency order

1. **#61** needs a separately scoped authored-native syntax/generated-helper
   compatibility decision/fix. This PR does not rewrite Gogo or reduce syntax.
2. **Cold missing-artifact restoration on 4.0.4** is reproduced: native scene
   loading attempts the absent Counter.gd before validation/indexing permits
   generation. Distributing current generated files passes; a subsequent
   source-only build passes. These do not erase the early scene-load failure.
3. **[#65 export cleanup](https://github.com/resistdesign/Estragon/issues/65):**
   4.0.4 produces a usable pack but emits `Condition "_first != nullptr" is true`
   and `Resources still in use at exit`. Exit zero is FAIL. An empty Node-only
   export control emits no ERROR (it has an ObjectDB warning); its separate
   control runtime exited 1 and is not a passing application result. Root cause
   of the sample-bundle cleanup remains unproven.
4. **Executable export/platform scope is UNTESTED.** Resource-pack execution
   with the verified editor executable is not a standalone exported application,
   release template, Windows/Linux/macOS signing or other-platform proof. The
   owner must define/approve the release boundary or request bounded template
   tests before this criterion can pass. No wider engine matrix is authorized.

Review this gate/distribution slice, then explicitly determine the serial issue
order and dispositions for these blockers under the one-open-PR rule. C01-H and
T09-A cannot become release-ready from earlier scoped green checks or this PR.
No new exception, raised minimum, hidden error suppression or automatic merge.

## Reproduce with the current TypeScript tools

```sh
node --experimental-strip-types --test tests/compatibility/*.test.ts
node --experimental-strip-types tools/check-compatibility.ts --engine 4.0.4=/absolute/godot-4.0.4 --engine 4.7=/absolute/godot-4.7.0 --output /new/core --collect-only
node --experimental-strip-types tools/check-distribution.ts --engine 4.0.4=/absolute/godot-4.0.4 --engine 4.7=/absolute/godot-4.7.0 --output /new/distribution --graphics --collect-only
node --experimental-strip-types tools/check-editor-lifecycle.ts --engine 4.0.4=/absolute/godot-4.0.4 --engine 4.7=/absolute/godot-4.7.0 --output /new/lifecycle
node --experimental-strip-types tools/check-editor-play.ts --engine 4.0.4=/absolute/godot-4.0.4 --engine 4.7=/absolute/godot-4.7.0 --output /new/play
node --experimental-strip-types tools/assert-release.ts /new/core/results.json /new/distribution/results.json /new/lifecycle/results.json /new/play/results.json /new/release.json
```

These are review recipes, not instructions to repeatedly rerun complete suites.
Use the owner's bounded focused-test policy and preserve known failures. The
`--graphics` path requires a native display (Xvfb/Mesa in Linux CI). Runtime
engine/child processes have an empty executable PATH; no external compiler.

## Owner-directed development/release separation verification

The completed native CI runs at **5a47e3e**
([4.0.4 macOS](https://github.com/resistdesign/Estragon/actions/runs/41389380959),
[4.7 Linux](https://github.com/resistdesign/Estragon/actions/runs/41389380918))
failed only at their then-strict release step. Their native checks, including
Dummy-audio graphics, completed. The exact known blocker baseline above comes
from those structured reports, rather than inferred green process exits.

The reporting-only change was checked against those downloaded artifacts without
rerunning Godot locally. [Preserved assessments](../tests/compatibility/c01-h/development-separation/)
record **development exit 0 / release exit 1 on both engines**, with release
status **BLOCKED** unchanged. Provenance records the assessment implementation
revision, original native execution revision, CI links and input report hashes.
This is reassessment of existing evidence, not execution at a new source head.
Final-head CI checks for PR #66 **passed and were merged**. See
[#51](https://github.com/resistdesign/Estragon/issues/51) and
[merged PR #66](https://github.com/resistdesign/Estragon/pull/66) for exact
native provenance and the cross-session handoff. This documents completed gate
infrastructure **only**; the strict release assessment still blocks publishing.
The next scoped implementation is [#61](https://github.com/resistdesign/Estragon/issues/61).
