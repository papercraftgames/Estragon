# S01 — shared local native 2D styling

Issue [#167](https://github.com/papercraftgames/Estragon/issues/167), base `5c70745`
(merged L07 #166). [Contract](../STYLING.md), [ADR-0020](../DECISIONS.md#adr-0020--local-native-2d-background-and-border-styling).
Implementation uses one Component2D-owned value/paint helper and the sole
Length/layout core. Native Nodes, transforms, input, lifecycle and composition
remain authoritative. No stylesheet, cascade, extra background Node, polling,
3D styling or S02–S04 widget/theme/advanced-visual implementation.

## Source and package provenance

Runtime/compiler/core code is unchanged from `5b09185`. Earlier clean regressions/package source is `4a59788`; extended focused runtime/editor source is `8a13e18`. Final source `a9b18d1a07bb93f7d2c6a60030ecb0d913b8c8f5` additionally clears stale Inspector invalid-color feedback after a valid update. Both focused styling and package gates were rerun on that clean source. Subsequent review commits only archive evidence/update documentation. The instance-based Play probe works on both approved engines. Every provenance file states actual clean source and
engine executable hash. Both official Linux 4.0.4 and pinned 4.7.0 use the same
unchanged direct-Yarn addon payload with65 canonical script UIDs, matching
source-content SHA256 `13ab5ea5edd3e40a43952b05983196bfbd11fd09520ba72cf57ce590e88a7d73`
and development tar SHA256
`fb279c2e02de4d4f6cf233c581b80394e9a0eaf83b99ccf1b23c72b84b46b300`.
These are development packages/local gate regressions, not published release
certification or authority to publish. Package bytes/UIDs remain unchanged after
Godot editor/import/Play. No copying, symlinking or .gdignore over node_modules.

## Final focused results

| Engine | Runtime | Exact native rejections | Editor | Restart | Direct Yarn / bytes |
| --- | --- | --- | --- | --- | --- |
| official Linux4.0.4 |79 PASS|18 PASS|13 PASS|8 PASS|PASS|
| pinned Linux4.7.0 |79 PASS|18 PASS|13 PASS|8 PASS|PASS|

[4.0 results](s01/acceptance/4.0.4/results.json), [4.7 results](s01/acceptance/4.7/results.json).

Runtime proves native Color/hex/transparent parsing and rejection, border units,
300px outer width →264px content at X12, shorthand/side order/auto, ordinary and
root percent references, natural measurement, safe zero size, derived `_draw`
foreground hook, pack/reload and exactly one hook after re-entry. All gallery
descendant IDs/parents/owners remain stable across resize. Native/Estragon
Buttons click and Estragon hover remains intact; Text retains local white/amber.
Dynamic invalid color/length/legacy-widget descriptions reject before committing;
invalid source preserves generated code/maps/cached Script and repairs normally.
Omitting a GGX border side restores shorthand on the retained Node.

At640×480 the panel is608×448 at(16,16), content565×405 and half-width Header282.5.
At1000×800 it is968×768, content925×725 and Header462.5. Returning to640 restores
geometry without recreation/recomposition. Native Buttons sit at(44,336)/(44,656);
Estragon Buttons at(172,336)/(172,656). Runtime registers three clicks each;
actual main/current games register two each at two sizes. Pixel assertions verify
root/panel/border colors. Actual captures were visually inspected:
[640](s01/acceptance/4.7/styled-640.png),
[1000](s01/acceptance/4.7/styled-1000.png),
[Inspector](s01/acceptance/4.7/inspector.png).

Both engines record identical counters: before/after the two color writes, Entry and panel measures/arranges remain4/4, Header8/4 and computation runs1. Panel draws7→8, color parses2→4 and native paint commands35→40. Equal writes add no parse/draw; the border update advances panel measures/arranges to5/5, draws9 and commands45. Subsequent idle frames change no counters. The unaffected intrinsic Text measure remains cached. [Exact4.7 runtime log](s01/acceptance/4.7/runtime.txt).

## Existing regression and package gates

Runtime/default-style regression evidence is clean `4a59788`, before the isolated color Inspector feedback fix; runtime/compiler/core bytes are unchanged. Final package gate evidence is clean `a9b18d1`:

- Linux4.7 native core18/runtime149 PASS; L01 Box68 PASS.
- Linux4.0.4/4.7 L06/L07 runtime195 each, exact native rejection checks and actual
  native root Exit quit PASS. Ordinary content/auto/proof/3D references remain
  unchanged; independent2D Entry percentages use the visible Viewport.
- Linux4.7 native Control57, Exit quit and three runnable example assertions PASS.
- Both engines: complete bounded seven-stage direct-Yarn package gate PASS
  (pack/install/build/import/runtime/editor/visual), runtime24/editor50 each,
  independent strict release assessor PASS. Same development tar on both engines.
- Pinned4.7 tiny routine native smoke PASS. Frozen install/static policy/typecheck30
  PASS at final `a9b18d1`.205 unique paired script UIDs; all three new maps
  authenticate exact sourceContent/generatedHash. No supplied Assets changed.

[Package assessments](s01/package/4.0.4/release-assessment.json),
[4.7 assessment](s01/package/4.7/release-assessment.json),
[static](s01/s01-static-review.txt),
[UID audit](s01/s01-audit.txt), [map audit](s01/s01-map-audit.txt).
Routine PR CI is independent; its link/timing is in the live PR/issue handoff.

## Exact commands and environment

Host Docker container `estragon-e04-local`, repository mounted read-only `/repo`,
`/tmp/e04-local` mounted as `/evidence`, isolated settings/PATH, Xvfb/Openbox,
GL Compatibility and Mesa llvmpipe. Engine executable paths:

- `/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64`
- `/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64`

The final focused invocation (both --engine selections above):

~~~sh
docker exec -w /tmp -e XDG_RUNTIME_DIR=/tmp/e04-runtime estragon-e04-local \
  xvfb-run -a sh -c 'openbox >/tmp/s01-review-final-openbox.log 2>&1 & exec corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-styling.ts --editor --engine 4.0.4=/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/s01-review-final'
~~~

The same Docker/Xvfb/Openbox prefix runs:

~~~sh
corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-native-addon.ts --fast-release --engine 4.0.4=/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/s01-package-review
~~~

[Exact sequential regression script](s01/regressions-command.txt) runs
check-node-runtime --runtime-only, check-box-model, check-lengths on both engines,
check-native-controls and check-routine-smoke; the others select4.7 only.
Host `bun install --frozen-lockfile` and `bun run check` are the retained tooling
checks; new runner is TypeScript through Yarn. The addon/editor/Play need only Godot.

## Retained failed development attempts and limits

- Initial68-assertion probe failed an overly strong cached percentage-sibling
  measurement expectation. The existing solver legitimately remeasures percent
  children while resolving changed context; acceptance instead checks the
  actually unaffected intrinsic Text leaf. No solver/cache policy was altered.
- Normal Box Inspector, direct Inspector edit and unnamed Box subclass selection
  on4.7 each reproduce the pre-existing inherited-relative-class icon diagnostic
  (`Class name cannot be empty`, native editor_node.cpp). These FAIL logs remain.
  The allowed participant-base API was chosen and the actual direct Node2D base
  supplies Inspector proof. No error whitelist, class-cache patch or fix claim.
  Box runtime/subclass/paint/compilation remain tested. Legacy Text/Rect/Button
  styles are explicitly rejected until S02; their existing painters are retained.
- Early negative-output per-error markers interleaved stdout/stderr. One complete
  bracket spanning deferred frames now counts exactly18 known errors and rejects
  unexpected diagnostics. A TypeScript regex escaping mistake was caught/fixed by
  typecheck before final acceptance. Both failures are archived.
- The first final4.0 build rejected static run.call_deferred on a Script; the test
  now defers a normal host method which holds/awaits a RefCounted probe instance.
  Next4.0 attempt rejected inferred Array typing on an untyped snapshot; explicit
  Array fixes the test. Neither changed production API or code.
- The added zero-paint test initially compared counters across a color update
  before deferred geometry had settled, counting a valid paint at the old extent.
  It now settles zero geometry, changes colors and checks no rectangles are drawn.
  The original failed79-assertion result is retained; no product behavior changed.

- Final screenshot review caught stale red color-entry feedback after a valid native picker update. Valid property refresh now clears it; an actual editor assertion verifies the transition on both engines. The original captures/results remain under development. The first follow-up correctly refused uncommitted evidence in the checkout; it was preserved outside the repo before clean-source reruns, with the refusal archived.

Original raw outputs remain under `/tmp/e04-local`. Archived logs are normalized
for trailing whitespace and renamed .txt; original result log names and package
hash manifests are preserved as provenance. [SHA256 archive index](s01/artifact-index.json)
authenticates the archived files; it is not a substituted release bundle.
No manual interactive Godot4.7 smoke, physical keypress, macOS/other platforms,
extra engine versions, full73 suite, tag, release, npm publication or merge ran.
Automated real editor/game graphics are separate from headless results. Fixed
children may still overflow tiny content; clipping/themes/unified widgets remain
future scope. Owner review/merge remains required.
