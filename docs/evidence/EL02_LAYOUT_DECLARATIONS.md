# EL02 — native lexical layout declarations

Issue [#192](https://github.com/papercraftgames/Estragon/issues/192), base owner-merged
D07 `23ce784b61a9b9164aafa009a72c4bc61ce3ff1f`. Implementation `05c9445`, complete
paired installed acceptance `7a20dd1`; final gallery refinement `0a05408` changes
only example sources/generated maps and the visible exported-child game assertion.
Production addon payload hashes are identical between these acceptance sources.
[Contract and exact native lowering](../LAYOUT_DECLARATIONS.md).

Full paired acceptance uses `tools/check-layouts.ts --editor` on official Linux
4.0.4 `fc0b241c9` and pinned4.7.0 `5b4e0cb0f`: **frontend69/runtime30/editor31/
cold-restart7 PASS per engine**. Build, import, whole-source maps, stable canonical
UIDs and unchanged directly installed package bytes PASS. Invalid source is tested
for both actual Play paths with original code/maps/timestamps/cache identity
preserved; repair saves current buffers before game execution. Dynamic invalid
preset defaults reject a whole transaction and repair through real signals.
Native geometry/input/borrowed projection/owners/removal/pack and quiet counters
are actual engine tests, not compiler-only claims.

The gallery refinement supplies existing `rows=["1fr","1fr"]` to the exported
nested Grid (empty auto rows otherwise correctly measure zero) and makes Toggle
label width explicit. Focused paired `--editor-only` acceptance tests those final
example bytes, real visible child height, native clicks at640/1000 and restart;
both engines PASS editor31/restart7, and all four final captures were visually
inspected. The identical159-file addon payload preserves all74 addon UIDs; see
the committed per-run results for the exact outcome. Original zero-height
captures and successful earlier acceptance are retained as history.

## Commands and provenance

Run in the existing Linux container, with isolated per-consumer settings and
software graphics. No macOS Godot or other engine version was launched.

```sh
COREPACK_ENABLE_PROJECT_SPEC=0 LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a corepack yarn@1.22.22 node --experimental-strip-types tools/check-layouts.ts --editor --engine 4.0.4=/evidence/s03-engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/evidence/s03-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/el02-final-pair
COREPACK_ENABLE_PROJECT_SPEC=0 LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a corepack yarn@1.22.22 node --experimental-strip-types tools/check-layouts.ts --editor-only --engine 4.0.4=/evidence/s03-engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/evidence/s03-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/el02-final-gallery
bun install --frozen-lockfile
bun run check
```

Frozen install/static checks PASS: TypeScript +30 policy tests. All298 committed
script UID pairs are unique; all three authored gallery maps match source content.
Generated canonical files came from isolated real-Godot bundled compilation, not
manual rewriting. Full installed payload hashes, exact tar/source/engine hashes,
commands and map proofs are in [the evidence directory](../../tests/layouts/evidence).
These are development packages, with `0.0.0-dev`; no release overlay, tag, registry
publication or release certification was requested/performed.

## Scoped existing regressions

Pinned4.7 only, separate fresh isolated consumers; complete suites were not repeated
on every development edit. Relevant source output/regression results are committed.

| Check | Actual result |
| --- | --- |
| Responsive Grid/Wrap | frontend21/math95/runtime44 and rendered/input/pack proof PASS |
| Native Controls | build/runtime57/Exit/examples PASS |
| Styling | negative/runtime158 PASS |
| S04 surfaces | defaults/negative32/runtime43/Play/immutable PASS |
| UX01/U02 | syntax/maxima/scrolling/nested/native/negative/gallery/inherited/removal PASS |
| S03 spreads | frontend/publication/negative/runtime28 PASS |
| Native Node runtime/shared3D | core/runtime/import/editor1/editor2 PASS |
| GGX | build/runtime55/editor89 PASS, internal output-path retry below |
| Counter | build/runtime32 PASS; legacy full editor highlighter probe FAIL, baseline reproduction below |

The unchanged Grid/Wrap math test explicitly verifies parent-content percentages
rather than cell percentages. EL02 preserves that shipped contract despite #192's
cell-relative illustrative wording; it never converts child width to a track.

## Retained failures and limits

- First full paired attempt at05c9445:4.0 frontend68/69, lifetime assertion FAIL.
  Native4.0 retains a property getter receiver temporary until the caller returns.
  A helper returning the weak reference/exported preset proves actual model release
  after the native stack unwinds on both engines. Runtime weak method Callables
  were unchanged; this test correction is7a20dd1. The original FAIL is retained.
- Development probe demonstrated lambda/self reference cycles on RefCounted owners;
  module defaults now use weak native method Callables. Local defaults retain normal
  GDScript lexical closure semantics. Disposed default owners reject safely.
- Native Inspector pack/reload initially restored areas before tracks and rejected
  an intermediate invalid configuration. Ordered Grid storage fixes this; final
  actual native Inspector edit/undo/save/reload passes both engines.
- Initial gallery geometry assertions assumed cell percentages and ignored intrinsic
  text floors; corrected to the existing native contract. String color storage is
  validated through the real parsed color getter. Borrowed scene children preserve
  native parentage and use external logical projection; they are not reparented.
- First Counter/GGX collectors failed `EACCES chmod` copying files to a Docker host
  bind mount. Retrying unchanged collectors with container-internal output removes
  that environment failure. GGX fully passes. Counter runtime32 passes; full editor
  reports nine legacy hard-coded fallback-color assertions. The same nine failures
  reproduce on unchanged base23ce784 with native highlighting active, so they are
  documented as an existing test/native-color mismatch, not relabeled PASS.
- An interim editor development probe shared a mutable project with another probe;
  its game timeout is invalid evidence and not claimed PASS. Final acceptance uses
  fresh independent installed projects with immutable source throughout each run.
- 4.0 optional isolated-preflight and symlink introspection report BLOCKED as before;
  mandatory transactional actual-path native validation/rollback passes. Exact
  semantic diagnostic location degrades normally where native Logger is absent.
- Only typed two-part host-instance exported preset tags are supported; native
  qualified component types use explicit preload aliases. Exports are instance
  properties, not ES module/static constructors. Inner-class layout declarations
  diagnose the existing hybrid restriction. EL01 responsive recipes/visual designer,
  general style systems and new layout engines are outside this implementation.

Manual interactive visual smoke was not run. Automated real native editor/game/
pointer/rendered proof ran; selected final captures were visually inspected.
No physical keypress test, exhaustive73-stage release suite, additional engine/
platform, account/release/workflow/version/publishing change or merge occurred.
The PR remains **In review** until owner review/merge; routine CI is independent
verification and is not release certification.

The evidence directory is narrowly Godot-ignored because it contains archived
native logs/JSON/captures only. Live `.gd` fixtures remain outside that directory
and run normally. No supplied assets or native asset import settings were changed.
