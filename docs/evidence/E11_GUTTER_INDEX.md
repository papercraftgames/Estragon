# E11 #147 — native negative gutter-index investigation

This resolves the investigation by demonstrating an **upstream Godot editor defect**, with a tested non-invasive mitigation. It does not fix Godot core or change Estragon production code. The owner's macOS4.7 screenshot establishes the original report; fresh proof here uses only official Linux4.0.4/pinned4.7.0. The original GogoDemo checkout was not available; the isolated direct-Yarn Home/Settings/Rose fixture reproduces its authoring/button layout independently.

## Cause and first error

Pinned4.7's ScriptTextEditor holds `line_number_gutter=-1` until the tab is activated and `_enable_code_editor()` runs `_update_gutter_indexes()`. A hidden, never-activated native `.gd` tab can still receive native idle validation after a line edit or native on-save formatting. `_validate_script()` calls `_update_errors()`, whose type-safe-line coloring loop passes that uninitialized cached index to TextEdit.set_line_gutter_item_color. The callee reports the native negative-index error once per line. The four gutters are native main/connection/line-number/fold; Estragon is not required to create this state.

Source references at the pinned upstream commit: [member defaults](https://github.com/godotengine/godot/blob/5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88/editor/script/script_text_editor.h#L85), [validation calls error coloring](https://github.com/godotengine/godot/blob/5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88/editor/script/script_text_editor.cpp#L841), [unsafe color loop](https://github.com/godotengine/godot/blob/5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88/editor/script/script_text_editor.cpp#L1022), [activation initializes indexes](https://github.com/godotengine/godot/blob/5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88/editor/script/script_text_editor.cpp#L2678), [reported callee](https://github.com/godotengine/godot/blob/5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88/scene/gui/text_edit.cpp#L6979).

Existing upstream [Godot#124489](https://github.com/godotengine/godot/issues/124489) describes this exact error and native Play/autosave/lazy-tab chain. Proposed upstream [#124551](https://github.com/godotengine/godot/pull/124551) removes the partially initialized ScriptTextEditor state. Both were OPEN/unmerged when checked for this task. Other releases named in those reports were not launched here and are not fresh evidence. No upstream issue/comment/patch was submitted.

## Minimal addon-free proof and mitigation

`tests/editor_gutters/upstream.gd` is an isolated test EditorPlugin containing only public Godot APIs. The runner copies **no Estragon addon** into its project.

1. Open Current.gd normally, then Hidden.gd with `EditorInterface.edit_script(...,grab_focus=false)`.
2. Record the hidden CodeEdit's native gutter names/count. Edit a line with public CodeEdit insertion and wait for native idle validation.
3. On4.7, exactly four `p_gutter=-1` diagnostics appear between explicit probe markers for the four-line file, **before Play, rendering a button, clicking, any Gogo text or any addon callback**. On4.0.4 this same probe emits none.
4. Activate Hidden through normal `edit_script(...,grab_focus=true)`, edit again and wait for the same validation. No further errors on either engine; all four native gutters remain intact.

**Mitigation:** after restoring a project/script layout, select each restored native script tab once before saving all scripts or running Play. Normal activation lets Godot initialize its own editor. This is a bounded workaround for the demonstrated lazy-tab state, not a promise against every upstream gutter bug. It does not require disabling type-safe colors, breakpoints, line numbers, autocomplete or changing project/user preferences. Keep using the supported pinned engine; no unapproved engine upgrade is required. Clear already-reported messages only after initializing the tabs; clearing Output alone does not fix the cause.

The addon must not rewrite private ScriptTextEditor member indexes, synthesize native gutter signals, remove/rename stock gutters, force-enable hidden editors or alter global settings to conceal the defect. No such workaround was added. Production diagnostic coloring looks up its owned gutter by name and returns when the index is negative; native breakpoints/source-map navigation/generated guard remain unchanged.

## Exact native evidence and acceptance

The current change contains only the native addon-free probe/UID, TypeScript orchestration and this documentation/evidence. **Every production addon byte is unchanged from merged main `c57409344398e6165998a3fca187e4c1c981fc14`.** No gutter ownership/index workaround, ScriptEditor mutation, diagnostic suppression or runtime/button/layout/compiler/template change was necessary.

| Proof | Official Linux4.0.4 | Pinned Linux4.7.0 |
| --- | --- | --- |
| Addon-free hidden native script | Failure not reproduced:0 errors | Upstream failure reproduced:exactly4 negative-index errors |
| Normal native tab activation, then equivalent edit/idle validation | PASS,0 errors | PASS,0 errors |
| Existing chain-completion source/native CodeEdit proof | 52 source +46 editor +4 restart PASS | 52 source +46 editor +4 restart PASS |
| Native main/current Exit->get_tree().quit | PASS, actual input and child process exit | PASS, actual input and child process exit |
| Direct Yarn / bounded relocation / standard-path probes | PASS,5 assertions each layout | PASS,5 assertions each layout |

The addon-free reproduction at clean `195e980fe086033e37530164be5f53eb5e98d87c` ran in30.98s total. Exact per-engine [4.0.4](e11/4.0.4/upstream/results.json) / [4.7](e11/4.7/upstream/results.json) results/log/provenance distinguish **a reproduced engine failure** from a passing mitigation control. The test permits only the exact4.7 negative-index message inside an explicit expected-failure bracket and rejects errors after activation or elsewhere; no addon error gate is relaxed.

Clean established authoring regression at `87f7bd510b50f968768a3b167775542ec24965ac` ran in85.08s total, only the two approved engines. Exact [4.0.4](e11/4.0.4/authoring/results.json) / [4.7](e11/4.7/authoring/results.json) logs/commands/source/engine provenance are committed. It proves native popup completion/acceptance/undo/caret/redo, bounded native/source return chains/call hints, GGX Callable attributes, actual source-map caret navigation, ordinary.gd isolation, saved compiled source and both main/current actual native Exit events, then restart. No negative gutter errors or other unexpected errors occur.

Existing direct-Yarn generated-editor4.7 regression at clean `47e0f9db4554b5a25e243afca8c9a1c20fcd34d6` also PASS:56 editor +6 restart assertions,40.81/10.14s, full runner61.41s. Read-only protection, generated/source actions/native breakpoint inspection, persistent dirty recovery and write failure, undo/redo/buffer identity, native navigation, unsaved Play/save/rollback/repair and restart are retained. [Exact results/captures](e11/generated-regression-4.7/results.json). This existing regression is independent corroboration; no additional production change or exhaustive suite.

All clean direct-Yarn runs test the identical reproducible development tar SHA256 **`a9eb230dc04753fad5039df8a2158888a889fc5ef566939765c40ccaeb3c2897`**, all55 addon UIDs and installed bytes unchanged. No installed copies/symlinks/package-ignore fallback. The unchanged product artifact is the same one tested for merged E08. Manifests, original engine hashes and consumer audits are adjacent to results. Frozen install/typecheck/30 policy tests PASS ([log](e11/static.txt)).

![Actual completed native Exit handler,4.7 established authoring proof](e11/4.7/authoring/chain-game.png)

## Exploratory owner-layout proof and separate failure

An additional Home/Settings/Rose stress fixture opened all three authored text tabs, authenticated generated Settings.gd and ordinary.gd; repeatedly edited/saved, completed get_tree().quit in Home and Settings with undo/redo, refreshed protected output, switched tabs, marked/repaired syntax, tested a one-line source gutter and addon teardown/reassociation, then ran main/current and clicked Settings Exit. All35 functional assertions passed on **both engines**, with no negative gutter-index diagnostics. Measured Exit position(0,64), size(64,44); Rose position(0,112), size(120,28): no overlap. Actual game captures were inspected.

However, **the overall exploratory stages are FAIL**, not accepted passes: native TreeItem/TextLine/shaped-text resources leak at editor shutdown. [4.0.4 failed stage](e11/exploratory/4.0.4/results.json), [4.7 failed stage](e11/exploratory/4.7/results.json), [verbose4.0 details](e11/exploratory/verbose-4.0.4.txt). These include2 leaked TreeItems/2 TextLines on4.0 and a shaped-text RID report. Their cause is **not established**; no attribution to upstream-only/addon/button and no fix is claimed. Controls removing synthetic theme notifications, duplicate internal teardown and injected plain-text breakpoint/bookmark marks still leaked ([later control](e11/exploratory/later-control-4.0.4.txt)). Scoped follow-up [#148](https://github.com/papercraftgames/Estragon/issues/148) preserves this unresolved investigation as issue-only backlog. That shutdown-lifetime investigation is separate from the conclusively isolated negative-index fault. It does not undermine the addon-free cause/control or the clean established editor regressions above; it is not silently discarded or counted green.

![Actual Settings Exit and Rose layout, exploratory4.7 run with separate shutdown failure](e11/exploratory/4.7/gutter-game.png)

To avoid expanding#147 into an unrelated editor-lifetime fix, the exploratory driver/UIDs and temporary runner mode were removed from live tests. Exact [47e0f9d driver](e11/exploratory/driver-47e0f9d.gd.txt)/[later control](e11/exploratory/driver-c25f508.gd.txt), structured FAIL records/logs/captures remain audited ignored evidence. The existing editor runner is byte-identical to main. No failing test was made green by suppressing leaks or excluding error lines.

Earlier local setup errors were corrected: source files needed filesystem rescan/settle before native FileSystem navigation; an initial minimal project accidentally copied an unrelated addon-dependent probe; a negative-line native activation caused a separate wrap-count error (use documented positive line); a test manually invoked internal cleanup twice; and one regression command omitted an engine subdirectory and failed before launching Godot. Raw attempts remain under `/tmp/e04-local/e11-*` and `/tmp/e11-*.log`. They are not final acceptance. The archived bare CodeEdit add/remove/Acceptance-script roundtrip was clean; this was not the failing native ScriptTextEditor path.

## Reproduce locally / provenance

```sh
bun install --frozen-lockfile
bun run check
docker exec -w /tmp -e XDG_RUNTIME_DIR=/tmp/e04-runtime estragon-e04-local \
  xvfb-run -a sh -c 'exec corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-editor-gutters.ts --engine 4.0.4=/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/e11-upstream-final'
```

The established authoring regression uses the same Docker/Xvfb setup plus Openbox, `tools/check-editor-ux.ts --chains` and both engines, output `/evidence/e11-chains-final2`. The existing generated regression uses `--generated`, only4.7, output `/evidence/e11-generated-regression`. Each runner requires a new absolute output directory; use a new suffix for reproduction. Actual command arrays/timings/engine authentication/source flags are in the retained JSON. Frozen/static checks ran locally before publication; routine CI is independent verification, not this investigation proof or release evidence.

Environment: owner-approved Docker `estragon-e04-local`, image `estragon-p02-linux-env:local`; read-only `/repo` and authenticated `/engines`, host `/tmp/e04-local` mounted `/evidence`; software OpenGL/Xvfb/Openbox, isolated self-contained editor settings, no checkout addon/preferences changed. Only official Linux4.0.4 SHA256 `e9a0db9798cf53385693898af39f98d0065552c0808b9e7eb82cfcb0da880ae9` and pinned4.7.0 `f85bbc6b15e22416c7d797cd60b63286dd67b9cb13498847056c18520ae55a75` were launched. Raw source/phase/error logs, manifests and rendered frames are retained, with [SHA256 artifact index](e11/artifact-index.json); archived logs normalize trailing whitespace only.

Manual interactive/macOS reproduction, other minors/platforms, full73/exhaustive suites and release certification/registry/publication were not run. Original macOS report is owner evidence; the precise Mac session trigger was not instrumented here. General native engine errors are not promised fixed. Accepted#44 and optional4.0 preflight/introspection differences remain; actual-path compiler validation/rollback and native editor error gates are unchanged. No private engine calls, forced hidden-tab activation, preference changes, version/tag/release/workflow/publish/merge or #145/#146/layout expansion. Review-ready evidence/tests/docs-only PR and issue handoff record final head/base/required CI; owner review/merge remains outstanding.
