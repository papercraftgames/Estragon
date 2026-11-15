# Parent-owned layout — L07A

L07A #164 extends the existing native coordinator and pure mathematical core.
The parent measures participants and owns their allocated border-box slots.
Native Nodes, owners, transforms, drawing and input remain authoritative.

```gogo
func build_view() -> Element:
    return <Entry2D width="100vw" height="100vh">
        <VBox width="100%" height="100%" horizontal_align="stretch" gap="8px">
            <Spacer grow={1} width="50%" />
            <Text text="Hello World!" />
            <Text text="This is fun!" />
            <Settings />
            <Rose />
        </VBox>
    </Entry2D>
```

Use normal explicit preload imports (or Add Missing Imports) for Entry2D, VBox,
Spacer, Text and Element. Spacer resolves to `EstragonSpacer`, a non-drawing,
zero-natural-size standard Node2D participant. Settings/Rose are project Gogo
components. `<Button>` remains Godot's native Button. No wrapper or helper Node
is needed for placement. See the runnable responsive lengths example.

`grow` replaces `flex` with no compatibility alias in this beta. Zero keeps
natural size; positive weights add proportional shares of free main-axis space
to auto preferred sizes. Spacer's preferred size is zero. Explicit width/height
wins over grow on that axis. Native Control EXPAND_FILL keeps its existing
minimum-constrained allocator; the adapter receives only the outer rect and Godot
owns Container interiors. Natural sizes/minimums and explicit dimensions never
shrink to hide overflow. Zero/negative free space adds zero. Pixels are floating
point, without per-child rounding or clipping.

Percentages are full definite immediate-parent **content** dimensions, never
remaining space. Entry roots have no layout parent: use `100vw`/`100vh`.
Unanchored percentages resolve to zero with an actionable warning. A 100% flow
child alongside siblings warns that it may overflow; explicit main size with
grow warns that size wins. Warnings are bounded per model, not repeated per frame.
Padding, margins and gaps subtract once. A percentage child does not subtract its
own margin from the parent's percentage reference. Auto parents invent no free
space; natural measurement already contains the children's preferred extents.

## Delivered parent policies

`Box direction="row"` or `"column"` selects a shared axis-transposed stack policy.
HBox and VBox fix that direction as readable presets. `horizontal_align` always
means X and `vertical_align` always means Y. Both accept start/center/end;
`stretch` is cross-axis only and affects auto child sizes. Start is default;
fixed child sizes remain fixed under stretch. Existing child `stretch=1` can
request cross stretch independently. Native Control minimums remain floors.
Changing direction plus alignment in one desired description commits atomically.

```gogo
<Box direction="row" width="400px" height="100px"
     horizontal_align="end" vertical_align="center" gap="12px">
    <Rect width="40px" height="20px" />
    <Rect width="70px" height="30px" />
</Box>
```

Physical names are canonical; no align-items/justify-content alias family.
Space-between/around/evenly and per-child placement overrides remain #161.
Legacy `center` remains the older main-axis centering option (and takes precedence
if explicitly true); new examples use physical-axis policies. No new native
Control properties, out-of-flow mode, shrink/basis shorthand or CSS engine.

## One measured-data / slot pipeline

| Contract | Existing core / policy data |
| --- | --- |
| Preferred border-box extent | `measured`; requested dimensions override intrinsic child/content measure |
| Minimum border-box extent | `allocation_minimum`, from native adapter minima |
| Outer preferred/minimum extent | corresponding border-box extent + `outer_extent()` (margins) |
| Parent content / unit basis | arranged extent minus padding; `content_reference` axes are -1 when indefinite; retained specs resolve only on changed references |
| Child placement | ordered measured policy input: preferred/minimum/requested, grow, stretch, fill, outer/leading margin |
| Allocated slot | parent `slots[index] = {position, extent}` relative to content origin, including leading child margin, excluding child offset |
| Final arrangement | parent padding + slot position + child additive length offset; native adapter applies position/extent |

`stack_policy.gd` assigns slots without Nodes, subscriptions or mutation of children.
Core measurement/invalidation/cache stays in `layout_core.gd`; the coordinator
applies native signals. HBox/VBox contain no arrangement math. Transparent Gogo
hosts forward allocation authority once, with independent Entry/plain/native
boundaries intact. 3D uses the same existing stack pipeline and explicit pixel
scale; no new grid plane is inferred. No polling or repeated per-frame parsing.
A future Wrap policy groups slots into lines; Grid computes slots from tracks;
neither must use the sequential cursor algorithm.

## Pure Grid groundwork; rendered Grid is future work

Internal `grid_definition.gd` normalizes serializable row/column tracks, area
matrix, rectangular bounds and child placement records. It has no public Grid
Node, native renderer or GGX `area` attribute yet. The following is **future
#163 syntax**, not a runnable current example:

```text
columns=["220px", "1fr"] rows=["64px", "1fr"]
areas=["header header", "sidebar main"]
```

Normalization yields header `{row:0,column:0,row_span:1,column_span:2}`,
sidebar `{row:1,column:0,row_span:1,column_span:1}`, main
`{row:1,column:1,row_span:1,column_span:1}`. A dot is an unassigned cell.
Tracks accept a positive integer count (equal 1fr tracks) or an array of length
specs/positive `fr` weights. `fr` is track-share weight, never a width/height unit.
Indices are zero based; spans are positive. Unknown fields/areas, uneven rows,
nonrectangular names, out-of-bounds spans, and overlapping child placements reject.
Area placement conflicts with explicit indices. Empty placement defaults to the
first cell in this pure bounded validator; **automatic placement is not delivered**.
The future parent/Element placement record owns area/index/span metadata; foreign
native Nodes do not acquire layout properties.

The future compact template
`header header, 64px\nsidebar main, 1fr\n\\ 220px 1fr` will parse to these same
tracks and matrix before normalization. That text parser and track allocation,
rendered Grid, Wrap and complete policies remain #163/#162/#161 respectively.
There are no dormant public components pretending to implement them.
