# U02 inherited scrolling verification

Owner [#185](https://github.com/papercraftgames/Estragon/issues/185) corrects
merged UX01 PR #184. [Current contract and migration](../SCROLLING.md), ADR-0027.
Implementation `815f1067f0bb029cb4956bd4817f1f82a78f630d`; final harness/paired
source `1c211440c51913c4b1794595eab62c2d881dec51`; base
`6b1de9752a41939228ff646ad487ca3f84b3f0f1`. Subsequent evidence/status changes
do not alter the tested addon. This is review-ready work, not merged completion.

## Immutable installed acceptance

Official Linux Godot 4.0.4 and pinned Linux Godot 4.7.0 each pass all **18 stages**
of the existing UX01 collector. Both install the same reproducible tarball via
direct Yarn into `node_modules/@papercraftgames/estragon`, with no symlink or
copied-addon substitute. Tar SHA-256:
`37101d09502105d251c3ec5fe31dadb7596296dee94e1be24dd1c639b599787f`.
This is a read-only candidate-tag preview using `estragon-tag-overlay-v1`, not
release certification, publication or a source version bump. Exact staged tag,
version, engine hashes and argv are in the fixture manifests/provenance.

[Source qualification](../../tests/ux01/evidence/u02/source-qualification.json)
matches all 153 package files to current source with only the authorized version
overlay. Both installs retain all 71 canonical addon UIDs and byte hashes after
editor shutdown. The old public script/UID, imports, catalog suggestion and
registered class are absent. All seven authored gallery maps match source and
generated hashes. [UID audit](../../tests/ux01/evidence/u02/uid-audit.json):
267 unique tracked script/UID pairs, including 254 active scripts.

| Acceptance on each engine | Result |
| --- | --- |
| Existing capacity/Bool/text/maxima/reproduction | PASS 89 / 32 / 14 / 40 checks |
| Native scroll ranges, max-only/unbounded axes, capture and persistence | PASS 12 |
| Nested wheel exhaustion, scrollbar hit, reentry and shrink | PASS 5 |
| Direct native/custom/Toggle input, offset-only translation | PASS 10 |
| Invalid GGX/native setters, read-only values, reset/repair, zero/many children | PASS 23; 13 intended diagnostics |
| New inherited VBox/HBox/Grid/Wrap/Entry, lifecycle and retained ownership | PASS 50 |
| Combined migrated gallery and native pack/reload | PASS 29 plus reload |
| Inspector properties/offset undo, current/main Play rollback and repair | PASS 20 |
| Cold editor restart and actual main game | PASS 12 |
| Clean native import and obsolete-component/package audit | PASS |

The inherited fixture proves eight direct Text children measure 900px with a
300px viewport and 600px range at 320x240, 640x480 and 1000x800. HBox retains
624px content with gaps; Grid retains tall cells, spans and named-area geometry;
nested Wrap retains its non-scroll capacity and border/padding. Entry native and
custom buttons activate exactly six times across those sizes. Native scaled bar
drag, wheel/Shift/pan, clipped release, focus, flag toggles, subscriptions,
reentry, pack/reload, foreign-owner rescue and bounded native geometry pass.
Nested hidden content does not inflate ancestor ranges. Scroll-only changes
leave layout/composition counters unchanged; settled layout is idle.

Actual software-OpenGL captures were inspected on **both** engines: direct Text,
320px spanned Grid, 320px and 1000px nested Wrap, and the migrated gallery at its
middle offset. They show native clipping/bars, two-line tags at small width,
single-line tags at wide width and ordinary unscrolled paint overflow. Selected
PNGs and complete stage logs accompany [4.0.4 results](../../tests/ux01/evidence/u02/4.0.4/results.json)
and [4.7 results](../../tests/ux01/evidence/u02/4.7/results.json).

## Commands and proportional regressions

Linux Docker `estragon-e04-local`, Xvfb/Openbox and Mesa llvmpipe compatibility
graphics; isolated self-contained editor settings, no user preference changes.
From `/repo`, `XDG_RUNTIME_DIR=/tmp/e04-runtime`, with `U02_CANDIDATE_TAG` set to
the existing preview tag recorded in provenance:

```sh
COREPACK_ENABLE_PROJECT_SPEC=0 corepack yarn@1.22.22 node --experimental-strip-types tools/check-ux01.ts --engine 4.0.4=/evidence/s03-engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/evidence/s03-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --editor --candidate-tag "$U02_CANDIDATE_TAG" --output /tmp/u02-review-final
bun install --frozen-lockfile
bun run check
```

Paired collector PASS in 249.10s, local only. Frozen install unchanged;
typecheck and all 30 policy tests PASS. Routine PR/main CI stays unchanged with
its 60-second budget; its independent result is recorded in the live PR.

The seven bounded 4.7 regression collectors use the same approved engine, each
with a new output directory; no extra editor matrix or full release suite:

```sh
corepack yarn@1.22.22 node --experimental-strip-types tools/check-lengths.ts --engine 4.7=/evidence/s03-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/u02-regressions-815f106/lengths
# Same invocation for check-styling.ts, check-spreads.ts, check-responsive.ts,
# check-native-controls.ts and check-node-runtime.ts (the latter --runtime-only).
corepack yarn@1.22.22 node --experimental-strip-types tools/check-native-ui.ts --engine 4.7=/evidence/s03-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --runtime-only --output /tmp/u02-counter-final
```

All PASS: lengths 243 (including L07/L08/minima/root Exit), styling 158,
spreads 61/7/93/28, Wrap/Grid 95/21/44 and rendered reload, shared core 18 plus
149 native 2D/3D runtime assertions, Controls 57 plus Exit/examples, Counter 32.
[Regression provenance/results/logs](../../tests/ux01/evidence/u02/regressions/)
record clean source `815f106` for the first six and `1c21144` for Counter. Their
addon bytes are identical to paired source; later changes only improve U02 tests.

## Failures, corrections and limits

Focused development exposed native Controls stealing a scaled scrollbar drag
when the bar used INTERNAL_MODE_FRONT. Appending both bars after the clip branch
fixes actual GUI order; both-engine drag/click counts now pass. First paired
acceptance failed an old nested fixture because the inner/outer bars overlapped:
the outer bar correctly moved, with zero content activations. Separating fixture
widths makes the intended inner target accessible. Counter's first collector
stopped after a successful build on a Docker bind-mount `chmod` EACCES while
copying generated evidence; the container-local output rerun passes. Original
attempt logs are retained under [attempts](../../tests/ux01/evidence/u02/attempts/).
Logs have only trailing horizontal whitespace removed; JSON/PNG/manifests retain
their original bytes.

Manual interactive smoke: **UNTESTED**. Automated real native graphics/input,
editor Inspector/undo, both actual Play paths and cold restart ran. No physical
keypress test is required. No other engine/platform, touch dragging, virtualized
lists, 3D scrolling, new focus manager or release/publication claim. The documented
4.0 optional isolated-preflight/introspection limits remain; mandatory actual-path
validation and transactional rollback pass. Owner review/merge remains next.
