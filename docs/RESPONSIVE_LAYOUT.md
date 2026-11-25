# Responsive Wrap and native Grid — L09-10

Issue [#176](https://github.com/papercraftgames/Estragon/issues/176) combines the former
Wrap #162 and Grid #163 milestones. Both produce parent-owned border-box slots in
`layout_core.gd`; native Node2D lifetime, drawing, transforms, input, the Control
adapter and the signal-driven description reconciler remain authoritative. No
Container, wrapper, CSS renderer, separate measure loop or frame polling is used.
This is container item wrapping, not Text glyph/word wrapping. 3D stays unwrapped.

Use ordinary explicit aliases (or editor Add Missing Imports):

```gogo
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Grid = preload("../../../addons/estragon/runtime/node/grid.gd")
```

Paths above match a generated script under `examples/responsive/generated`.
The [gallery source](../examples/responsive/ResponsiveGallery.gogo) and
[native scene](../examples/responsive/ResponsiveGallery.tscn) are runnable examples.

## Wrap

Box/HBox/VBox expose `wrap: bool = false`. `gap` remains the shorthand;
`column_gap` is always X, `row_gap` always Y. Both accept nonnegative shared Length
specs or `auto` (default), which falls back to that physical axis's resolved gap.
Their percentages use the immediate containing content box, like existing edges.
They work on unwrapped 2D stacks too. Native Controls gain no custom properties.

```gogo
<HBox width="100%" wrap={true} gap="10px" row_gap="12px"
      horizontal_align="space-between" vertical_align="center">
    <Card width="120px" />
    <Card width="120px" />
    <Card width="120px" />
</HBox>
```

Greedy line breaks use preferred border boxes, minimum floors and outer margins,
before growth. Only an independently definite main content axis permits breaking;
auto/unanchored main axes form one finite natural line. Zero content is definite
when independently supplied; an oversized child occupies one overflowing line.
VBox/column Box uses precisely the transposed algorithm.

Each completed line uses the existing StackPolicy: requested dimensions/minimums,
grow/native fill shares, then remaining positive space distribution. Percent child
sizes refer to the full parent content, never the line remainder. The cross extent
is the largest outer child extent on that line. Physical item alignment and
cross-only `align_self` operate inside that line; stretch changes only auto sizes.
Natural auto cross size contains all lines and cross gaps. An independently
assigned auto width/height can cause a bounded allocation-dependent remeasurement
inside the same core; this does not reexecute Gogo.

`align_content`, default `start`, groups finished lines in definite extra cross
space: `start`, `center`, `end`, `space-between`, `space-around`, `space-evenly`,
`stretch`. Stretch enlarges line allocations, not definite child dimensions.
Empty groups consume no gaps. A single line starts for between/stretch, centers
for around/evenly/center, and ends for end. Overflow adds no negative offsets or
negative extents. Indefinite cross axes invent no extra distribution space.

With 160px content, 3×70px children, column gap10 and row gap12, 20px-high children
start at (0,0), (80,0), (0,32). At230px all fit at X0/80/160. Resizing preserves
native instances, handlers and ownership.

## Grid

`EstragonGrid` derives from Box, with the grid strategy selected by default. Default `columns=null` means one
column. Set a positive integer count for equal1fr tracks, or a nonempty Array of
shared numeric/Length/`auto` track specs and positive `Nfr` weights. `fr` belongs
only to track grammar. Each axis is limited to256 tracks (65536 cells maximum).
Nonfinite/negative lengths and zero/nonfinite fraction weights reject.

```gogo
<Grid columns={3} width="100%" gap="10px" padding="12px">
    <Card /><Card /><Card /><Card /><Card />
</Grid>
```

Omitted/null rows grow as intrinsic auto tracks. An explicitly supplied count or
Array is finite: out-of-range explicit placements and exhausted automatic cells
reject the complete desired description. There is no silent extra-row precedence.
The physical gaps, border, padding, margins, minimums, native text/font signals
and visible viewport units use the existing shared contracts.

Fixed/%/viewport/physical tracks keep their resolved sizes. Auto tracks take
measured contributions. Fractional tracks water-fill the remaining nonnegative
content above their intrinsic/minimum floors; equal fractions stay equal when
floors permit. A wrapping component contributes its largest unbreakable child's
main extent as its intrinsic floor, then measures cross size at its assigned cell
width/height. Spanning deficits distribute equally over covered auto/fr tracks;
all-fixed spans remain fixed and the child may overflow. Overconstraint never
shrinks explicit dimensions or native/authored minimums. Indefinite fraction axes
use intrinsic floors; indefinite percentage tracks use zero and a bounded warning.
Grid ignores stack grow and Box's cross-only align_self for cell placement.

At320px content with3 columns/gap10, tracks are100 and origins0/110/220. At620px,
tracks are200. Fixed100/1fr/2fr at440px/gap10 produces100/106.6667/213.3333 without
integer rounding. Native Control minima may make equal fractions unequal or cause
safe forward overflow; they are never silently shrunk.

### Placement, spans and named areas

```gogo
<Grid columns={["220px","1fr"]} rows={["64px","1fr"]}
      areas={["header header","sidebar main"]} width="100%" height="100%" gap="12px">
    <Header area="header" />
    <Button area="sidebar" text="Native Control" />
    <Main area="main" />
</Grid>
```

`area` or 0-based integer `row`/`column` and positive integer `row_span`/
`column_span` belong to the Grid child's Element/external framework record.
They are never native properties or metadata on a Control/Gogo host. Missing
explicit row/column defaults to0 when either coordinate is authored; spans without
coordinates auto-place. Area conflicts with any explicit placement field.
Rectangular named areas use identifier names; `.` is an empty cell. Their matrix
must match track counts. Nonrectangles, unknown names, overlap, malformed values
and out-of-bounds spans reject before any native commit, with authored provenance.
All explicit/area items reserve first; remaining children scan row-major through
free rectangles in stable authored order. Unused named cells are not implicitly
reserved without an item. Borrowed compatible children without metadata auto-place.

Per-cell `horizontal_align` and `vertical_align` both default to `stretch` and accept
only start/center/end/stretch. Stretch affects auto axes; explicit dimensions win.
Outer margins consume cell space; additive x/y applies afterward once. Percentage
child dimensions use the immediate Grid's total usable track budget after physical track gaps, **not the cell** ([L12](PARENT_PERCENTAGES.md));
authored100% inside a smaller cell may therefore overflow. There is no extra
per-child physical alignment API. Grid does not infer geometry for Sprite/plain
Node/3D children or accept conflicting anchored/transformed Control outer bounds.
Godot retains Control internals, focus and native GUI behavior.

### Compact template

```text
header header, 64px
sidebar main, 1fr
\ 220px 1fr
```

Set this as one `template` String. Each nonempty row contains space-separated area
names and optionally one comma plus its row track (`auto` if omitted). Exactly one
leading-backslash line declares space-separated column tracks. Tabs are whitespace;
blank lines are ignored. This small native grammar normalizes to the same
columns/rows/areas/placements as the expanded form, inspired by Voltra EasyLayout's
readability. No Voltra renderer/wrapper implementation is copied.

Nonempty template and explicit nonnull columns/rows or nonempty areas are ambiguous
and reject. Complete GGX descriptions atomically reset omitted Grid config fields
to defaults, so switching forms works. Direct native setters preserve the previous
valid config; clear explicit config before setting a template. Arrays are snapshotted
by setters; mutate through assignment, not in-place Array edits.

## Reactivity, validation and evidence

The normal lexical compiler, native Script/ClassDB metadata, source maps, ordered
S03 spreads, complete-description preflight and native Inspector remain in use.
Invalid dynamic config/placement preserves the previous **whole** mounted view;
repair replays normally. Keyed reorder/removal clears stale placement records.
Native visibility, minimum/font, resize and tree events dirty affected branches;
equal assignments and idle frames do not parse templates or recompute layout.
Runtime layout Nodes remain transient; authored scene owners and native pack/reload
semantics are unchanged. See `tests/responsive` and `tools/check-responsive.ts` for
focused mathematical, native, actual-path, direct-Yarn graphics/editor verification.

### UX01 available capacity refinement

An auto main-axis Wrap can use definite immediate-parent capacity to break lines
without an authored width/height. Short groups retain natural size; this ceiling
does not confer percentage authority. Ordinary overflow remains visible. Maxima
and inherited Component2D scrolling use the same core and parent slot policies.
Scrolling decorates Stack/Wrap/Grid rather than replacing their strategy. [Contract](SCROLLING.md).

### EL02 reusable definitions and Grid modes

[Layout declarations](LAYOUT_DECLARATIONS.md) lower visual named-area matrices
to this existing contract. Grid now derives from Box: `direction="grid"` is its
default; row/column (and Box wrap properties) use existing policies while retaining
inactive grid settings. Child dimension percentages use the L12 policy budget specified above; Wrap remains full-content. No additional track/parser/solver or width-to-track alias exists.

## LAYOUT-01 — allocated constraints and dependent natural dimensions

[Issue #201](https://github.com/papercraftgames/Estragon/issues/201) refines the existing bounded measure/slot/remeasure/arrange path. The live PR determines review/merge state. It does not add Text word wrapping, a shrink engine, another solver, or authored refresh hooks. The repository-owned [constraint gallery](../examples/constraint_layout/Constraints.gogo) composes an ordinary nested Gogo Header/Flow with keyed observable rows, native Input and a scrolling fractional Body.

Natural preference, available capacity and independent allocation are distinct:

- An independently assigned axis can supply a descendant percentage/grow reference. Its actual slot can remeasure a dependent cross axis; its allocated size is never reused as a new intrinsic grow basis.
- A content-derived auto Grid track remains intrinsic even inside a definite-width/height Grid. Assigning its initial slot must not suppress a dependent cross measurement. A fixed track supplies definite authority even when the Grid's overall axis is auto. Fraction/percentage tracks need a definite containing reference to supply that authority. Spans containing an auto track remain content-derived.
- A capacity ceiling can travel through an ordinary stack or transparent host to nested Wrap without making the intervening auto dimension a percentage reference. An unbounded fractional track's unbreakable floor can bound wrapping capacity while the axis still lacks independent percentage/grow authority. Scroll content remains unbounded on its scrolling main axis; this does not change definite scroll-viewport child percentage references.
- Auto tracks use natural preferred contributions. Fractional tracks use the existing unbreakable/minimum floors and distribute only actual remaining definite space. Nested ordinary stacks compose those floors rather than hiding a Wrap behind a wider initial unbounded measurement. Fixed/percentage tracks and spanning deficit distribution retain their existing grammar and overflow rules.

The same transposed rules apply to row width→height and column height→width. The numeric examples use native actual geometry, zero insets/margins unless stated:

| Case | Result |
| --- | --- |
| Three90×20 children, Wrap width220, column_gap10/row_gap8 | Two rows, natural height48; second line starts Y28 |
| Same at width290 | One row, height20 |
| Three20×90, column Wrap height220, row_gap10/column_gap8 | Two columns, natural width48 |
| Grid width460, two fr columns, column_gap20, definite height200, auto row | Child cell220; wrapped height48 contributes to auto row48, rather than being frozen at initial20 |
| Same Grid width600 | Cell290; row returns to20 |
| Fixed220 column in an auto-width Grid | Width authority220; dependent auto row48 |
| Fixed100+100 span with internal gap20 | Spanning child receives220, with dependent height48 |
| Span220, outer margins4+6, inside horizontal20/vertical24 | Actual child210, inner width190, natural border-box height72; no double insets |
| Immediate Body210, padding20 each, vertical gutter12 | Nested100% width158; its own Wrap lines use158 |
| Grid200 high with Header30 and tall300 scroll content | Auto Body row300/range0; definite1fr Body170/range130, subject to real floors |
| Grid460 wide/gap20 with native minimum500 and sibling10 | Actual track floors500/10 and content end530; deliberate forward overflow |

Changing a track, removing/restoring an independent constraint, resizing, hiding/inserting/removing/reordering participants, changing native font/minimum/theme, or changing relevant GGX props invalidates the existing affected branch. Lost allocation authority is cleared **before** natural slots are chosen, preventing an old width/height becoming its own auto floor. Capacity-only changes invalidate only dependent branches; fixed siblings stay cached. This remains a bounded dependent remeasurement inside one core, not convergence across frames. Genuine native minimum notifications can cause the existing coalesced follow-up; settled render/measure/arrange counters are zero.

Native Controls continue to contribute `get_combined_minimum_size()` through their existing event-driven adapter. Native Label wrapping, where supplied by Godot, reports its width-affected minimum via its normal notifications after actual allocation. Arbitrary Controls have **no universal height-for-width API** here: their real native minimum remains the floor, Container internals stay opaque, and anchors/transforms retain native authority. No new general-purpose measurement callback is exposed.

`EstragonText` still measures explicit newline-separated lines with the actual native font. Automatic words/glyph wrapping, shaping/fallback/RTL and the new Text authoring behavior remain **TEXT-01 #205**. That task can integrate constraint-dependent font measurement with this bounded allocation/capacity path; it must supply its own concrete tested adapter behavior rather than promise a native API that does not exist.
