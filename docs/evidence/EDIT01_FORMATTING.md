# EDIT-01 — native Gogo indentation acceptance

Issue [#196](https://github.com/papercraftgames/Estragon/issues/196), from owner-merged CORE-01 PR #213 at `9ad0abcf2abcd59735d2f833b0c6827d41bc03b2`. Final native acceptance used clean **`9a1368788e53e2b8c38311c3bf52aa8641a51fed`**; subsequent evidence/status edits change no addon, fixture or collector bytes. This is a review candidate until owner merge. [Behavior and bounds](../GOGO_FORMATTING.md).

## Final acceptance — 2026-11-22 local / November 23 UTC logs

Only official Linux **4.0.4** `fc0b241c9` and pinned **4.7.0** `5b4e0cb0f` were used. Every final stage passes on both engines, including shutdown. [Exact results](edit01/summary.json), [source/package manifest](edit01/package-manifest.json), [artifact SHA256 index](edit01/file-hashes.json).

| Check | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| Grammar, literals/rows, idempotence and actual compiled semantic parity | 56 PASS | 56 PASS |
| Native CodeEdit carets/selection/scroll/dirty/undo safety | 15 PASS | 15 PASS |
| Real Script dock menu, Ctrl/Meta shortcuts, isolation, Play and repair | 26 PASS | 26 PASS |
| Cold editor restart and actual rendered Play | 2 PASS | 2 PASS |
| Build/import, direct Yarn, source maps, stable UIDs, installed bytes | PASS | PASS |

The native formatter covers the owner's original Cmd+I example, actual Home/Layouts/Core sources, GDScript suites and comparisons, paired/self-closing tags, multiline attributes/strings/comments, spreads and interpolated child expressions, delimiters and layout matrices. The owner's historical fill properties are a **syntax-only reproduction**, not restored runtime APIs. Original and formatted native compiled functions produce equal desired descriptions across conditional branches with literals, spreads, layout placement and bindable getters, using both two-space and tab formatting.

The native CodeEdit tests assert exact mapped columns for reversed selections and secondary carets, fractional vertical/horizontal scroll, separate prior user edits, one Undo/Redo, return to the saved version, clean no-op behavior and refusal before any caret merge. The real editor fixture activates Godot's Tools popup by its native `index_pressed` signal and sends Ctrl/Meta key events through its viewport. It checks the active unsaved tab, configured tabs/two-space width, ordinary/generated/multiple tab isolation, disable/re-enable and restart. It does not call the command directly as a substitute for menu/shortcut proof.

Baseline Play and formatted current/main Play run the same native layout probe at640×480 and1000×800: geometry and Node identity remain valid, two actual native button clicks are counted and two toggle edits restore false. Rejected malformed Play retains code/maps/UID/timestamp/cached Script; repaired formatted Play saves the latest buffer and produces matching map sourceContent/generatedHash. The collector allows exactly two bracketed `An EditorPlugin build callback failed` errors for those deliberate rejections; any other native error/leak fails.

One reproducible development tarball, SHA256 **`20cb3cf1526c5b301a15cb44b059ec0a1789c48202ab641abbcfbb506dfeac3f`**, was installed directly with Yarn into `node_modules` on both engines. All **163 addon files / 78 canonical addon UIDs** and the four package root files remain byte-identical after editor/Play/restart. No copy, symlink or ignore overlay hides the installed addon. Final source audit: **305 active scripts, 305 paired unique UIDs**. Frozen Bun install and TypeScript checking + all30 policy tests pass; [raw static log](edit01/static.log), [audit](edit01/audit.log).

All six final captures were inspected: [4.0 Script dock](edit01/4.0.4/format-editor.png), [640](edit01/4.0.4/layout-game-640.png), [1000](edit01/4.0.4/layout-game-1000.png), [4.7 Script dock](edit01/4.7/format-editor.png), [640](edit01/4.7/layout-game-640.png), [1000](edit01/4.7/layout-game-1000.png). **Manual interactive Godot4.7 smoke was not run**; no physical keypress or macOS validation is claimed. Meta is exercised through real Linux native input events.

## Reproduction

Container `estragon-e04-local`, repository mounted read-only at `/repo`, host `/tmp/e04-local` mounted at `/evidence`; isolated engine settings, projects and plugin activation only. Both binaries were authenticated by the existing pinned/hash-verifying `tools/download-compat-engine.ts`. Original binary hashes, exact commands/timings and source qualification are retained per engine.

```sh
bun install --frozen-lockfile
bun run check
COREPACK_ENABLE_PROJECT_SPEC=0 LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a \
  corepack yarn@1.22.22 node --experimental-strip-types tools/check-formatting.ts \
  --engine 4.0.4=/evidence/edit01-engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/evidence/edit01-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/edit01-acceptance-final
```

## Retained failures and limits

- The first editor fixture failed native parsing of an inferred variable before assertions; an explicit String type fixes the fixture. [FAIL log](edit01/development/fixture-type-failure.log).
- An early fixture emitted Tools `id_pressed` rather than native `index_pressed`, so it failed menu/undo assertions. Its manually changed per-buffer indentation also disagreed with native generated-script save-conversion settings, producing a shutdown mixed-indentation error. The corrected fixture configures its **isolated** native settings consistently, while exercising per-buffer tabs and widths; it checks all installed/generated bytes after shutdown. [FAIL log](edit01/development/menu-signal-and-settings-failure.log).
- The first paired attempt wrongly assumed `select()` always moves the caret to its last endpoint. Godot4.0 and4.7 differ; the fixture now captures actual pre-command caret/selection state and verifies preservation. That attempt also emitted native `!texture` and exited abnormally. [Retained FAIL](edit01/development/native40-selection-and-texture-failure.log). A fresh isolated final attempt has no unexpected native errors or shutdown leaks on either engine. This does **not** claim to fix the native texture/startup fault or historical#148.

Leading indentation only; whole buffer rather than selected-region reflow. Ambiguous suites/incomplete delimiters are refused; save/Play remains the native semantic validator. Multiline literal content and blank-line whitespace are retained. No release certification, extra engine/platform, full73 suite, Assets/GogoDemo change, workflow/version/publication action, merge or successor work is claimed. Required routine PR CI is tracked in the live review PR.
