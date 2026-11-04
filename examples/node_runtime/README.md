# C1 Node-native runtime demos

Run **`res://examples/node_runtime/TwoD.tscn`** or
**`res://examples/node_runtime/ThreeD.tscn`** with official Godot 4.0.4 or pinned
4.7.0. No build step or external tool is needed. The script uses the actual
`addons/estragon/runtime/node` API; it imports no proof fixture.

The teal/purple Polygon2D or MeshInstance3D visuals use C1's bounded native
adapters. Press Enter to grow the teal geometry; existing native Nodes move
through deferred layout rather than being replaced. Automated tests call the
same `change_geometry()` method. Resizing shows the native view/camera framing.
The orange visual is a native decoration inside a layout-only component beneath
an ordinary Node and a second explicit entry: its independent layout does not
contribute to the outer row. No C3 widget or compiler migration is implied.

Minimal authoring is ordinary GDScript or native scenes:

```gdscript
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Component = preload("res://addons/estragon/runtime/node/component_2d.gd")

func _ready() -> void:
    var entry = Entry.new()
    var participant = Component.new()
    participant.set_extent(Vector2(80, 40))
    entry.add_child(participant) # Inherited Node API returns void.
    add_child(entry)
    # Add an ordinary native visual beneath participant, or use native_2d.gd
    # around one Polygon2D for optional bounds measurement.
```

A component alone below an ordinary Node has no automatic layout scope: add an
explicit entry to re-enter. Width/height/depth use -1 for natural child/native
extent and >= 0 for fixed allocation; fixed allocation never stretches geometry.
`layout_size` and `layout_applied(size)` expose computed layout, and
`get_layout_root()` identifies participation. Native child transforms remain
Godot-owned. Call `invalidate_native()` after polygon/transform edits or mesh
replacement; native mesh change observation is opt-in.

The demo assigns `owner` separately so generated native children survive native
PackedScene/editor save/reopen. Runtime `add_child` never assigns scene owners.
See [C1 API, coordinates and lifetime](../../docs/NODE_RUNTIME.md). C2 general GGX
resolution/default compiler cutover and C3 widget parity remain separate tasks.
