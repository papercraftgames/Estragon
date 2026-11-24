# U03 — inside scrollbars and native skin evidence

Issue [#222](https://github.com/papercraftgames/Estragon/issues/222) follows owner-merged
L12/UI-04 PR #221, base `f4072716c91c4636325457a9c4b401b7c75236d7`.
Review implementation (all paired stages PASS): `49c981fe8b01e6ba7a86c5e895b37ad2af87aefd`.
Subsequent documentation/evidence commits do not change tested executables.
This is local development-package acceptance, not release certification/publication.

## Before and after

The repository-owned `tests/scrollbars/baseline.gd` exercises a bounded Body,
full-width button/panel, wrapping actions and nested scroller. Every one of174
baseline addon files was compared byte-for-byte with the base commit; see
[baseline provenance](../../tests/scrollbars/evidence/baseline/provenance.json).
On official Linux4.7 the outer400×300 box originally gave its clip/child400px,
while the12px bar started at388: authored content occupied the same right12px.
The same fixture after the change gives the clip/child388px inside the same400px
owner. [Before](../../tests/scrollbars/evidence/baseline/before.png),
[after](../../tests/scrollbars/evidence/baseline/after.png), with adjacent exact
logs. The after-baseline image is a focused dirty development capture; the final
paired captures below qualify the committed implementation. No GogoDemo or supplied
Assets were edited.

The40 mathematical assertions cover vertical/horizontal/dual gutters, the exact
380×270/20×270/380×30/20×30 example, border/padding→332.5→249.375, auto allocations
without outside growth, zero/150% caps, physical/viewport units, malformed values,
axis skins and explicit Resource identity. Native42 additionally verifies real
range/page, bounded rewrap, Body210→158, rendered neutral/hover/press pixels,
edge clicks at640/900, native track click/drag through a thickness change,
Shift-wheel/pan/nested exhausted bubbling, native viewport-unit changes, resource
minimum fitting, textured expansion clipping, settled idle and pack/reload.

Retained GGX32 covers transparent hosts, reactive targets, native Input focus/caret,
valid offsets, imperative override preservation, omission/default restoration
(including actual subclass defaults), seven invalid-description/repair pairs,
five atomic native setter rejections and four authored compiler rejections.
The12 expected runtime diagnostic brackets are checked exactly; unexpected native
errors/leaks fail the collector. The positive9 retained checks also run in both
editor Play paths and on restart.

## Paired immutable direct-Yarn acceptance

Both approved official Linux engines execute one identical development tarball
installed directly under `node_modules`, without copying/symlinking or hiding the
package. Isolated projects, engine copies/self-contained settings and addon paths
are used; the user's checkout preferences/addon activation stay untouched.

| Stage | Linux4.0.4 | Linux4.7.0 |
| --- | --- | --- |
| U03 pure40 / native42 / retained32 | PASS | PASS |
| L12 pure36 / native34 | PASS | PASS |
| Input52 / neutral palette12 / frontend22 / rejection19 | PASS | PASS |
| Clean import / Inspector7 / current+main Play rejection/rollback/recovery | PASS | PASS |
| Successful current+main Play / editor restart | PASS | PASS |
| Installed addon bytes/85UIDs / six authored maps+UIDs unchanged | PASS | PASS |

[Paired summary](../../tests/scrollbars/evidence/paired/summary.json),
[4.0.4 results](../../tests/scrollbars/evidence/paired/4.0.4/results.json),
[4.7 results](../../tests/scrollbars/evidence/paired/4.7/results.json) and adjacent
provenance/logs record exact outcomes, engine identities, files and commands. Both
use tar SHA256 `9ef8005929e58ccf688bb2fb0a7772738f83f27ebe506009795580b8d09201f7`. Native source semantic validation and transactional rollback
remain mandatory on both.4.0 lacks optional isolated preflight/symlink
introspection; its normal documented BLOCKED capability status is not a failed
actual-path build. No untested minor/platform claim is made.

Inspected [4.0.4 dual geometry](../../tests/scrollbars/evidence/paired/4.0.4/scrollbars-dual.png),
[4.7 dual geometry](../../tests/scrollbars/evidence/paired/4.7/scrollbars-dual.png),
[4.7 resized edge controls](../../tests/scrollbars/evidence/paired/4.7/scrollbars-900.png)
and [Inspector](../../tests/scrollbars/evidence/paired/4.7/scrollbar-inspector.png)
are adjacent to the paired logs: dual tracks/corner,
640/900 content/edge controls, native hover/pressed pixel assertions and Inspector
fields. Native synthetic input is separate from headless math/parsing proof.
**Manual interactive Godot4.7 smoke was not run. OS-level pointer/IME composition,
mobile/macOS/other minors and measured-monitor DPI remain UNTESTED.** Logical
viewport units and96px/in reference units are tested; no physical-key gate exists.

## Exact commands and focused regressions

```sh
bun install --frozen-lockfile
bun run check
node --experimental-strip-types -e "import('./tools/audit-native-source.ts').then(m=>console.log(m.auditNativeSource()))"
# Inside estragon-e04-local; /repo read-only, host /tmp/e04-local -> /evidence:
COREPACK_ENABLE_PROJECT_SPEC=0 LIBGL_ALWAYS_SOFTWARE=1 LP_NUM_THREADS=2 xvfb-run -a \
  corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-input.ts \
  --scrollbars --proportions \
  --engine 4.0.4=/evidence/engine404/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/evidence/engine47/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/u03-review-proof
```

Frozen install, TypeScript and static30 PASS; native audit347 scripts/347 unique
canonical UIDs PASS. Installed package audit independently requires85 unchanged
addon UIDs. New identities were generated once with official Godot ResourceUID;
no existing UID was replaced and generated maps retain their actual source paths.

At clean `d5a8b9a7bf8db6a8d825f7d8e0900c9d8fba5281`:
`tools/check-ux01.ts --scroll-only --engine 4.7=/evidence/engine47/Godot_v4.7-stable_linux.x86_64 --output /evidence/u03-scroll-final`
and `tools/check-core-reactivity.ts` with the same engine and output
`/evidence/u03-core-regression` PASS. They run through the same Yarn/Xvfb/software
GL prefix. The scroll run covers native clipping, native/nested/generated scrolling,
inherited/transformed input, foreign rescue, identity, pack/reload, idle, removed
public ScrollView and immutable package. CORE-01 passes frontend15/runtime11/
integration65. Final49c981f differs only in captured subclass-default restoration,
its two retained tests and the editor's corresponding assertion count; final paired
acceptance exercises that correction. These regressions are not presented as
identical-head evidence. Full historical UX syntax is outside this focused run;
its preexisting CORE-01 evaluation-count mismatch remains separately qualified in
[L12 evidence](L12_PARENT_PERCENTAGES.md#retained-failures-and-boundaries).

## Retained development failures

- Initial static checks caught untracked helper files and missing UID sidecars.
  Both were added with their scripts; final30 policy tests and the347-UID audit pass.
-4.0 rejected newer Vector2/3 `max()` methods; production uses the4.0 public scalar
  clamp APIs instead. The failure log is retained, not called a successful run.
- An initial collector rejected the geometry stage because its success marker
  included a count. Counts now have a separate assertion line, with exact standalone
  success markers. No classification rule was weakened.
- The original180s editor budget timed out after successful Inspector, invalid
  current/main rollback and current Play.45s settling and a separate bounded360s
  whole U03 editor stage accommodate the combined games on the isolated cold4.0
  editor. Original failed log/result remain in development evidence. This opt-in
  test budget does not alter routine CI or production behavior.
- Diagnostic/editor runs interrupted while incorporating the final auto-size,
  texture and subclass corrections are retained as interrupted evidence, not PASS.
- Synthetic pointer tests use the existing real Input dispatch path and retain
  coroutine probe objects explicitly across awaits on4.0. Pan is delivered directly
  to the native Viewport to avoid duplicate root/subwindow Input gesture delivery.

Required PR CI and its60-second execution-wall measurement are recorded on the sole
live PR. No workflow/gate/version/release/publication change or automatic merge.
