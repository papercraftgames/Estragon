# UI-03 — editable Input and implicit String binding evidence

[Issue #199](https://github.com/papercraftgames/Estragon/issues/199), base owner-merged UI-02 PR217 at `1c4d892ca9c3bef4a6984df4d0ed53c831064de5`. Final clean native-tested source **`4641252c519f56304e704773c4d40ec0c95bcf94`**. Later evidence/documentation/status edits change no addon, example, fixture or collector bytes. Owner review/merge is required. [Input API and platform boundaries](../INPUT.md), [shared Bool/String binding](../TWO_WAY_BINDINGS.md).

## Final native acceptance — 2026-11-23

Only official Linux Godot **4.0.4** `fc0b241c9` and pinned **4.7.0** `5b4e0cb0f`. [Stage results](ui03/summary.json), [exact source/package manifest](ui03/package-manifest.json), [artifact SHA256 index](ui03/file-hashes.json).

| Check | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| Compiler, String metadata/typed writer, one-way paths, maps and negatives | 22 PASS | 22 PASS |
| Real native editing/clipboard/selection/focus, binding, geometry and idle | 47 PASS | 47 PASS |
| Atomic rejection/repair, model lifetime and packed/reloaded Input | 19 PASS | 19 PASS |
| Actual editor current/main invalid-source rollback, repair and Play | 8 PASS | 8 PASS |
| Cold editor restart and native game | 2 PASS | 2 PASS |
| Build/import, directly installed Yarn payload, maps/UIDs/unchanged bytes | PASS | PASS |

Both engines install the same reproducible development tarball, SHA256 **`32444f3de07865615dffa77d9e8f4ee45d757c49fc359d28d7d080428cd4d2fe`**. All **174 addon files / 83 addon script UIDs**, plus four package-root files, remain unchanged through editor/Play/restart. No package copy/symlink/ignore overlay or source-version change. This is development-package acceptance, not release certification.

The native LineEdit lives in the actual arranged/clipped Node2D ancestry. Its hit/focus rect includes padding, with transparent style insets placing native text/caret/selection inside the host's content rect. Tests exercise platform input (`Input.parse_input_event`): Unicode typing, Backspace/Delete/Home/End/Shift selection, copy/cut/paste, mouse drag selection, Enter/Escape, native GUI ownership before game fallbacks, read-only copy/edit rejection, disabled/hidden focus, shared Tab and keyed movement. An unrelated parent render retains the same Input/editor, caret and selection. Independent Input writes notify/write the model synchronously; source projection suppresses reciprocal writes while notifying observers. Equality, one-way snapshots/computed/plain/read-only/Dictionary sources, parameter paths, reentrancy, replacement/null/stale callbacks/unmount and idle-zero are checked through the existing manager.

Native Box/Grid geometry and ancestor clip hit rejection pass. A directly authored Input packs its exported String and reconstructs exactly one private editor; Gogo-managed output similarly reconstructs one binding. The endpoint has no scene owner or layout adapter; no reconciliation metadata is injected on application Nodes.

Five exact bracketed dynamic/null preflight failures retain the whole previous native view and repair. Editor current Play rejects removed bind:* syntax; main Play rejects a Bool placeholder expression through actual native String semantics. Code/maps/UID/timestamp/cached Script identity roll back before repaired native games run. The collector permits only the exact Bool-as-String diagnostics in that deliberate block plus exactly two build-callback failures. Unexpected errors/leaks fail. On4.0 optional isolated preflight/logger precision is unavailable: native diagnostics identify generated code and the authored fallback points to `app/Inputs.gogo:1:1`; mandatory actual-path validation/rollback still passes. Current source maps/UIDs are checked independently.4.7 reports the mapped placeholder location.

## Rendered proof and limits

Inspected actual native captures: [4.0.4 / 640px](ui03/4.0.4/input-640.png), [4.0.4 / 1000px](ui03/4.0.4/input-1000.png), [4.7.0 / 640px](ui03/4.7/input-640.png), [4.7.0 / 1000px](ui03/4.7/input-1000.png). They show editable values, retained native caret/selection and focus outline, placeholder/invalid/read-only/disabled states, Grid placement and real ancestor clipping. Headless parsing alone is not this rendering/editing proof.

Both engines report X11 / native IME capability. **Actual OS IME composition/candidate interaction is UNTESTED under Xvfb**; synthetic Unicode is not composition proof. Native LineEdit owns that platform path in the real rect. **Manual interactive Godot4.7 smoke was not run.** No mobile/virtual-keyboard, accessibility, password, multiline, extra engine/platform or physical-key gate is claimed.

## Commands and source qualification

Container `estragon-e04-local`: repository read-only `/repo`, host `/tmp/e04-local` → `/evidence`. Only isolated project/settings/plugin activation; root checkout preferences unchanged.

```sh
bun install --frozen-lockfile
bun run check
node --experimental-strip-types -e "import('./tools/audit-native-source.ts').then(m=>console.log(m.auditNativeSource()))"
COREPACK_ENABLE_PROJECT_SPEC=0 LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a \
  corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-input.ts \
  --engine 4.0.4=/evidence/edit01-engines/godot-verified- 4.0.4/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/evidence/edit01-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/ui03-acceptance-final-2
COREPACK_ENABLE_PROJECT_SPEC=0 LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a \
  corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-core-reactivity.ts \
  --engine 4.7=/evidence/edit01-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/ui03-core-regression
```

Frozen install and TypeScript+**30 policies PASS** ([install](ui03/install.log), [static](ui03/static.log)); **330 active scripts / 330 paired unique UIDs** ([audit](ui03/audit.log)). All65 authored modules/maps match native regeneration; the prior63 modules remain unchanged.

Relevant Linux4.7 shared-layer regressions pass at clean `4c59312`: [two-way41](ui03/regressions/twoway.log), [bindable95](ui03/regressions/bindable.log), [nativeUI32](ui03/regressions/native_ui.log), [focus42](ui03/regressions/focus.log), [native compiler70](ui03/regressions/nativefrontend.log), [Bool frontend21](ui03/regressions/checkboxfrontend.log), and CORE-01 [frontend15](ui03/regressions/core/frontend.log)/[runtime11](ui03/regressions/core/runtime.log)/[integration65](ui03/regressions/core/integration.log). Shared compiler/binding/focus/layout bytes match the final source; the sole subsequent production difference is Input-only border-box skin geometry, covered by final paired UI-03 acceptance. [Exact regression commands, engine hash and byte comparison](ui03/regressions/provenance.json), [CORE provenance](ui03/regressions/core/provenance.json). NativeUI's two bracketed width/gap errors and Bool frontend's three bracketed unknown-identifier errors are deliberate; backend warnings remain visible.

## Retained development failures

- A focused native process ended without its completion marker during concurrent development runs; cause was not established and this is not a PASS. [Partial log](ui03/development/incomplete-focused-game.log), [failed result](ui03/development/incomplete-focused-results.json). Final source completes all stages and shutdown on each approved engine.
- Actual4.7 editor assertions passed but the collector initially rejected deliberate Bool-as-String diagnostics. The bounded exact filter now recognizes only those native/mapped errors inside the rejection block. [Failure](ui03/development/typed-rejection-results.json), [log](ui03/development/typed-rejection-filter-failure.log).
- 4.0 completed native editing but exceeded the inherited15-second game-marker wait, causing a false fixture failure. The Input fixture now bounds its longer delivered-frame/capture sequence at45seconds and the full editor stage at180seconds; assertions and routine CI were not weakened. [Failure](ui03/development/native40-game-deadline-results.json), [log](ui03/development/native40-game-deadline-failure.log).
- Initial unstaged package checks correctly rejected a tracked catalog reference to an untracked new Input file. Staging the actual package source restores all30 policies; no packaging guard was bypassed. [Failure](ui03/development/untracked-package-policy-failure.log).
- 4.0 could not infer the return type of the selection convenience method used by the fixture; tests now use supported selection-column APIs, with no production shim. [Fixture failure](ui03/development/native40-selection-fixture-failure.log). Initial map-accessor and native clip-child-path fixture mistakes were corrected before acceptance.

The live PR records independent required CI and its60-second budget measurement. No workflow/version/release/publication/Assets/GogoDemo change, automatic merge or successor implementation.
