# UI-01 — native focus, keyboard and text-delegate evidence

[Issue #197](https://github.com/papercraftgames/Estragon/issues/197), base owner-merged EDIT-01 PR #215 at `c27cf6d2ae7fa617be1bb1415bd0527edae986fc`. Final clean native-tested implementation **`1e5599dcad20bf41fb73e3f061177c0f61d274bb`**. Later documentation/evidence/status edits change no addon, example, fixture or collector bytes. Owner review/merge remains required. [Contract and prototype decision](../FOCUS_KEYBOARD.md).

## Final acceptance — 2026-11-23

Only official Linux Godot **4.0.4** `fc0b241c9` and pinned **4.7.0** `5b4e0cb0f`; the entire final run passes on each, including shutdown and immutable installed payload checks. [Stage results](ui01/summary.json), [exact source/package manifest](ui01/package-manifest.json), [artifact SHA256 index](ui01/file-hashes.json).

| Check | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| Real mixed native runtime: pointer/key/focus/text/clip/lifetime/pack | 42 PASS | 42 PASS |
| Compiled Gogo retained game: native identity/focus/editing/model ownership | 14 PASS | 14 PASS |
| Actual editor current/main rejection/rollback/repair/Play | 8 PASS | 8 PASS |
| Cold editor restart and native game | 2 PASS | 2 PASS |
| Build/import, direct Yarn, current source maps and stable UID | PASS | PASS |

One reproducible development tarball was installed directly in `node_modules` on both engines: SHA256 **`8910181fd3277f2a2ec0bc1e60d6582f7c1bb3abf7cceb90b7c96ca8f7b886b3`**. All **168 addon files / 80 addon script UIDs**, plus the four package root files, remain byte-identical after editor/Play/restart. No addon copy/symlink/ignore overlay. Existing optional4.0 preflight/symlink introspection remains BLOCKED, with mandatory transactional actual-path validation successful; this is not relabelled optional capability support.

## What the tests prove

Actual platform input (`Input.parse_input_event`, delivered over native frames) exercises pointer-to-native focus, mixed Tab/Shift-Tab across separate GUI roots and Entries, authored native `focus_next`, click-only/none modes, disabled/hidden skips, repeat-safe press/release, Escape/Window/focus-loss cancellation, native Button activation and native Unicode/select-all/clipboard text edits. A raw custom key prototype receives unhandled text when unfocused, but native-handled editing/activation presses do not also reach it. Native releases/unrecognized keys retain native dispatch, not a claim of universal swallowing.

Native GUI wins over overlapping Estragon pointer rectangles; a native PASS Control that accepts only release cancels pending custom capture without a stale click. Overlapping Entries resolve one capture using native CanvasLayer, inherited Z and tree order. Native scene ancestry is preserved. No parallel mouse/key signals are synthesized for native Controls.

Scroll tests assert exact layout-sized, zero-origin focus rectangles with **no acquired Control layout adapter**. Partly clipped targets remain eligible, fully clipped targets refuse focus/Tab, and scrolling a focused rectangle out of view releases focus eventfully. SubViewport traversal is separate and uses Godot's native focus rules. Native reorder, removal/reentry and queued teardown leave no stale focus registration or SceneTree subscription. Packed authored controls recreate exactly one runtime-only endpoint. Settled frames do no focus refresh work.

The real compiled Gogo game runs at640×480 and1000×700, retaining focused Node/endpoint identity through parent rerender and resize. Keyed reorder keeps focus, and new tree order determines traversal. A real native Button activates exactly once. The visible native LineEdit delegate retains text, caret, selection, focus and actual parent through parent rerender. Its owner remains null. Removing a focused branch mid-key cancels without a stale callback; keyboard Toggle editing uses existing controlled Bool binding. Idle frames do no recomposition.

Real editor main/current Play blocks malformed unsaved Gogo and retains the previous code/maps/UID/timestamp/cached Script. Repair saves the latest authored buffer and runs the native game through both entrypoints. Cold restart repeats native focus/editing/retention proof. Final sourceContent/generatedHash/sourceName and canonical authored UID are checked after shutdown. The runner permits exactly two bracketed deliberate `An EditorPlugin build callback failed` errors in the first editor stage; all other native errors/leaks fail.

All eight final captures were inspected: [4.0 runtime clip/focus](ui01/4.0.4/focus-runtime.png), [640](ui01/4.0.4/focus-game-640.png), [1000](ui01/4.0.4/focus-game-1000.png), [retained text selection](ui01/4.0.4/focus-text-delegate.png); [4.7 runtime](ui01/4.7/focus-runtime.png), [640](ui01/4.7/focus-game-640.png), [1000](ui01/4.7/focus-game-1000.png), [retained text selection](ui01/4.7/focus-text-delegate.png). Visible focus aligns with the border-box and clips with native content; text selection/caret use native LineEdit presentation.

## Text/IME boundary

Both approved engines pass the native text prototype and report X11 / `DisplayServer.FEATURE_IME=true`. **Actual OS IME composition/candidate interaction is UNTESTED under Xvfb.** Synthetic Unicode is text-entry proof, not composition proof. Native LineEdit owns the OS/platform editing path; the example keeps it visible in the real allocated/clipped scene rect. The bounded raw-key alternative only appends Unicode and does not provide native selection/clipboard/IME services. [Documented comparison/decision](../FOCUS_KEYBOARD.md#text-editing--ime-decision-and-prototype) selects native delegation for UI-03 without shipping an Input widget or String binding here. Runtime delegates are owner-null, excluded from layout/reconciliation/persistence, and recreated on mount. New mounts start from authored initial text.

**Manual interactive Godot4.7 smoke was not run.** No macOS/mobile/extra engine, physical keypress, real OS IME or full Input/accessibility claim is made.

## Commands, regressions and provenance

Container `estragon-e04-local`: repository read-only `/repo`, host `/tmp/e04-local` → `/evidence`. Only isolated editor settings/projects/plugin activation. Engine identities/hashes are authenticated by the existing pinned-engine tools and recorded in per-engine provenance/results.

```sh
bun install --frozen-lockfile
bun run check
COREPACK_ENABLE_PROJECT_SPEC=0 LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a \
  corepack yarn@1.22.22 node --experimental-strip-types tools/check-focus.ts \
  --engine 4.0.4=/evidence/edit01-engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/evidence/edit01-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/ui01-acceptance-final-2
```

Final source TypeScript + **30 policy tests PASS** ([static log](ui01/static.log)); frozen install PASS ([log](ui01/install.log)); **314 active scripts / 314 paired unique UIDs** ([audit](ui01/audit.log)). Existing final-source Linux4.7 Counter/nativeUI32, nativeControls57 and inherited scrolling50 checks PASS. Counter's exactly two bracketed invalid-width/gap diagnostics are intentional; no unexpected errors/leaks in those runs. [Regression commands, exact addon hashes and source qualification](ui01/regressions/provenance.json), [Counter](ui01/regressions/native_ui.log), [native Controls](ui01/regressions/native_controls.log), [scrolling](ui01/regressions/ux01.log). Their isolated native-Control/inherited fixtures were prepared using existing source/build tools; no test harness was enabled in the root checkout.

## Retained development failures

- Accepting native `gui_input` before native BaseButton processing suppressed activation. The shared Entry shortcut phase now consumes the remaining accept only **after** GUI; actual activation stays native. [FAIL](ui01/development/native-gui-early-accept-failure.log).
- Godot4.0 child-entry notification exposed the newly added private Control to the layout adapter before internal-child bookkeeping completed, offsetting it by14/8 button padding. The existing coordinator now rejects explicitly private children before adapter acquisition; scrolling also excludes them from content adoption. Zero-origin/no-adapter and clip assertions pass on both engines. [Before geometry/FAIL](ui01/development/native40-layout-delegate-offset-failure.log).
- The Gogo example helper's bare event receiver resolved through a native4.0 lambda without its instance; `self.clicked` is explicit. No compiler compatibility path was added. [FAIL](ui01/development/native40-helper-callable-failure.log).
- A temporary RefCounted probe did not stay alive across native4.0 awaits. The fixture now holds it in a local. [Incomplete, terminated development log](ui01/development/native40-temporary-probe-incomplete.log), not a PASS.
- The first paired attempt reached an existing C++-only `get_parent_item()` call when the new overlap test exercised Z comparison. Public parent/top-level queries now implement that ancestry, with shared CanvasLayer/Z/tree ordering. Its release fixture also wrongly assumed showing an overlay transfers native mouse capture; the final fixture explicitly accepts release on the real native mouse owner. [Retained FAIL](ui01/development/native40-public-api-and-release-fixture-failure.log).

Earlier `Viewport.push_input` tests omitted4.0 unhandled delivery; actual platform-dispatched final tests cover both phases without a production engine shim. Initial regression setup attempts without the expected generated Home/InheritedScrolling fixtures or isolated PATH were failures, not product PASS evidence. No workflow/version/release/publication/Assets/GogoDemo changes, automatic merge or successor work. Required routine PR CI is recorded on the live review PR.
