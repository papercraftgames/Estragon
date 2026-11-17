# Local native 2D styling — S01 / S02 / S04

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

## Historical S01 boundary and follow-ups

The following records S01 at merge; S02 below supersedes its temporary widget exclusion.

Text, Rect and Button/Toggle still use their existing legacy foreground painters.
They explicitly reject the new shared style properties in compiler/preflight and
native setters until S02, rather than accepting hidden/competing paints.
Text `color`, Rect `fill`, Button pointer palette/padding and their native input
behavior remain unchanged. No redundant text_color/fill_color API is introduced.
All ordinary native Godot Controls retain their own theme/drawing internals.

S02 owns their unified content/background/state contract and Rect fill migration.
Historical S01 scope anticipated S03 resources/themes; owner revision #173 supersedes
that plan with general-purpose [GGX attribute spreading](GOGO_LANGUAGE.md#ordered-attribute-spreads-s03).
No style prop, resources, tokens or framework style utilities are authorized. Historical S04 intent included shadows/transitions; revised #187 excludes both.
S04 below owns radii, native texture/gradient values and rectangular child clipping.
3D styling/materials and
alignment/wrap/Grid are outside S01. The known inherited-relative-class4.7 icon
limitation remains unchanged; editor field proof uses the actual shared direct
Node2D participant API, not a class-cache patch or an error exemption.

## S02 — Text, Rect, Button and Toggle

S02 #169 removes the temporary S01 widget exclusions. All four widget families
and their normal subclasses use the same Component2D background/border hook.
Widget `_draw` methods add only foreground glyphs/checked indicator. Their
native parentage, font subscriptions, pointer router and description manager
remain unchanged. There is no cascade, background Node or per-frame work.

Padding is declared once on Component2D, including its five authored fields.
It uses the same Length grammar and pure core as Box. Text measures only glyph
metrics; the core adds border+padding once. Text's first baseline is at content
origin plus the native font ascent; explicit lines use native font height.
Button centers its label in the content rectangle (leading border+padding,
outer extent minus both inset sets, clamped to zero). Overflow does not imply
clipping; text is not drawn when either content axis is zero. The outer allocated
Button rectangle remains the transformed native hit area, including its border
and padding.

An unstyled Button/Toggle retains14px left/right and8px top/bottom padding.
`padding` defaults to `"auto"` **only on these families**, selecting that local
class default in the same core. It is not four authored side overrides. Set
`padding="10px"` for10px on all four sides; explicit side values override it in
any assignment order, and side auto restores the local shorthand. Uniform auto
on Box/Text/Rect remains invalid. Explicit0 removes all default padding. Native
Inspector undo/redo and PackedScene retain the distinction; no hidden permanent
PADDING addition is made to the label measurement.

| Widget property | Default / behavior |
| --- | --- |
| Text `color: Color` | white, direct local glyph color; no text_color alias |
| Text background | transparent |
| Rect background | white; canonical authored Color/hex field |
| Rect `fill: Color` | legacy synchronized view of normalized background Color |
| Button background | #514174, normal state only |
| hover_background_color | #705a9e |
| pressed_background_color | #302440; held AND hovered |
| disabled_background_color | #38343f; wins over all other states |
| Toggle checked_background_color | #227a60; checked wins over hover/pressed |

Every state color uses the shared finite Color/hex/transparent parser and retains
its authored value/type. `get_background_color()` returns the effective normalized
state Color. Setting normal background does not compute or replace other state
colors. Checked Toggle retains its #65f4b0 underline, placed inside the border
edges; disabled label alpha remains0.5. Pointer release emits exactly one native
`pressed`; Toggle's user activation emits one `value_changed`, while programmatic
`value` projection remains quiet. Existing controlled `bind:value` keeps its
native bool lvalue behavior.

Rect `background_color` is the canonical visible fill. Native successful writes
to either it or legacy `fill` update the same cached paint, last write wins;
invalid writes retain the previous good value. Reading `fill` returns normalized
Color even when canonical background was authored as a hex String. PackedScene
stores only the canonical value, preserving its type. Existing fill-only GGX and
stored scenes remain supported; migrate new authoring to background_color.
**Authoring both on one GGX Rect is a source-located conflict**, in either order,
and computed descriptions reject before any commit. Rect never paints a second
background over the shared border. No fill_color alias is introduced.

Color and pointer/disabled/checked state changes queue redraw only. Text/font
metrics and padding/border updates invalidate the affected existing layout branch.
Equal writes and settled idle frames remain quiet. Native Inspector exposes each
applicable state color and the sole padding control, with validation and undo.
A shared native Texture2D @icon supplies inherited widget Inspector categories
through Godot's supported script-icon path; this is neither class-cache mutation
nor an engine error exemption. Exact tested engine outcomes remain in the task
evidence; earlier inherited-icon failures remain truthful historical evidence.

[WidgetGallery](../examples/styling/WidgetGallery.tscn) is the runnable source-authored
example, with styled Text/Rect, four pointer-state Buttons, controlled and unchecked
Toggles, native Control and nested Gogo child. Revised S03 #173 adds only ordinary
GGX Dictionary attribute spreads, not shared resources/themes/tokens or a style prop.
Future framework style support requires a separate owner design decision.
Focus/navigation and S04 advanced visuals remain separate.3D acquires no style API.

## S04 — opt-in native surfaces

[Owner #187](https://github.com/papercraftgames/Estragon/issues/187), ADR-0028,
adds direct inherited Component2D properties. Box/HBox/VBox/Grid/Entry2D and
Text/Rect/Button/Toggle use the same surface hook; native Godot Controls keep
their own theme skins. [SurfaceGallery](../examples/surfaces/SurfaceGallery.tscn)
is source-authored Gogo with a checked-in native GradientTexture2D resource.

```gogo
const PANEL_TEXTURE = preload("../panel_gradient.tres")
func build_view() -> Element:
    return <VBox width="320px" height="160px" padding="16px"
                 background_color="#202b38" background_texture={PANEL_TEXTURE}
                 background_texture_mode="stretch" border_color="#88aac4"
                 border_width="2px" corner_radius="12px" clip_content>
        <Text>Native surface</Text>
    </VBox>
```

Use ordinary explicit aliases, as in the gallery. Native textures/gradients are
Resource values, not authored children. Reuse Dictionaries with ordinary GGX
spreads; no style prop, framework style Resource, cascade or inheritance appears.

| Property | Default / contract |
| --- | --- |
| corner_radius | 0; finite nonnegative numeric pixels or shared Length string |
| corner_radius_top_left / top_right / bottom_right / bottom_left | auto; local override of shorthand, auto/omission restores fallback |
| background_texture | nullable native Texture2D, including GradientTexture2D |
| background_texture_mode | stretch or tile; default stretch |
| clip_content | false; rectangular child viewport after border/padding |

Corner percentages deliberately use **min(owner border-box width, height)**,
unlike ordinary parent-referenced layout lengths. Viewport/physical units retain
the shared [Length](LENGTHS.md) conversions and finite numeric bounds. Resolve
four corners, then uniformly reduce them until every adjacent pair fits its
actual edge. Zero extents are safe. Radius does not enlarge layout or pointer
bounds, consume padding or change the exact border width/side precedence. Corner
overrides win independent of attribute/spread order; omission resets an owned
override on the same retained Node.

The square/no-texture path remains the original floating-point rectangle/strip
painter, with identical blending and corner ownership. Effects use cached native
polygon/UV/ArrayMesh commands in that same hook: base effective widget color,
optional texture inside the border contour, border, then native widget foreground.
Textures do not overwrite border strips or square off rounded corners. Stretch
maps the inner border rectangle to the full texture; tile repeats at native
texture-pixel dimensions, with a private CanvasTexture repeat override that does
not change the user's CanvasItem settings or Resource. Native CanvasTexture
normal/specular settings are retained when supplied.

Rounded arcs use **16 chords per quarter circle**, floating-point coordinates,
and Godot's native polygon/triangle rasterization, without added edge smoothing.
The maximum circle-to-chord deviation is `radius * (1 - cos(PI/64))` before
native pixel rasterization. This is bounded contour approximation, not an
integer StyleBoxFlat conversion or a claim of vector-perfect antialiasing.
The inner contour intersects the outer contour for extreme asymmetric insets;
cached nonoverlapping border bands avoid texture escape and double-blended seams.
Subpixel geometry is subject to native float/polygon raster precision; dimensions
and fractional square borders remain exact authored layout values.

Geometry/UV/mesh state rebuilds only for relevant size/radius/border/texture
changes, outside draw. Color/state writes redraw without rebuilding geometry;
equal writes and idle remain quiet. Native texture and nested Gradient `changed`
signals redraw referencing surfaces only. Replacement, tree exit/reentry and free
disconnect/reconnect those subscriptions. Viewport-relative radii subscribe only
while needed; a viewport resize can update a fixed-size surface without layout
or function recomposition. Border/padding/font changes retain normal affected
layout invalidation. No per-frame processing, scene scan, texture regeneration,
shader/material system or extra surface Node is introduced.

`clip_content` shares the [U02 private viewport/input service](SCROLLING.md).
It clips children to the content rectangle, **not the rounded surface contour**.
The owner's own surface and native foreground remain on their normal draw path.
Scrolling already clips: enabling both reuses one helper ancestry/GUI guard.
Turning off both restores ordinary overflowing paint/input and zero offset/range;
helpers already created remain attached/inert for retained focus/parentage.
Never-enabled components create none. First enabling may adopt native children
behind private ancestry; subsequent clipping toggles update clip/input state
without remeasuring unchanged geometry. Native logical child accessors, owners,
pack/reload, nested scrolling and native Control capture/focus retain U02 rules.

Wrong resource classes/enums, malformed colors, negative/nonfinite radii and
unsupported Node targets reject through native property metadata and shared
compiler/runtime preflight before a description commits. Existing S03 precedence
still applies: shorthand plus an individual corner is valid; duplicate explicit
attributes reject, later spreads override earlier entries. Invalid native setter
writes retain the prior value; omitted spread props restore their owned defaults.
Inspector uses the existing Length editor for radii, native Texture2D selector,
enum and Bool fields, with native undo/redo and scene persistence.

Shadows, transitions, descendant rounded masks, new focus/text features and 3D
effects are excluded. Exact tested engines, native captures, failures and limits
are recorded in #187/its sole PR and the committed S04 evidence report; target
support does not imply fresh certification of other engines/platforms.

D07 updates unstyled framework Button and unchecked Toggle defaults to normal
`#383838`, hover `#505050`, pressed `#252525`, disabled `#303030`, including
initial cached state. Checked Toggle stays `#227a60` with `#65f4b0` underline.
Explicit colors remain authoritative. See [Button imports](BUTTON_IMPORTS.md).
