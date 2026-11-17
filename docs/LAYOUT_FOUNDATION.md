# Parent-owned layout — L07A

L07A #164 extends the existing native coordinator and pure mathematical core.
The parent measures participants and owns their allocated border-box slots.
Native Nodes, owners, transforms, drawing and input remain authoritative.

```gogo
func build_view() -> Element:
    return <Entry2D width="100%" height="100%">
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
components. Unimported `<Button>` remains Godot's native Button. No wrapper or helper Node
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
remaining space. Independent2D Entry roots use their visible Viewport as an
implicit containing rectangle:100% is full viewport,50% half,150% overflow;
100vw/100vh remain equivalent explicit syntax. This applies to root dimensions,
insets, margins, direction-aware gap and additive offsets. Root margin is not
consumed without a layout parent. All ordinary children use their immediate
parent content box; auto/cyclic ordinary percentages remain zero with a warning.
Nested independent Entries retain their own viewport scope. L07 #160 supersedes
the earlier L06/L07A statement that root100% must be rejected. A 100% flow
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
L08 below completes main-axis space-between/around/evenly and eligible 2D align_self.
Legacy `center` remains the older main-axis centering option (and takes precedence
if explicitly true); new examples use physical-axis policies. No new native
Control properties, out-of-flow mode, shrink/basis shorthand or CSS engine.

## One measured-data / slot pipeline

| Contract | Existing core / policy data |
| --- | --- |
| Preferred border-box extent | `measured`; requested dimensions override intrinsic child/content measure |
| Minimum border-box extent | `allocation_minimum`, from native adapter minima |
| Outer preferred/minimum extent | corresponding border-box extent + `outer_extent()` (margins) |
| Parent content / unit basis | arranged extent minus padding; `content_reference` axes are -1 when indefinite; an independent2D Entry receives its visible viewport containing reference; retained specs resolve only on changed references |
| Child placement | ordered measured policy input: preferred/minimum/requested, grow, stretch, fill, outer/leading margin |
| Allocated slot | parent `slots[index] = {position, extent}` relative to content origin, including leading child margin, excluding child offset |
| Final arrangement | parent padding + slot position + child additive length offset; native adapter applies position/extent |

`stack_policy.gd` assigns slots without Nodes, subscriptions or mutation of children.
Core measurement/invalidation/cache stays in `layout_core.gd`; the coordinator
applies native signals. HBox/VBox contain no arrangement math. Transparent Gogo
hosts forward allocation authority once, with independent Entry/plain/native
boundaries intact. 3D uses the same existing stack pipeline and explicit pixel
scale; no new grid plane is inferred. No polling or repeated per-frame parsing.
Wrap groups slots into lines; Grid computes slots from tracks. Both use this same
core, native coordinator and event-driven measure/arrange pipeline (L09-10 #176).

## Grid normalization and native delivery

L07A introduced pure serializable track/rectangular-area/placement groundwork.
L09-10 #176 extends it with implicit rows, explicit-first collision-free auto
placement, compact template normalization and a real native Grid slot policy.
The [current public contract](RESPONSIVE_LAYOUT.md) covers authoring, finite row
limits, cell alignment, spanning floors, overflow and description-owned placement.
Foreign native Nodes never acquire layout properties. Earlier #162/#163 proposals
are consolidated in this one milestone.


## L08 — complete physical-axis distribution and child overrides

[L08 #161](https://github.com/papercraftgames/Estragon/issues/161) extends the same
Box/HBox/VBox properties and pure StackPolicy. Main X for row/HBox, main Y for
column/VBox: start, center, end, space-between, space-around, space-evenly.
Cross axis: start, center, end, stretch. Main stretch and cross space-* reject.
HBox/VBox remain fixed presets; generic Box can change direction and both physical
policies atomically through GGX. No justify/align/align-items/justify-content alias.

Compute final requested/natural/minimum/grow/native-fill border-box extents first,
including margins and base gap between adjacent items. Only remaining positive
free space is distributed. Main grow consumes its allocation before any space-*
calculation; distribution never allocates that space twice. Native fill keeps its
existing minimum water-filling. Padding/border consume content once; margins stay
outside each child. No integer rounding, shrink, clipping or negative distribution offsets.

For 300px content, three 40px children and 10px base gap, 140px occupied leaves 160px:

| Main policy | Child positions relative to content origin |
| --- | --- |
| start | 0,50,100 |
| center | 80,130,180 |
| end | 160,210,260 |
| space-between | 0,130,260 |
| space-around | 26.6667,130,233.3333 |
| space-evenly | 40,130,220 |

The same table applies to Y for a column. Between adds extra inter-item gap only;
around has half-sized outer added gaps; evenly has equal outer/inter-item added
gaps. Base gap is never added at outer edges. Zero children produce no slots.
One child: between=start, around/evenly=center. Overflow has zero distributable
space, so all policies fall back to forward start placement and the normal gap.
Legacy center=true still overrides the main physical policy to center; it cannot
create leftover space after growth and does not affect cross alignment.

Eligible Component2D descendants have align_self=auto (default), start, center,
end or stretch. It overrides only the actual parent's cross axis. Explicit
non-auto wins over old child stretch; auto uses an existing child stretch/fill
request first, otherwise the parent's cross policy. Ordinary native Godot Controls
participate in parent cross alignment/minimums without acquiring align_self.
Public 3D properties are unchanged. All cross stretching applies only to auto child
axes; explicit percentage/fixed dimensions win, and authored/native minima remain
floors. Outer margins are subtracted before cross placement; x/y remain additive
post-slot offsets. Self stretch carries the existing definite percentage authority
to descendants; explicit self start/end/center can remove the old stretch request.

Nested Gogo hosts forward their managed root's align_self through the existing
transparent layout bridge, without helper Nodes or duplicated positioning. Omitted
previously authored GGX align_self restores auto on the retained Node, including
spread removal. Native setters, compiler literals, complete-description preflight
and the native enum Inspector use the same shared value matrix. Invalid directions,
main/cross enum values and self values retain prior native/generated state; repaired
source/Play recovers normally. Equal writes and idle frames do no layout polling,
recomposition, length parsing or repainting.

[AlignmentGallery](../examples/alignment/AlignmentGallery.tscn) demonstrates native
HBox/VBox/Box, nested Gogo, styled Text/Rect/Estragon Button/Toggle, native Control,
Dictionary spreads and explicit keyed/conditional children. Use explicit preload
aliases; unimported Button remains Godot's native Control. Absolute position,
shrink/basis changes and style/theme APIs remain separately scoped.


## L09-10 — responsive Wrap and native Grid

Owner #176 combines former #162/#163 in one milestone. See [the complete public
contract](RESPONSIVE_LAYOUT.md), [source-authored gallery](../examples/responsive/ResponsiveGallery.gogo)
and its native scene. `wrap`, physical gaps and `align_content` extend Box;
`EstragonGrid` is a real Component2D with tracks, implicit rows, spans, named areas
and a compact template. Grid placement belongs to Element/external framework records.
No foreign Node properties, wrappers, polling, CSS renderer or 3D plane are added.
