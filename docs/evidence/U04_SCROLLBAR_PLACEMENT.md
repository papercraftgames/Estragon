# U04 — border-edge scrollbar placement evidence

[Issue #224](https://github.com/papercraftgames/Estragon/issues/224) follows
owner-merged U03 PR #223, base `fc8931eb79dd769043a8129121ef183fb4edcea3`.
Paired tested implementation: `ce46bb9695f58a35bb2b56e4250abaa3540371b4` (clean). Final documentation/evidence
commits do not change tested executables. This is a development-package acceptance
run, not release certification or publication.

Only three production files change: the existing pure scrollbar geometry helper,
its core call site and service fallback. B positions chrome; P still resolves/caps
thickness, and V still supplies layout/clip/range. No extra placement formula,
measurement pass, option, style schema, content-inset model or 3D behavior is added.

## Numerical and rendered before/after

The same repository-owned `placement_baseline.gd` was run against unmodified base
addon bytes and the changed geometry. [Baseline provenance](../../tests/scrollbars/evidence/u04/baseline/provenance.json)
binds the fixture and engine, and verifies every base addon file. Compare
[before](../../tests/scrollbars/evidence/u04/baseline/before.png) and
[after](../../tests/scrollbars/evidence/u04/baseline/after.png), with adjacent logs.
The after-baseline is a focused dirty development capture; final paired images
qualify the clean committed source. No external GogoDemo or supplied Assets changed.

For outer400×300/border5/padding20, vertical12 only:

| Region | Before | After |
| --- | --- | --- |
| Child viewport | `(25,25,338,250)` | unchanged |
| Vertical track | `(363,25,12,250)` | `(383,5,12,290)` |
| Vertical range, content720 | 470 | unchanged |

With horizontal16 also enabled, V remains `(25,25,338,234)` and range `(262,486)`.
Vertical moves from `(363,25,12,234)` to `(383,5,12,274)`; horizontal from
`(25,259,338,16)` to `(5,279,378,16)`; corner becomes `(383,279,12,16)`.
The owner remains400×300 and padding separates V from chrome by20px. With5%
vertical thickness, P350 still resolves17.5, now positioned at377.5 beside B.right395.

## Native acceptance

| Stage | Official Linux4.0.4 | Pinned Linux4.7.0 |
| --- | --- | --- |
| U04 pure geometry28 / native44 | PASS | PASS |
| U03 geometry40 / native42 / retained GGX32 | PASS | PASS |
| L12 pure36 / native34 | PASS | PASS |
| Input52 / palette12 / frontend22 / rejection19 | PASS | PASS |
| Inspector9 / current+main invalid Play rollback, repair and successful Play | PASS | PASS |
| Editor17 / restart2 | PASS | PASS |
| Immutable direct-Yarn bytes/85 addon UIDs / six source maps+UIDs | PASS | PASS |

[Paired summary](../../tests/scrollbars/evidence/u04/paired/summary.json),
[4.0.4 results](../../tests/scrollbars/evidence/u04/paired/4.0.4/results.json) and
[4.7 results](../../tests/scrollbars/evidence/u04/paired/4.7/results.json) record the
exact source, commands, engine identities and outcomes. Both use tar SHA256
`e8447aeeb4bc669130bc9e65c2a3bffad218aee3d3af407732721d8d5a91b02b`. Both engines execute it directly in `node_modules`, without copying,
symlinking or hiding the addon. Every unexpected native error/leak fails the
collector; only exact existing rejection brackets are permitted. Installed addon
bytes and canonical script identities are checked after editor restart.

The new tests cover A/B exact rectangles, asymmetry, fractional P-based thickness,
0/1/2 axes, oversized/zero/tiny boxes, stable hidden gutters, hover/pressed pixels,
new-coordinate native drag and vertical/horizontal track clicks, old-track padding
band rejection, clickable content edges, nested wheel exhaustion, responsive Wrap,
unchanged unrelated branches, runtime target/flag/inset changes, custom texture
identity/minimum fitting/expansion clipping, GGX re-render/focus/caret/offset retention,
scene ownership/reload and settled idle without parsing/layout/style churn.
Editor proof edits real Inspector properties and uses the same native model to
verify border-edge placement; both current/main Play execute U04 native44 plus the
existing Input/L12/U03 probes. Native graphics are separate from headless math.

## Observed padding semantics (unchanged)

The fixed viewport is `(25,25,338,250)` and fixed vertical track `(383,5,12,290)`.
Measured content720 minus V.height250 gives range470, without new start/end inset
terms. At offsets0/235/470, first content top is25/−210/−445 and last bottom
745/510/275. All padding bands remain outside the fixed clip, including along-axis
padding. The content edges align V at start/end. Tracks/corner are not translated.
[4.0.4 observations](../../tests/scrollbars/evidence/u04/paired/4.0.4/u04-padding-observations.json),
[4.7 observations](../../tests/scrollbars/evidence/u04/paired/4.7/u04-padding-observations.json),
[start](../../tests/scrollbars/evidence/u04/paired/4.7/u04-offset-0.png),
[middle](../../tests/scrollbars/evidence/u04/paired/4.7/u04-offset-235.png),
[end](../../tests/scrollbars/evidence/u04/paired/4.7/u04-offset-470.png) and
[GGX](../../tests/scrollbars/evidence/u04/paired/4.7/u04-ggx.png) were inspected.
Raw observations are in each paired engine's `u04-padding-observations.json`;
`u04-offset-0/235/470.png` and `u04-ggx.png` provide rendered evidence.

The alternative conventional model where leading/trailing insets travel with
content and appear only near start/end is a **separate future owner-reviewed design
decision**. U04 does not select or implement it. [Current contract](../SCROLLING.md#u04--tracks-inside-border-outside-padding).

## Commands, provenance and limits

```sh
bun install --frozen-lockfile
bun run check
node --experimental-strip-types -e "import('./tools/audit-native-source.ts').then(m=>console.log(m.auditNativeSource()))"
# Container estragon-e04-local: /repo read-only; /tmp/e04-local -> /evidence.
COREPACK_ENABLE_PROJECT_SPEC=0 LIBGL_ALWAYS_SOFTWARE=1 LP_NUM_THREADS=2 xvfb-run -a \
  corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-input.ts \
  --border-scrollbars --proportions \
  --engine 4.0.4=/evidence/engine404/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/evidence/engine47/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/u04-review-proof
```

Frozen install, TypeScript/static30 and351 unique active script/UID audit PASS.
Existing generated identities are preserved; the four new fixture sidecars were
generated once through official Godot ResourceUID. Current source and paired
command/results/engine SHA/tar/file provenance are adjacent to this report's linked
fixture evidence.4.0 optional isolated preflight/symlink introspection remains
unavailable; mandatory actual-path validation and transactional rollback pass.
Only the two approved Linux engines were used; user project preferences/addon
activation were not changed.

Same implementation source: existing inherited-scroll regression
`tools/check-ux01.ts --scroll-only --engine 4.7=/evidence/engine47/Godot_v4.7-stable_linux.x86_64 --output /evidence/u04-scroll-regression`
through the same Yarn/Xvfb prefix PASS: native clipping/scroll/nested exhaustion,
scaled input, direct/Grid/Wrap inheritance, foreign rescue/ownership/reload, idle,
removed ScrollView invariant and package integrity. No full historical UX syntax
or release matrix is claimed; the earlier unrelated syntax-count mismatch remains
qualified in the historical L12 evidence.

A first native reload fixture used a participant without an Entry; it was corrected
to an independent Entry and passed. [Retained fixture failure](../../tests/scrollbars/evidence/u04/development/unscoped-fixture-failure.log).
This was fixture setup, not an engine limitation or product policy change.

**Manual interactive Godot4.7 smoke was not run. Actual OS pointer/IME, other
platforms/minors and measured-monitor DPI remain UNTESTED.** Synthetic native input,
headless checks and software-GL/Xvfb rendered captures are explicit. Physical
keypresses are not acceptance gates. Required PR CI and its60s execution-wall
measurement are recorded on the sole live PR. No workflow/gate, release/version,
publication or automatic merge change.
