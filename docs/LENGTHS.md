# Unit lengths — L06

L06 #156 intentionally replaces the experimental numeric-only/helper APIs. All
Estragon dimensions, declarative offsets, gaps and applicable 2D Box padding and
participant margins accept `int`, `float`, or a validated `String`. Ordinary
Godot Node/Control properties retain their native types. No imports or component
extraction are needed for inline percentages.

```gogo
func build_view() -> Element:
    return <Entry2D width="100vw" height="100vh" padding="16px">
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
Box bounds visible; Box has no background styling API. The same properties work
in native GDScript (`panel.width = "50%"`) and the enabled addon's native Inspector
length entry, with native undo/redo and scene storage. Inspector bare numerics
produce numbers; units and auto produce strings. Reads preserve the exact authored
value/type; `layout_size` and `requested_extent()` are derived layout outputs.

| Value | Resolution |
| --- | --- |
| `200`, `200.0`, `"200"`, `"200px"` | 200 logical layout pixels |
| `"50%"` | half the immediate layout parent's independently arranged content axis |
| `vw`, `vh` | one hundredth of the containing native visible Viewport width/height |
| `vmin`, `vmax` | one hundredth of the smaller/larger visible Viewport axis |
| `in`, `cm`, `mm`, `q` | 96px, 96/2.54px, 96/25.4px, 96/101.6px respectively |
| `pt`, `pc` | 96/72px, 16px respectively |
| `auto` | intrinsic dimension; on individual inset edges, inherit shorthand |

`2.5in = 240px`, `12pt = 1pc = 16px`. Inches denote the CSS reference scale,
not measured physical monitor inches. Font metrics (`em/rem/ex/ch`), `calc`,
`min/max` and monitor-DPI modes are deferred. There is no general CSS parser.

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

Width/x use horizontal parent content; height/y use vertical; depth/z use depth.
Left/right edges use horizontal references and top/bottom use vertical. A scalar
padding/margin percentage resolves separately on each edge's axis. Gap uses the
parent stack's main axis. Padding is inside the border box; margin is outside;
neither collapses. Parent allocation subtracts padding, margins and gaps once.
A child's percentage width is the full parent content width times its fraction,
without subtracting that child's margins. Values above100% intentionally overflow;
there is no clipping or implicit shrink.

Transparent Gogo hosts forward the root constraints/offsets once. Inline elements
and borrowed scene participants use their actual logical layout parent, without
reparenting native Nodes. Plain native boundaries and independent Entries remain
boundaries; generic actors have no inferred size. Native Controls retain their
minimum/size-flag/Container/GUI contracts and do not acquire this unit API.

A fixed/unit dimension is an independent reference. A flex-assigned natural axis
can reference its allocated content. An auto axis that would derive its own size
from percentage descendants is unanchored/cyclic: that reference resolves to zero
and reports a warning, with no iterative solver. Give the containing axis an
independent dimension or flex allocation. Missing/root percent references follow
the same deterministic zero rule. A native Control's contents remain Godot-owned.

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

`flex={1}` is dimensionless main-axis growth with zero basis, matching a spacer.
Positive weights share nonnegative remaining space after fixed/natural/% siblings,
gaps and margins. Native minimum floors reserve constrained shares first. Explicit
dimensions (including%) override growth on that axis. `stretch={1}` stretches only
auto cross axes; default0 retains natural sizing. It is one enum, not axis booleans.

```gogo
<Entry2D width="100vw" height="100vh">
    <VBox width="100%" height="100%">
        <VBox flex={1} stretch={1} />
        <Text text="Hello World!" />
        <Text text="This is fun!" />
        <Settings />
        <Rose />
    </VBox>
</Entry2D>
```

A 100% height consumes the parent's entire content height. It is distinct from a
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

## Migration

The following names are deliberately removed, with no compatibility aliases:
`Pixels.parent_width/parent_height`, `EstragonPixels`, `fill_width/fill_height`,
`viewport_width_scale/viewport_height_scale`. Use unit dimensions (`"50%"`,
`"100vw"`, `"100vh"`) and `flex`/`stretch` as appropriate. Removed GGX attributes
produce a replacement diagnostic. Old L02/L05 fixtures/runners are replaced by
`tools/check-lengths.ts`; their committed evidence remains historical. Original
L01 Box arithmetic and native Control interoperability remain in the same core.
