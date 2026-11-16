# L08 — parent-owned Box alignment and distribution

[#161](https://github.com/papercraftgames/Estragon/issues/161), after owner-merged
S03 #174, base `81e3c6215f7a9f87e8dad6f103ec332661eae2b9`.
[Contract/table](../LAYOUT_FOUNDATION.md#l08--complete-physical-axis-distribution-and-child-overrides),
[ADR-0024](../DECISIONS.md#adr-0024--physical-axis-box-distribution-and-cross-axis-child-overrides).

Canonical physical horizontal_align/vertical_align remain the only parent API.
Main-axis distribution consumes positive free space after preferred/requested/
minimum/grow/native-fill allocation, margins and base gaps. Cross-axis align_self
joins the same ordered slot data, not a second child positioning pass. Eligible
native2D overrides forward through transparent Gogo roots. No aliases, helper
Nodes, polling, style layer or public3D field.

## Source and outcomes

Clean alignment acceptance source is `1d7f3e78d043aad7708de2572048a8f095a1d501`.
Clean package/regression source is `47675b80fc04cde74603336d63a72614ca0a35ac`;
only test-editor shutdown settling follows it. [Source qualification](l08/source-qualification.json)
authenticates identical addon files, 66 UIDs, content SHA256
`5c009e31485ea351d461b03e2d1723a10899e2bf559b92bb387714a6f70817ac` and reproducible tarball SHA256
`db33feb94aa545864e3aa1865509d8f3fe571c4e21485bff3993f826212024f4`.
Final review strengthened two test-only retention checks: tile instance IDs survive
keyed reorder and native self changes do not increment view runs. Both approved
engines PASS35 in focused follow-up runs; [provenance](l08/retention-provenance.json)
honestly records pending test/docs work as dirty, not package certification.
Later report/status/archive commits leave the tested production bytes unchanged.

| Check | Official Linux 4.0.4 | Pinned Linux 4.7.0 |
| --- | --- | --- |
| Pure numeric slot/matrix assertions | PASS 112 | PASS 112 |
| Compiler/source-publication repair | PASS 25 | PASS 25 |
| Complete-description/native rejection | PASS 54 /21 intended errors | PASS 54 /21 intended errors |
| Native runtime/geometry/input/counters | PASS 35 | PASS 35 |
| Real Inspector/current+main Play/restart | PASS 19 /11 | PASS 19 /11 |
| Seven-stage direct-Yarn package gate | PASS  | PASS  |

Pinned 4.7 regressions PASS: shared core18/runtime149 including 3D, lengths/L07/L11
243/rejections24/root-exit, Box68, styling158/rejections21, S03 frontend61/publication7/
rejections93/runtime28, Controls57/native-exit/3 examples and tiny routine smoke.
Both package gates PASS24 native runtime/50 actual editor assertions each.

Frozen install/static 30 PASS; 231 unique script/UID pairs and both canonical new
Gogo source/output maps PASS. Source qualification compares exact addon files,
reproducible tarball, direct node_modules installation and 66 unchanged addon UIDs.
No copying/symlinking/ignored install directory or external editing compiler.

## Numeric and retained native behavior

The 112 pure assertions repeat the 300px content/three 40px children/gap 10px table on
X and Y: start0/50/100, center80/130/180, end160/210/260,
between0/130/260, around26.6667/130/233.3333, evenly40/130/220. Zero/single children,
forward overflow, floating-point fractions, growth before all modes, native70/20
water-filling and explicit/self/parent stretch matrices pass. Final extents are
counted again after growth; no allocated share becomes distribution space twice.

Native inset example:340x120 outer, border10+padding10 gives300x80 content; uneven
children/margins/gap and additive offsets place first(28,51), second(260,40).
Legacy center=true overrides main distribution, moving them to X118/170 while
cross alignment remains unchanged. Explicit percentage cross sizes remain fixed;
auto cross stretch respects margins/minimum overflow and forwards percentage
authority to descendants. Explicit self start disables old child stretch/basis.
Real native expand Controls with70/20 floors and gap10 at widths100/120/80 yield
70/20,70/40,70/20 respectively, without extra distribution or hidden shrink.

The authored gallery's evenly-distributed row has content616/976 at640x480 and
1000x800. Tile X124/288/452 and214/468/722, Y33/66/33, prove parent center plus
one child's self=end. Header Close stays at content end; the configurable Box
changes row/column direction and physical policies atomically. Nested Gogo root
self=end and width50% occupy the right half through the same transparent bridge;
native override changes placement without Gogo recomposition. Responsive10vw/10vh
minima resize retained tile slots and preserve bottom cross alignment.

Keyed reorder, conditional removal, borrowed native owner/parent boundaries,
spread omission resetting self=auto, Node identities/subscriptions, default style
paint/border pixels and full outer pointer targets remain sound. Actual current/
main games report UI clicks4/native2/Toggle edits[true,false] at both sizes. Equal
native/reactive updates and settled idle frames leave composition/property writes,
measure/arrange, paint and length counters unchanged. Teardown clears all records.
Exact L08_NUMERIC and L08_COUNTERS records are in the logs.

Shared matrix rejects main stretch, cross space-*, invalid/fixed directions,
invalid self enums, invented aliases and native Control/3D self attributes. Literal
and computed/spread failures retain previous generated bytes/maps/cache and native
tree/geometry; source and offending spread key remain authored. Repair succeeds.
The real Inspector exposes parent distribution and child override enum fields,
with edits/undo/redo repeated after restart. Both native Play entry points save
current source, reject invalid unsaved policy without stale execution, preserve
code/maps/UID/timestamps/cached Script, then repair and render the newest source.

Inspected selected captures: [4.0.4 runtime640](l08/alignment/4.0.4/alignment-640.png),
[4.0.4 repaired editor1000](l08/alignment/4.0.4/editor-alignment-1000.png),
[4.7 runtime640](l08/alignment/4.7/alignment-640.png),
[4.7 repaired editor1000](l08/alignment/4.7/editor-alignment-1000.png),
[4.7 native enum Inspector](l08/alignment/4.7/alignment-inspector.png).

## Reproduce

Only official Linux 4.0.4 and pinned Linux 4.7.0, isolated settings/PATH and native
startup imports; Docker estragon-e04-local with read-only /repo and host
/tmp/e04-local mounted /evidence, Xvfb/Openbox/Mesa llvmpipe compatibility graphics.
Normal authoring/Play uses only Godot. Exact executable hashes and invocation arrays
are in provenance. No addon/preferences were enabled in the user's checkout.

~~~sh
docker exec -w /tmp -e XDG_RUNTIME_DIR=/tmp/e04-runtime estragon-e04-local \
  xvfb-run -a sh -c 'openbox >/tmp/l08-final-openbox.log 2>&1 & exec corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-alignment.ts --editor --engine 4.0.4=/evidence/s03-engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/evidence/s03-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/l08-ready'
~~~

[Regression commands](l08/regression-command.txt) use the same Docker/Xvfb prefix;
only the bounded seven-stage package group uses both engines. Other proportional
checks use pinned4.7. Existing contributor tooling uses
`bun install --frozen-lockfile` / `bun run check`; new collector uses TypeScript/Yarn.
No routine CI workflow expansion, exhaustive 73, extra versions/platforms or
release/tag/OIDC/npm publication action.

## Failed attempts and limitations

- Initial math fixture failed native type inference on a Variant loop value;
  explicit bool typing repaired the test. Its original failure is retained.
- Old L07A tests rejected main space-between, intentionally superseded by L08.
  Replace those two negatives with still-invalid cross-axis distribution cases;
  retain all geometry/counters/migration assertions and updated source contracts.
- Initial final 4.0.4 editor assertions all passed, but exit leaked one GLES3 Texture
  RID/ObjectDB instance; the raw result remains FAIL. A separate verbose native
  editor/restart probe at the same product source passed without reproducing it.
  The fixture now waits for native filesystem/timer stability and 0.3s cleanup
  after final Play stops before quitting. Corrected clean scoped two-engine run
  passes all stages and strict leak/error audits. No diagnostic waiver or
  engine-wide leak-fix claim; failed run, probe assertions and results are retained.

Selected evidence/captures are archived once with [SHA256 index](l08/artifact-index.json),
not duplicated install trees/tarballs/screenshots. Logs are normalized only for
trailing whitespace and renamed .txt; original results preserve actual log names.
The original full runs remain in /tmp/e04-local and /tmp/l08-*.log.
Godot 4.0.4 optional isolated preflight/path introspection remains unavailable/BLOCKED;
mandatory actual-path semantic validation/publication rollback PASS. No manual
interactive smoke; automated native editor/game and inspected captures supply
visual/input proof. Physical keys are not required. #162/#163/#88/S04, style/theme
APIs, shrink/basis redesign,3D expansion and publication remain out of scope.
Owner review/merge remains required; the live issue/sole PR records CI and handoff.
