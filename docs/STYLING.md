# Local native 2D styling — S01

S01 #167 adds native backgrounds and square borders to eligible Estragon 2D
participants: Component2D, Box/HBox/VBox, Entry2D, Spacer and bounded Native2D
adapters. Values and painting share one helper owned by Component2D; layout
remains in the existing mathematical core. There is no background/stroke Node,
stylesheet, wrapper, selector or implicit style inheritance.

```gogo
func build_view() -> Element:
    return <Entry2D width="100%" height="100%" background_color="#171b24" padding="8px">
        <VBox grow={1} stretch={1} margin="8px" padding="16px" padding_top="24px"
              gap="12px" background_color="#252b38" border_color="#8295bc"
              border_width="2px" border_bottom_width="5px">
            <Spacer grow={1} />
            <Text text="Hello!" color={Color("#ffcc66")} />
            <Settings />
            <Rose />
        </VBox>
    </Entry2D>
```

Use normal explicit imports and project Gogo components. The runnable
[StyleGallery](../examples/styling/StyleGallery.tscn) includes differently painted
HBox/VBox, asymmetric edges,50%/100% children, native and Estragon Buttons and
nested Settings/Rose. `grow`/cross stretch let the parent subtract outer margins;
a100% dimension remains the full containing content dimension and does not
subtract its own margin.

## Values and local defaults

| Property | Default / contract |
| --- | --- |
| background_color | transparent; native finite Color or validated hex/transparent String |
| border_color | transparent; same color contract |
| border_width | 0; nonnegative numeric pixels or any supported Length unit; auto rejects |
| border_top_width / border_right_width / border_bottom_width / border_left_width | auto; local override of the shorthand; auto restores shorthand |
| padding and padding_top/right/bottom/left | existing Box contract; inside border |
| margin and margin_top/right/bottom/left | existing 2D participant contract; outside painted border-box |
| gap | existing flow-axis spacing between children |

Color strings allow trimmed #rgb, #rgba, #rrggbb and #rrggbbaa with case-insensitive
hex digits, or the exact lowercase `transparent`. Other names/malformed strings,
non-Color/non-String values and nonfinite native channels reject. Native Color
constants/expressions remain supported. Public getters retain the authored value
and type; the helper caches its normalized Color. Inspector hex entry and native
Color picker preserve String/Color respectively, with native undo/redo and helpful
invalid-entry feedback. Direct GDScript writes use the same parser as GGX/preflight.

Border widths use [the sole Length grammar](LENGTHS.md), including reference and
viewport units and immediate-parent percentages. Left/right percent borders use
containing width; top/bottom use containing height. Root2D Entry uses its visible
Viewport context for all relative specs. Local per-side overrides win regardless
of assignment/attribute order; setting a side to auto resets it. Omitting a
previously declared GGX border-side attribute also removes that local override
on the retained Node. This is a scoped side-override rule, not a general change
to ordinary native property omission semantics.

No property cascades into descendants. An unstyled child keeps a transparent
background, not a copied parent color. Seeing an ancestor through transparency
is normal native compositing. Text keeps its own explicit `color` or white local
default. Native CanvasItem transforms/modulation still have their normal Godot
semantics; Estragon adds no style lookup along the parent chain.

## Border-box, content and paint

Explicit width/height include border and padding. Content extent is border-box
minus both inset sets, clamped to zero; child origin is leading border + leading
padding + child margin + additive offset. Natural preferred measurement includes
border and padding once. A300px box with left/right border2/4 and padding10/20
has264px content atX12. A100% child gets264px before its own margin/offset.
Transparent Gogo hosts forward one measured root and do not subtract insets again.
Margins remain outside paint; gap remains exclusively between children.

Paint uses native CanvasItem draw commands: full background, then four filled
edge strips inside the border-box. Top/bottom own the corners so translucent
border strips never double-blend. Widths stay floating point for layout and draw
commands; there is no integer layout rounding. Godot rasterizes fractional edges.
Paint widths clamp inside very small extents and zero-size boxes emit no draw
rectangles. Fixed/natural child overflow remains the existing contract; S01 adds
no clipping or implicit shrink when content cannot fit.

The shared hook connects to the native `draw` signal before the script `_draw`
callback, including for Box subclasses with their own foreground override. Style
paint precedes normal child CanvasItems. Color changes only queue_redraw;
arranged-size and width changes queue redraw through the same base lifecycle.
Border changes invalidate the existing affected layout branch. Repeated equal
writes are quiet; idle frames do not parse, lay out or redraw. Style/length stats
expose counters for the native acceptance proof, not a new scheduling system.

## S01 boundary and follow-ups

Text, Rect and Button/Toggle still use their existing legacy foreground painters.
They explicitly reject the new shared style properties in compiler/preflight and
native setters until S02, rather than accepting hidden/competing paints.
Text `color`, Rect `fill`, Button pointer palette/padding and their native input
behavior remain unchanged. No redundant text_color/fill_color API is introduced.
All ordinary native Godot Controls retain their own theme/drawing internals.

S02 owns their unified content/background/state contract and Rect fill migration.
S03 owns explicit shared resources/tokens/themes (no CSS cascade); S04 owns radius,
shadows, gradients, textures, clipping and transitions.3D styling/materials and
alignment/wrap/Grid are outside S01. The known inherited-relative-class4.7 icon
limitation remains unchanged; editor field proof uses the actual shared direct
Node2D participant API, not a class-cache patch or an error exemption.
