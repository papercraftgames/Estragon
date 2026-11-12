# E08 — borrowing scene-authored children in GGX

Add `Settings` and `Sprite2D` beneath a Gogo `Home` through Godot's Scene dock. They remain normal native children of Home. To include the existing instances in Home's desired layout, use a native child expression:

```gogo
func build_view() -> Element:
    return <Entry2D>
        <VBox gap={8.0}>
            <Text text="Hello World!" />
            {get_children()}
            <Text text="After Settings" />
        </VBox>
    </Entry2D>
```

Use normal completion to import Element/Entry2D/VBox/Text. There is no SceneChildren/Slot tag or implicit `children` variable. `get_children()` is Godot's existing method; helpers, filtering, nested arrays and individual Node expressions work through the same child normalizer. The root still returns an Element. Run [SceneHome.tscn](../examples/nested_layout/SceneHome.tscn) for this arrangement with an existing Settings Exit button and a free-positioned Sprite2D.

`<Settings />` creates a new managed instance from source (E07). `{get_node("Settings")}` borrows the already-authored instance. Do not use both to represent the same intended child. With no reference expression, native children keep their existing behavior and do not implicitly join the returned Box.

## Identity, eligibility and ordering

A referenced Node must be a **persistent direct child of the rendering host**, with a non-null scene owner. It keeps its exact instance, native parent, owner, path, script, exported properties, signals and native sibling order. Nested scene roots may have an outer owner; their authored descendants keep their separate inner owners. A nested Gogo host can borrow its own direct children in its own view.

Framework-created nodes are recognized through external reconciliation records and ignored, including the managed root returned by second and later `get_children()` calls. Unowned direct runtime children are ignored and remain native actors. References to external/non-direct nodes and duplicate occurrences of one borrowed Node anywhere in a desired view reject the whole composition before commit; the previous valid tree remains. Diagnostics name the authored containing element and native path. Multiple expressions are allowed when their node sets are disjoint. Scalars, Dictionaries and non-Node Resources remain invalid child values. Array cycles/depth limits and Element key rules still apply; borrowed identity is the native instance, not an Element key.

Default order is the expression's array order. Normal `get_children()` gives native sibling order; a filtered/reversed array deliberately chooses another logical order. Native add/remove/reorder notifications schedule the interested computation without polling. Assign the persistent owner as part of the same native add transaction, as Godot's scene editor does. Later arbitrary changes to `owner` or mutations of a privately cached Array have no universal notification; reassign an observed bindable reference when changing such a custom source.

## Layout and native transform authority

Borrowing supplies a **logical layout edge**, held outside user nodes. A same-dimensional Estragon participant or a Gogo host returning a participant contributes its existing measured/fixed/fill footprint at that expression's slot. It uses the same layout coordinator/core as ordinary GGX. Native ancestry never changes. Translation converts from the logical parent's coordinates through Godot's native transforms into the borrowed node's actual native coordinates, once. Native rotation/scale remain unchanged; their footprint follows the existing participant/adapter contract. Descendant content changes invalidate affected layout branches without recomposing Home. Event-driven arrange refreshes borrowed translations when logical ancestors move.

Plain Node/Node2D/Sprite2D/Node3D children have no universal size. They stay free-positioned in their native tree, consume no Box footprint or gap, and remain visible according to Godot's normal rendering rules. Use an existing explicit EstragonNative2D/3D adapter with a supported geometry provider when the visual needs a measured slot. Borrow the authored adapter, with its visual still beneath it. There is no automatic Sprite wrapper or geometry inference.

The same rule applies to bounded 3D participants/adapters in world units. Plain-node and cross-dimensional boundaries remain unallocated. An explicit Entry remains an independent scope/position and contributes no parent footprint. Do not add an Entry to every nested Settings component; returning a VBox/HBox or another participant lets it inherit Home's Entry. No new 3D wrapping, Text/Button3D, pixel conversion or general transform policy is introduced.

Borrowing does **not** change native canvas ancestry, clipping, inherited visibility/modulation, physics, Z or draw order. Logical Box order controls sizing/translation only; Godot still chooses overlap order from actual native tree/Z. Use native Z properties deliberately where visuals overlap. Native pointer routing uses the borrowed subtree's current logical Entry and actual transformed hit regions; release/replacement reconnects or cancels that scope without extra input nodes.

## Lifetime, persistence and editing

Removing a reference, replacing a managed branch, detaching the host or disabling composition releases its logical edge; it never frees/unmounts the authored node. Participating translation restores its pre-borrow value when the node still has the same native parent. Plain nodes/independent entries keep native translation authority throughout. Native reparenting transfers eligibility to the new host and does not restore an old parent's coordinates. User edits/removal/free remain Godot-owned.

Borrowed bookkeeping is weak and external: no metadata, injected fields, helper nodes, cloned scenes or second reconciler/layout engine. Managed output remains `owner=null`. PackedScene saves the real authored hierarchy, owners and stored native properties, then remounts transient GGX once on reopen. As with other layout participants, packing a running scene records the current native translation; it does not synthesize an earlier editor-property snapshot. The editor's authored scene is separate from the running game and preserves normal Scene dock/Inspector/UndoRedo behavior.

Focused acceptance uses direct Yarn installation and isolated real editors/games on official Linux4.0.4 and pinned4.7.0. On 4.0, host `NOTIFICATION_CHILD_ORDER_CHANGED` supplies reorder invalidation when the newer child-order signal is unavailable. Existing actual-path compilation/maps/UID/rollback and Play gates remain in force. See [testing](TESTING.md), [issue #136](https://github.com/papercraftgames/Estragon/issues/136) and its sole review PR for exact evidence and limitations.
