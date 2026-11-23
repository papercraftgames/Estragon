# UI-02 — Checkbox and implicit Bool binding evidence

[Issue #198](https://github.com/papercraftgames/Estragon/issues/198), base owner-merged UI-01 PR #216 at `4d6081ff06d37b765ad94280ab8abf041b30a1cf`. Clean native-tested implementation **`1c73a421c084b64728fe3d40eb76306759a34e26`**. Subsequent evidence/documentation/status edits change no addon, example, fixture or collector bytes. The PR requires owner review/merge. [Checkbox API](../CHECKBOX.md), [implicit Bool contract](../TWO_WAY_BINDINGS.md).

## Final native acceptance — 2026-11-23

Only official Linux Godot **4.0.4** `fc0b241c9` and pinned **4.7.0** `5b4e0cb0f`. [Per-stage results](ui02/summary.json), [immutable package/source manifest](ui02/package-manifest.json), [artifact SHA256 index](ui02/file-hashes.json).

| Check | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| Compiler, original native expressions, snapshots/paths/maps/negative syntax | 21 PASS | 21 PASS |
| Rendered native pointer/key/focus, model ownership, keyed geometry, idle | 27 PASS | 27 PASS |
| Atomic dynamic/null rejection, repair, pack/reload/lifetime | 16 PASS | 16 PASS |
| Actual editor current/main invalid-source rollback, repair and Play | 8 PASS | 8 PASS |
| Cold editor restart and native game | 2 PASS | 2 PASS |
| Build/import, direct Yarn, current maps and unchanged installed bytes/UIDs | PASS | PASS |

Both engines install the same development tarball, SHA256 **`75e0aed7eb9f705179074a539a0680dc573ebdde39db6b7b0413c8238c605542`**. All **170 addon files / 81 addon script UIDs**, plus four package-root files, remain unchanged through editor/Play/restart. No package copy, symlink or ignore overlay. Existing optional4.0 isolated preflight remains unavailable; mandatory actual-path validation and transactional code/maps/UID/timestamp/cache rollback pass. This is development-package proof, not release certification.

Native input uses `Input.parse_input_event` across real GUI/unhandled phases, not physical-key interaction. Pointer and repeat-safe focused keyboard activation occur once; cancel/disabled/hidden cannot edit. Tests cover independent programmatic value notifications, synchronous source updates, no automatic projection writeback, equality, reentrant restoration, one-way snapshots/computed/plain/read-only/Dictionary values, parameter paths, model replacement/stale callbacks/null/unmount, retained keyed focus, natural Box/Grid/Wrap sizes, local label styling, pack reconstruction and zero idle composition work. The shared UI-01 focus42 regression retains native clipping/scroll and mixed-Control ownership coverage.

The frontend deliberately brackets three native parse errors for one undefined identifier; exactly those diagnostics are allowed. Five runtime preflight failures retain the whole previous tree and repair; both invalid Play paths deliberately emit the native build-callback rejection. Unexpected errors fail the collectors. The inherited4.0 signal-type bridge reads the real base declaration; no second manager or scheduler was introduced.

## Visual inspection and limits

Actual engine-rendered captures were inspected at [4.0.4 / 640px](ui02/4.0.4/checkbox-640.png), [4.0.4 / 1000px](ui02/4.0.4/checkbox-1000.png), [4.7.0 / 640px](ui02/4.7/checkbox-640.png) and [4.7.0 / 1000px](ui02/4.7/checkbox-1000.png). They show square/checkmark and label, distinct Toggle presentation, local label styling, disabled state, retained keyed focus ring and Box/Grid/Wrap geometry.

**Manual interactive Godot4.7 smoke was not run.** Actual OS IME composition is untested and out of scope; no String Input, extra engines/platforms, physical-key gate or full release claim.

## Exact commands and regressions

Container `estragon-e04-local`: repository read-only `/repo`, host `/tmp/e04-local` mounted at `/evidence`; isolated projects/settings and plugin activation only.

```sh
bun install --frozen-lockfile
bun run check
node --experimental-strip-types -e "import('./tools/audit-native-source.ts').then(m=>console.log(m.auditNativeSource()))"
COREPACK_ENABLE_PROJECT_SPEC=0 LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a \
  corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-checkbox.ts \
  --engine 4.0.4=/evidence/edit01-engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/evidence/edit01-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/ui02-acceptance-final-2
COREPACK_ENABLE_PROJECT_SPEC=0 LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a \
  corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-core-reactivity.ts \
  --engine 4.7=/evidence/edit01-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/ui02-core-regression-final
```

Frozen install and TypeScript + **30 policy tests PASS** ([install](ui02/install.log), [static](ui02/static.log)); **320 active scripts / 320 paired unique UIDs** ([audit](ui02/audit.log)). Relevant latest-source Linux4.7 regressions pass: [two-way41](ui02/regressions/twoway.log), [bindable95](ui02/regressions/bindable.log), [nativeUI32](ui02/regressions/native_ui.log), [focus42](ui02/regressions/focus.log), [native compiler70](ui02/regressions/nativefrontend.log), and CORE-01 [frontend15](ui02/regressions/core/frontend.log)/[runtime11](ui02/regressions/core/runtime.log)/[integration65](ui02/regressions/core/integration.log). CORE collector records exact clean source/engine commands and hashes; other regression commands/provenance are [recorded here](ui02/regressions/provenance.json). NativeUI's two bracketed invalid-width/gap diagnostics are deliberate; backend V-Sync warnings remain visible.

## Development failures and corrections

The initial candidate needed inherited signal declaration recovery on4.0; its optional native metadata reports typed arguments as NIL on the leaf Script. Both final engines pass. A temporary awaited probe needed a retained local on4.0. These were corrected rather than adding alternate event/binding paths.

An old two-way test expected an independent control assignment to remain local; the new API requires synchronous model notification and both observing peers to rerender once. [Retained old expectation failure](ui02/development/twoway-old-expectation-failure.log). Final41 passes. A native negative fixture initially assumed `self.missing` was statically invalid, but native GDScript permits dynamic self members; the corrected negative uses an undefined root identifier. [Retained fixture failure](ui02/development/native-self-dynamic-fixture-failure.log). An initial final regression invocation omitted bindable's required no-tools PATH and failed its environment assertion; the correctly isolated final95 passes. A native compiler setup attempt without the generated class cache failed; isolated import restores final70. These setup/development failures are not product PASS evidence.

The earlier complete paired run at `d15de0a` was superseded after source-expression/Dictionary correctness review. Final evidence above is qualified to `1c73a42`; the sole PR's required CI and its60-second budget measurement are recorded on the live PR. No Assets/GogoDemo/workflow/version/release/publication change, automatic merge or successor work.
