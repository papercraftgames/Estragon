# L02 — observed parent-relative pixel helpers

`EstragonPixels.parent_width(context: Node, percent: float) -> float` and `parent_height(context: Node, percent: float) -> float` return ordinary numeric pixel lengths. Import the helper as `Pixels` through the normal editor/import service, or use its explicit preload/canonical class name. There is no unit-valued dimension, percent attribute, per-element compiler rewrite or alternate binding system. `width="50%"` remains a source-located error.

```gogo
# ResponsivePanel.gogo; normal Element/Pixels/VBox preload declarations omitted.
func build_view() -> Element:
    return <VBox width={Pixels.parent_width(self,50.0)}
                 height={Pixels.parent_height(self,75.0)}>
        <Text text="Half the parent's content width" />
    </VBox>
```

Context is **self in the currently executing Gogo component composition**. Its managed root receives the returned pixels. Use a normal child Gogo component for an inline nested target: one function's `self` identifies one host, not each nested tag. The helper does not infer a destination property or a syntactic GGX parent. Passing an unrelated Node to reach a sibling, ancestor or arbitrary geometry source falls back to0 with a warning. Calls outside composition likewise return0 with a warning; imperative code should use explicit native geometry rather than expecting an implicit reactive binding.

The reference is the containing, same-dimensional **layout participant's arranged content box**, not its measured intrinsic size, viewport, remaining flex space, or outer margins. Structural Gogo proxy hosts introduce no content box and are skipped until the containing participant is reached. Explicit Entry scopes are independent. Missing/unscoped parents, plain native boundaries, opaque native Control/Container parents and3D contexts return0. This is a2D helper; existing3D world-unit/layout contracts do not acquire pixel conversion.

## Reference geometry and safe dependency direction

A parent content axis is independently allocated when its actual bounds are fixed, supplied by a positive Entry viewport scale, or allocated by fill through a chain anchored at such bounds. The shared core subtracts resolved padding and clamps content at zero. Helper width uses X and helper height Y explicitly. Parent margins affect the parent's own allocation once; they are not deducted again from its content. The child's margin is outer space in its parent and does not change the percentage reference. Parent gaps and siblings do not reduce the reference; they still participate normally in allocating **remaining** fill space.

An auto/natural parent axis that depends on its children is **unavailable as a percentage reference**. That axis returns0, even if fixed siblings currently give it a nonzero intrinsic extent. This avoids solving `parent = child + other content; child = percent(parent)` repeatedly. Set an explicit parent bound, use viewport-backed Entry sizing or an independently allocated fill chain to establish a responsive basis. Width and height qualify separately. A policy change from auto to fixed wakes dependent components even when the previous arranged size happens to equal the new fixed size.

Before the first arrange, a helper bootstraps at0 and subscribes to the parent geometry signal. First arrangement schedules the existing affected component computation; ordinary changed-property commits then feed the existing layout pass. Deep percent children settle from ancestor to descendant. No user initialization callback, resize handler, explicit invalidation, hook or per-frame polling is required. No reconciliation/helper state is stored on user Nodes/models/resources.

| Input/reference | Numeric output and layout behavior |
| --- | --- |
| 50, parent content width600 |300 pixels, independent of sibling fill shares |
|75, parent content height360 |270 pixels |
| Fractional nonnegative percentage | Fractional pixels, no deliberate rounding; normal Godot float/vector precision applies |
|0 percentage or zero content | Fixed0 pixels; existing fill flags do not override a fixed dimension |
| Above100 | Allowed; children may overflow using the existing visible, sequential overflow rules |
| Negative/NAN/INF percentage |0 plus a warning; no invalid native property commit |
| Result outside finite native vector storage |0 plus a warning |
| Auto/cyclic, missing or incompatible reference axis |0; no iterative fixed-point fallback or guessed viewport |

Multiple percent siblings each use the same full parent content extent. Two50% children plus margins/gaps can overflow; percentages are not flex weights. Fixed dimensions computed by helpers retain existing precedence over fill. Native Control minimum floors remain intact and can overflow alongside percent-sized children. Padding/margin are the existing [L01 pixel box model](NODE_UI.md#l01--pixel-box-model).

## Observation, lifetime and boundaries

The helper registers reads with the **same external composition manager** used by Gogo `@bindable` getters. The existing core publishes a signal only when its usable arranged reference changes (including availability), and publishes parent-edge changes for logical reparenting. Signals schedule/coalesce normal component execution and desired pixel-property commits after layout; they do not synchronously rebuild Nodes inside arrange. Unrelated components and clean sibling measurements stay cached, and idle trees do no work.

Native exit/re-entry suspends/rebinds the normal weak subscriptions. Logical borrowed-child projection can change the containing parent without native reparenting; its observed parent-edge signal retargets the helper. Transparent wrapper roots cannot become their own sizing anchors. Native/keyed Node identities, scene parent/owner, pointer transforms, native GUI and pack/reload remain authoritative. Arbitrary imperative callbacks that mutate layout in response to themselves are outside this helper's downward dependency contract; this API is not a general constraint solver.

Run [ResponsiveHome.tscn](../examples/parent_pixels/ResponsiveHome.tscn) to resize a viewport-backed parent and toggle25%/50% width with a retained button; height stays75%. [ResponsivePanel.gogo](../examples/parent_pixels/ResponsivePanel.gogo) uses only normal helper calls and bindable data. The nested native Box allocation is the source of truth. [Focused runner](../tools/check-parent-pixels.ts) records exact native runtime/editor/graphics evidence on only official Linux4.0.4/pinned4.7.0. Live [#129](https://github.com/papercraftgames/Estragon/issues/129)/its sole PR controls verification/review status; no release or merge is implied.
