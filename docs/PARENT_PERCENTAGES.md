# L12 — parent-owned dimension percentages

[Issue #219](https://github.com/papercraftgames/Estragon/issues/219) refines the existing native2D core. `width` and `height` remain the only authored/runtime-writable dimension targets. Getters retain the assigned numeric/String value; `layout_size` is the computed actual border-box. Layout never writes actual geometry into those setters. Changed GGX desired props apply normally; an unchanged desired prop preserves an intervening imperative assignment.

Borders and padding always consume the inside of that border-box once. For actual width200, border5 each and padding20 each, content width is150. Margins remain outside. No box-sizing option, shrink, alternate sizing prop or viewport fallback is added.

## Two internal reference domains

Let **P** be the immediate parent's actual content extent after its inside border/padding. Only child **percentage width/height** use the policy budget **R** below. Padding, borders, margins, offsets, gaps, min/max and Grid track percentages retain their existing Length-domain containing references. Gaps resolve from that ordinary context before budget subtraction. Physical `column_gap` is X and `row_gap` is Y, with `auto` falling back to the matching physical `gap` axis.

| Immediate native2D policy | Width budget R.x | Height budget R.y |
| --- | --- | --- |
| Nonwrap row/HBox, N participating children | max(0,P.x−column_gap×max(0,N−1)) | P.y |
| Nonwrap column/VBox | P.x | max(0,P.y−row_gap×max(0,N−1)) |
| Grid with canonical C columns / T rows | max(0,P.x−column_gap×(C−1)) | max(0,P.y−row_gap×(T−1)) |
| Wrap, either direction | P.x | P.y |

Hidden/nonparticipating children, null managed output and plain/independent-Entry boundaries do not create stack gaps. Disabled but visible children still participate. Transparent Gogo hosts forward the ordinary reference and dimension budget once; they neither subtract another gap nor expose new author fields. A child resolves descendants from **its own final actual content**, including when its outer allocation came from a Grid, grow, stretch or a native adapter.

Unavailable/unanchored axes stay unavailable (`-1` internally), with the existing bounded warning/zero percentage resolution. An auto parent does not invent independent authority. Independent2D Entry roots continue using their visible viewport as their own containing rectangle for every existing Length domain. Nested Entries start a separate scope. This task leaves native3D's existing percentage policy unchanged.

## Examples and honest overflow

For inner width300 and column gap20, two nonwrap children25%/75% are70/210 at X0/90: the last edge is300. Transpose for a column and row gap. Zero/one children consume no phantom gaps. Percentages are **not** fractions of the leftover after fixed siblings:100px +75%×280 +20gap totals330, deliberately overflowing.

Wrap instead resolves75/225 from the full300, then places them on two lines because75+20+225 exceeds300. Adding a sibling or wrapping another line does not change those fractions. With outer400, border5 and padding20 each, P.x=350 and a75% wrapped child is262.5. No per-line solver or back-propagation is used.

Grid dimension percentages are of the **usable total track budget**, not their own cell. At300/gap20/two default fraction columns,25%/75% become70/210 and the existing floor-aware water-fill produces70/210 tracks. An auto Header spanning both columns fills300 including the internal gap. Named areas, placements and spans do not redefine the dimension reference or add a Header-specific deduction.

Explicit fixed/auto/%/fr track semantics remain separate. Columns `["25%","75%"]` still resolve75/225 from300; with a20 gap their total is320. A70px child can overflow a50px fixed track. Large natural content, conflicting rows, minima/native floors, margins or over100% dimensions preserve forward overflow. No track normalization, percent renormalization or invisible shrinking is introduced.

If Grid allocates Body actual width210 and Body has border5/padding20 each, its nested `HBox wrap width="100%"` is160. Its own75% child is120, regardless of the ancestor Grid or viewport. Changing Body's allocation updates the nested context and wrap lines; the getters remain `"75%"` / `"100%"`.

## Auto rows, allocation and scrolling

Implicit/auto Grid rows remain intrinsic and may exceed the containing viewport. A200-high Grid with30-high Header and300-high auto Body has rows30/300; content can visibly overflow. Auto is not remaining space.

For `rows={["auto","1fr"]}` on a definite200-high Grid, a scrolling auto Body can use the remaining170 as its actual viewport. Hidden scroll content is not a minimum viewport floor in an entirely fractional definite span; the item's own intrinsic/insets/authored/native minimum still constrain it. The existing water-fill allocates the tracks. Fixed/auto/percentage spans and unbounded fraction axes retain their prior contribution rules. A real minimum larger than the available170 still overflows.

With300px content in that170 viewport, range is130 and the native clip/bar operate on170. In an implicit auto row, Body naturally fits300 with range0. An empty grow child in an unbounded auto row can remain0; in a definite170 viewport with positive remainder it receives170. Overflow has no positive growth remainder. Nested scroll viewports contribute their visible actual bounds to ancestors, not hidden content; offsets/hit clipping and exhausted-wheel bubbling remain native/current behavior.

Allocated container axes are not fed back as another intrinsic grow basis. The bounded measurement pass updates dependent unallocated axes (such as wrapped height after a cell width is assigned) while preserving the natural growth basis on assigned axes. Genuine invalidation clears stale allocations. No iterative signal convergence, per-frame solver or automatic viewport height is introduced.

## Invalidation and evidence

The parent caches its dimension budget by content/gaps/participating counts; children keep domain-aware resolution caches. Target/gap/inset/count/visibility/placement/viewport changes invalidate affected branches through existing coordinators. Same-value writes, unchanged contexts and settled frames perform no repeat parsing/measurement/arrangement/recomposition. Reentrant callbacks can queue one genuine follow-up because pending/arrange flags clear before callbacks. `layout_applied` still means arrangement completion, including a dirty pass whose numeric size remains unchanged.

[Layout.gogo](../examples/proportions/Layout.gogo) and its scene demonstrate the existing layout-declaration/Grid/transparent-host path. `tests/lengths/proportions.gd` covers numerical contracts; `proportion_game.gd` covers real native targets, geometry, ownership, scroll, reentrancy and retained GGX. The existing `tools/check-input.ts --proportions` packages both #219 and the independent [neutral Input #220](INPUT.md) correction into one immutable direct-Yarn consumer, including both real editor Play paths/restart. No external GogoDemo is modified. Engine/platform/manual-smoke/IME limitations belong in the source-qualified task evidence.

[Source-qualified paired native evidence and separate Input before/after proof](evidence/L12_PARENT_PERCENTAGES.md).

U03 [#222](SCROLLING.md#u03--stable-inside-gutters-and-native-skins) reserves enabled scrollbar gutters after parent border/padding. For scroll owners the usable P in the tables above is V after that single gutter deduction. Shared/axis thickness percentages use the separate pre-gutter inner rectangle, preventing circular sizing.
