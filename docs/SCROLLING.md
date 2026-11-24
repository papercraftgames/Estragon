# U02 — inherited native 2D scrolling

Owner [#185](https://github.com/papercraftgames/Estragon/issues/185) supersedes the
public wrapper from merged UX01 #183/PR #184. Scrolling is an inherited capability
of `EstragonComponent2D`. Box/HBox/VBox, Grid, Entry2D and their subclasses keep
their native class, child layout policy, scene ownership and retained identity.
No public ScrollView class, script, catalog entry or compatibility alias remains.

## Authoring

Use ordinary explicit Gogo preload aliases, as in
[InheritedScrolling.gogo](../examples/ux01/InheritedScrolling.gogo):

```gogo
<VBox width="100%" height="300px" vertical_scroll gap="12px">
    <Text>First item</Text>
    <Text>Second item</Text>
    {render_more_items()}
</VBox>
<Grid columns={3} height="260px" vertical_scroll row_gap="10px">
    {render_cards()}
</Grid>
```

Children are direct authored elements; zero, one and many are valid. Existing bare
Bool attributes, String bodies, spreads, keys, conditions, Grid placements and
native Control adapters retain their contracts. Unrelated native Control/Container
and 3D classes receive no new properties. Leaf participants inherit the API but
have zero range without measured layout content. Generic Nodes do not acquire a
universal size; native geometry retains its existing bounded-provider contract.

The inherited properties are `horizontal_scroll: bool`, `vertical_scroll: bool`
(default false), writable `scroll_offset: Vector2` (default zero), and read-only
`scroll_range`/`content_extent`. Offsets require finite nonnegative components.
Enabled axes clamp to `max(0, content_extent - visible content extent)`; disabled
axes clamp to zero. When geometry and authored offsets change together, geometry
commits first and the existing arrangement resolves/clamps the pending offset.
Stable offset-only updates immediately change translation and scrollbar values,
without measure/arrange or Gogo recomposition. Spread omission restores owned
class defaults without overwriting unrelated imperative changes.

## Viewport versus child layout

Both flags false preserve ordinary overflow painting/input and allocate no private
scroll nodes on never-enabled components. With at least one flag true, the content
rectangle after border/padding clips both visual axes. Only enabled axes scroll.
Normal explicit/min/max/percent/viewport lengths, grow/stretch and parent slots
allocate the outer viewport. Auto/unbounded size can naturally fit content and
have zero range; flags do not invent an allocation or viewport fallback.

Scroll axes are independent state on the same mathematical core. Stack still
sums/aligns/grows its children, Wrap still groups lines, and Grid still computes
tracks/spans/areas. Enabled axes measure natural unbounded content; non-scroll axes
keep normal reference/capacity authority. Enabled indefinite axes do not become
circular percentage references. Insets are consumed once. Child slots retain
ordinary logical coordinates; a private native clip/translation pair compensates
the clip origin. Descendant clipped viewports contribute their visible allocated
bounds to ancestors, so hidden nested content does not create an outer range.

A private `internal/scroll_2d.gd` service owns only native clip/translation/bars and
weak input subscriptions. The owner's existing coordinator/model remains the
layout authority; no second scene graph, Container solver or compositor exists.
Flag toggles retain authored children, order, owners, native focus and offsets
where enabled. Disabling both makes the retained private clip inert, hides bars,
clears effective offset/range and stops capture subscriptions. Previously enabled
components retain attached inert helpers for stable parentage/focus and reuse;
helpers are not orphaned or duplicated. Never-enabled components have none.

Native physical ancestry can include these private nodes. Use inherited
`get_layout_children()` and `get_layout_child(name)` to inspect logical authored
children and names; these return real Nodes and do not replace native Node APIs.
Native `get_parent()`/`get_node()` paths remain actual SceneTree paths. Don't
hardcode implementation helper names. Framework reconciliation/name conflict,
foreign rescue, Grid placement and native bounds discovery use logical children.
Persistent native authored children keep owners and serialize the necessary
private ancestry. Generated Gogo views/helpers remain transient and remount after
reload. Removal/re-entry restores registry connections without duplication.

## Native interaction

Wheel and horizontal/Shift-wheel use 40 logical units per wheel factor;
InputEventPanGesture uses 40 logical units per delta component. Hit geometry uses
native canvas transforms, including translated/scaled parents. The deepest
eligible viewport consumes movement; a saturated axis can leave the event for an
ancestor. Events outside its content rectangle are untouched. Scrollbars use
native GUI/range handling and are appended after the clip branch in SceneTree
order, so underlying native Controls cannot steal their clicks/drags.

The existing scoped weak GUI guard cancels BaseButton's cached press with public
`NOTIFICATION_SCROLL_BEGIN` on outside-clip release or scroll movement. Custom
Estragon picking intersects ancestor clips and excludes bars. Entry2D explicitly
chains base scrolling and its pointer router, preserving exactly-once custom and
native Button/Toggle handling. Native focus/Container interiors stay Godot-owned.
Touch-drag emulation, new keyboard/focus management and virtualization are absent.

## Intentional beta source migration

**Obsolete UX01 wrapper form**, retained here only to explain migration:

```gogo
<ScrollView height="300px" vertical_scroll padding="16px">
    <VBox width="100%" gap="8px">...</VBox>
</ScrollView>
```

**Current form:**

```gogo
<VBox height="300px" vertical_scroll padding="16px" gap="8px">
    ...
</VBox>
```

Remove the obsolete preload and class/script references. Transfer viewport
width/height/min/max, scroll flags/offset and desired viewport border/background/
padding onto the actual layout component; retain its gap/direction/alignment or
Grid tracks/placements. Remove redundant inner width 100% only when it represented
the viewport content width. Distinct old wrapper/content padding, margins,
backgrounds, sizes or transforms require an explicit author choice: preserve a
real nested group if both layers had meaning. There is no silent source migrator.
Replace old one-root discovery with logical child/name accessors. Historical
UX01 ADR/evidence remains marked superseded rather than rewritten as U02 proof.

## Verification boundary

The existing `tools/check-ux01.ts` harness adds direct-child inherited coverage,
not another test universe. Only official Linux 4.0.4 and pinned Linux 4.7.0 are used.
It exercises immutable direct-Yarn node_modules, source/maps/UIDs and removed-class
invariants, native rendered layout/input, toggle/lifecycle/pack, Inspector offset/
bool undo, current/main Play rejection/repair and cold restart. Exact commands,
source/artifact hashes, outcomes, failed attempts and inspected captures are in
#185/its sole PR and committed evidence. Manual interactive smoke is reported
separately, not a physical-key gate. Routine CI remains bounded at 60 seconds.

S04 `clip_content` independently opts into this same rectangular viewport with
zero scroll range when both axes are off. Both scroll flags **and clip_content**
false preserve visible overflow; no second clip/input tree is created. Surface
corner radii affect owner paint only, not the descendant clipping rectangle.

L12 clarifies [definite fraction viewports versus intrinsic auto rows](PARENT_PERCENTAGES.md#auto-rows-allocation-and-scrolling): hidden content is not a viewport minimum in a definite all-fr span. Actual inset/intrinsic/native/authored floors remain; implicit auto rows can overflow and unbounded scrolling invents no viewport. Positive grow uses at least the actual viewport once.
