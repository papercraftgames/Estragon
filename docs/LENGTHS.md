# Unit lengths — L06

L06 #156 intentionally replaces the experimental numeric-only/helper APIs. All
Estragon dimensions, declarative offsets, gaps and shared 2D participant padding and
participant margins accept `int`, `float`, or a validated `String`. Ordinary
Godot Node/Control properties retain their native types. No imports or component
extraction are needed for inline percentages.

```gogo
func build_view() -> Element:
    return <Entry2D width="100%" height="100%" padding="16px">
        <VBox width="100%" height="100%" gap="12px">
            <VBox width="50%" height="75%">
                <Rect width="100%" height="100%" fill={Color.CORNFLOWER_BLUE} />
            </VBox>
            <Text text="Hello World!" />
            <Text text="This is fun!" />
            <Settings />
            <Rose />
        </VBox>
    </Entry2D>
```

Use ordinary explicit Element/Entry2D/VBox/Rect/Text imports. Rect makes the inline
Box bounds visible; Box also supports local background/borders (see STYLING.md). The same properties work
in native GDScript (`panel.width = "50%"`) and the enabled addon's native Inspector
length entry, with native undo/redo and scene storage. Inspector bare numerics
produce numbers; units and auto produce strings. Reads preserve the exact authored
value/type; `layout_size` and `requested_extent()` are derived layout outputs.

| Value | Resolution |
| --- | --- |
| `200`, `200.0`, `"200"`, `"200px"` | 200 logical layout pixels |
| `"50%"` | dimensions use half the immediate parent's policy budget (L12); other domains keep their containing references; independent2D Entry roots use their visible viewport |
| `vw`, `vh` | one hundredth of the containing native visible Viewport width/height |
| `vmin`, `vmax` | one hundredth of the smaller/larger visible Viewport axis |
| `in`, `cm`, `mm`, `q` | 96px, 96/2.54px, 96/25.4px, 96/101.6px respectively |
| `pt`, `pc` | 96/72px, 16px respectively |
| `auto` | intrinsic dimension; on individual inset edges, inherit shorthand |

`2.5in = 240px`, `12pt = 1pc = 16px`. Inches denote the CSS reference scale,
not measured physical monitor inches. Font metrics (`em/rem/ex/ch`), `calc`,
functional `min()/max()` and monitor-DPI modes are deferred. There is no general CSS parser.

Grammar is case sensitive with lowercase units and `auto`. Outer whitespace is
trimmed; no internal whitespace is allowed. Optional `+`/`-`, decimals including
`.5in`, and numeric exponents (`2e1px`) are accepted. Booleans, collections,
nonfinite numbers, malformed/unknown suffixes and absolute magnitudes above
1e12 reference pixels reject. Converted reference-unit magnitudes also obey
that bound. Geometry-dependent results saturate at that finite bound. Dimensions,
gaps, padding and margins are nonnegative; offsets permit negatives. Numeric
`-1` is no longer authoring syntax. Unsupported `auto` contexts reject. Native
invalid setters report an error and retain the prior value/spec/geometry; GGX
literals diagnose their authored spans, and computed values are preflighted for
the complete desired tree before any commit. Repair resumes normal compilation.

## Content axes, layout and native transforms

Width/height percentages use the parent policy budget below. Other width/height units are unchanged; x/y use ordinary horizontal/vertical containing references and depth/z keep their prior depth contract.
Left/right edges use horizontal references and top/bottom use vertical. A scalar
padding/margin percentage resolves separately on each edge's axis. Gap uses the
parent stack's main axis. Padding is inside the border box; margin is outside;
neither collapses. Parent allocation subtracts padding, margins and gaps once.
Child percentage width/height use [L12 parent-owned dimension budgets](PARENT_PERCENTAGES.md): nonwrap stacks subtract applicable physical gaps, Grid subtracts canonical track gaps, and Wrap uses full content with no gap deduction. Other Length domains keep their normal containing references. Percentages never subtract fixed sibling sizes or their own margins; overflow stays explicit.

Transparent Gogo hosts forward the root constraints/offsets once. Inline elements
and borrowed scene participants use their actual logical layout parent, without
reparenting native Nodes. Plain native boundaries and independent Entries remain
boundaries; generic actors have no inferred size. Native Controls retain their
minimum/size-flag/Container/GUI contracts and do not acquire this unit API.

A fixed/unit dimension is an independent reference. A grow-assigned natural axis
can reference its allocated content. An auto axis that would derive its own size
from percentage descendants is unanchored/cyclic: that reference resolves to zero
and reports a warning, with no iterative solver. Give the containing axis an
independent dimension or grow allocation. Missing ordinary/proof references follow
that deterministic zero rule. A native Control's contents remain Godot-owned.

**L07 #160 corrects the former root restriction:** an independent2D Entry has its
current native visible Viewport as an implicit containing rectangle. Root100%
and100vw/100vh give identical geometry;50% uses half an axis and150% deliberately
overflows. The same context applies to all eligible root percentages: dimensions,
padding/margin edges, direction-aware gap and additive x/y. Root padding resolves
against the viewport even if root dimensions are fractional. Root margin remains
an outer request with no layout parent to consume it; it does not move or shrink
the independent root. Child percentages still use their actual immediate parent
content, after padding. Nested independent Entries use their own Viewport, never
the surrounding Box. SubViewport, project stretch and scale follow
get_visible_rect(), not outer OS chrome pixels. Existing size_changed signals
resolve changed references, without reparsing strings or recomposing Gogo.

This is a2D Entry scope rule, not a global percentage fallback. Auto/cyclic
ordinary content, pure proof roots and3D Entries retain their prior unavailable
reference semantics; no viewport plane or Z extent is inferred for3D. Explicit
3D viewport units/pixels_per_unit remain supported.

`x/y/z` are additive offsets from the flow slot. They do not consume extra flow
space or move siblings. Negative offsets and offsets beyond the parent are valid.
The parent content origin already includes its padding; offsets are applied once
through native transforms, including nested/projection translation. Declarative
axes are separate from native Vector2/Vector3 `position`. At Entry roots they add
to native position; changing the offset applies its delta, avoiding accumulation.
Outside an explicit Entry scope, participants retain the existing inactive-layout
boundary; use an Entry to arrange a free scene root. No absolute/out-of-flow mode
is introduced; #88 retains broader transform/position work.

## Remaining space

`grow={1}` is a dimensionless main-axis growth weight. Auto children retain their
preferred natural sizes, then positive weights share extra nonnegative space after
all preferred sizes, gaps and margins. A Spacer has zero natural size. Native
EXPAND_FILL adapters preserve minimum-constrained zero-basis sharing. Explicit
dimensions (including%) override growth on that axis. `stretch={1}` stretches only
auto cross axes; default0 retains natural sizing. It is one enum, not axis booleans.

```gogo
<Entry2D width="100%" height="100%">
    <VBox width="100%" height="100%">
        <Spacer grow={1} />
        <Text text="Hello World!" />
        <Text text="This is fun!" />
        <Settings />
        <Rose />
    </VBox>
</Entry2D>
```

A 100% height consumes the parent's applicable dimension budget. It is distinct from a
remaining-space spacer. [NativeHome](../examples/nested_layout/NativeHome.gogo)
and [responsive lengths](../examples/lengths/ResponsiveHome.tscn) are runnable.

## 3D and invalidation

The same abstraction/parser/resolver serves both native inheritance trees and the
existing mathematical core. Every 3D participant explicitly exposes
`pixels_per_unit` (positive finite, default100). Numbers, bare strings, px,
reference and viewport units convert using that participant's scale: 200 or
"200px" produces2 world units at100px/unit. Percent uses parent content already
in world units. Native positions, orientation, mesh AABBs and intrinsic native
bounds remain world-space values, without conversion or geometry stretching.
For old world-authored numeric fixtures, select `pixels_per_unit={1}` explicitly.
Z is unaffected by viewport Y unless explicitly authored with a viewport unit.

Property changes parse once into a retained spec. Layout resolves only on changed
spec/reference contexts; viewport signals and affected-branch dirty propagation
coalesce deferred work. Resizing does not recompose Gogo functions or rewrite
properties. Idle frames perform no parse, resolve, measure, arrange or scans.
No helper Node, geometry observation binder, polling or second solver is involved.

## L07A migration

`grow` replaces the experimental `flex` property with no alias. Update native
Scripts, GGX and stored scenes. This is a beta API break. Positive growth on an
auto natural widget adds space to its preferred size; it never implicitly shrinks
it. Use the zero-natural `Spacer` for pure remaining space.

[Parent policy, slot and future track contract](LAYOUT_FOUNDATION.md).

## Earlier L06 migration

The following names are deliberately removed, with no compatibility aliases:
`Pixels.parent_width/parent_height`, `EstragonPixels`, `fill_width/fill_height`,
`viewport_width_scale/viewport_height_scale`. Use unit dimensions (`"50%"`,
`"100vw"`, `"100vh"`) and `grow`/`stretch` as appropriate. Removed GGX attributes
produce a replacement diagnostic. Old L02/L05 fixtures/runners are replaced by
`tools/check-lengths.ts`; their committed evidence remains historical. Original
L01 Box arithmetic and native Control interoperability remain in the same core.

[Exact two-engine proof, rendered geometry and native Inspector limitation](evidence/L06_UNIT_LENGTHS.md). The inherited-relative-class native4.7 icon diagnostic remains separate; it is not claimed fixed.

## S01 border insets

Eligible 2D participants use the same grammar/context for `border_width` and `border_top_width/right/bottom/left`. Uniform width rejects auto; sides default to auto and restore the local shorthand, independent of assignment order. Left/right percentages use containing width; top/bottom use height. Border plus padding lies inside explicit dimensions and is subtracted once for child content (300 minus borders2/4 and padding10/20 gives264 at X12). Margins stay outside. No new 3D border API. See [styling](STYLING.md).

S02 hoists padding to Component2D. Button/Toggle uniform `padding="auto"` selects local14px horizontal/8px vertical defaults in the same core; numeric/unit shorthand replaces all four defaults, side auto follows shorthand. Other uniform padding domains still reject auto. No intrinsic text padding is added twice. See [widget styling](STYLING.md#s02--text-rect-button-and-toggle).

## L11 — minimum 2D dimensions

`min_width` and `min_height` are local outer border-box floors on Component2D
and its Box/HBox/VBox, Entry2D, Text, Rect, Button/Toggle, Spacer and Native2D
families. They accept the same nonnegative numeric pixels, physical/reference,
percent and viewport unit strings as dimensions. Default `0` means no additional
authored minimum. Explicit `"auto"` clears to effective zero and retains the
authored String getter. GGX omission of a previously declared minimum resets
that same retained Node to numeric zero. No max dimensions or new 3D fields ship.

```gogo
<VBox width="100%" min_width="280px" min_height="200px"
      background_color="#252b38" border_width="2px" padding="12px">
    <Text text="A readable minimum" min_width="120px" />
    <Button text="Continue" width="50%" min_width="96px" min_height="36px" />
</VBox>
```

Use ordinary explicit class aliases; bare Button is still Godot's native Control.
[MinimumGallery](../examples/lengths/MinimumGallery.tscn) is a runnable source-authored
example with nested Gogo composition, styled constrained Button, controlled Toggle
and native Button. Native Controls continue using `custom_minimum_size` and native
combined minimums; they do not acquire Estragon's two new fields.

An explicit width80 with min_width120 allocates at least120. An intrinsic/auto
preferred size also cannot go below the floor, while a larger intrinsic size is
retained. Author order is irrelevant. Getters retain their independent authored
specs: width stays80, min_width stays120; layout_size reflects the constrained
allocation. Floors include padding/border, not margins. Resolve first, then clamp
outer size, then subtract border+padding once for content. A120px clamped box with
left/right border2/2 and padding10/20 gives86px content atX12. A100% child uses that
content when the containing axis has the existing independent allocation authority.

Minimum percentages use the immediate parent content axis; min_width uses X and
min_height Y. Independent Entry2D uses its existing visible Viewport containing
rectangle. Viewport/reference units share the sole resolver and saturation bound.
A minimum alone does **not** turn an auto axis into an independent percentage
reference: auto/cyclic descendant references still resolve to zero with the existing
warning. Explicit dimensions or independently assigned grow/stretch allocation
provide authority. This avoids iterative percentage/minimum cycles or frame churn.

Parent-owned slots apply the combined floor in the existing StackPolicy. Ordinary
grow starts from preferred sizes including minima, then shares remaining space;
stretch also respects the floor. If the parent is too small, children preserve
minima, margins, gaps and order and overflow forward. Definite parents do not grow
implicitly, sizes do not become negative, and there is no CSS shrink or clipping.
Native expand water-filling retains its existing behavior. Authored and native
adapter floors combine by per-axis maximum, never by summing/overwriting them.
Transparent Gogo hosts forward the managed root's effective floor without a second
inset or new user fields. Native2D constrains its allocated slot only: native
render/physics bounds are neither scaled nor stretched.

Changed minima parse once and invalidate the affected branch through existing
signals. Resize resolves references without rewriting properties, reparsing or
recomposing Gogo. Equal writes and settled idle frames are quiet. Native setters,
compiler literal validation, complete-description preflight and Inspector use the
same grammar; invalid/negative/nonfinite/overlimit/type-invalid values preserve
previous valid specs and geometry. Authored diagnostics/maps and actual-path
publication rollback remain mandatory, with repaired editor/Play recovery.


L09-10 #176 adds optional `row_gap` / `column_gap` on native2D participants:
`auto` falls back to the physical-axis `gap`. The shared parser and immediate-parent
non-dimension percentage references are unchanged. L12 refines child width/height budgets separately. Grid tracks alone additionally accept positive
`Nfr`; ordinary dimensions/minima/offsets never do. [Wrap/Grid contract](RESPONSIVE_LAYOUT.md).

### UX01 maximum 2D dimensions

`max_width`/`max_height` use the existing extent Length units with `auto` meaning
unbounded and omission resetting auto. They cap the owning border-box; minima and
native floors win, margins remain outside and descendants keep visible overflow.
See [maxima, capacity and scrolling](UX01.md#available-capacity-and-maximum-dimensions).

U03 scrollbar thickness targets share this grammar. `scrollbar_size` forbids auto; per-axis overrides allow auto to inherit it. Their `%` basis is the owner’s pre-gutter inner width/height, with actual strips capped to that axis; [scrolling contract](SCROLLING.md#u03--stable-inside-gutters-and-native-skins).
