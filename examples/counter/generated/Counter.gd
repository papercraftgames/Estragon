extends Node2D
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const HBox = preload("res://addons/estragon/runtime/node/hbox.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Text = preload("res://addons/estragon/runtime/node/text.gd")
const UiButton = preload("res://addons/estragon/runtime/node/button.gd")
var count: int = 0
var ui: Node

func _ready() -> void:
    ui = get_node_or_null("UI")
    if ui == null:
        ui = build_view()
        add_child(ui)
        persist(ui)
    refresh()
    if OS.get_environment("ESTRAGON_C3_PROOF") == "1": write_proof.call_deferred()

func build_view() -> Node:
    return _GogoFactories_0._gogo_build_0(
        (Vector2(24,24)),
        (0.9),
        (true),
        (16.0),
        (8.0),
        (true),
        (Color(0.2,0.8,0.6)),
        (28),
        (Color(0.74,0.64,0.94)),
        (26),
        (true),
        (12.0),
        (true),
        (increment),
        (true),
        (true),
        (reset_count),
        (true),
        (6.0),
        (18),
        (18)
    )

func persist(node: Node) -> void:
    node.owner = self
    for child in node.get_children(): persist(child)

func increment() -> void:
    count += 1
    refresh()

func reset_count() -> void:
    count = 0
    refresh()

func refresh() -> void:
    ui.get_node("Panel/Count").text = "Count: %d" % count
    ui.get_node("Panel/Actions/Reset").disabled = count == 0

func write_proof() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    var file := FileAccess.open("res://.godot/c3-play.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"count":count,"text":ui.get_node("Panel/Count").text,"native":ui.get_layout_root()==ui}))



class _GogoFactories_0:

    static func _gogo_build_0(
        _gogo_value_0: Vector2,
        _gogo_value_1: float,
        _gogo_value_2: bool,
        _gogo_value_3: float,
        _gogo_value_4: float,
        _gogo_value_5: bool,
        _gogo_value_6: Color,
        _gogo_value_7: int,
        _gogo_value_8: Color,
        _gogo_value_9: int,
        _gogo_value_10: bool,
        _gogo_value_11: float,
        _gogo_value_12: bool,
        _gogo_value_13: Callable,
        _gogo_value_14: bool,
        _gogo_value_15: bool,
        _gogo_value_16: Callable,
        _gogo_value_17: bool,
        _gogo_value_18: float,
        _gogo_value_19: int,
        _gogo_value_20: int
    ) -> Entry:
        var component_0: Entry = Entry.new()
        component_0.name = "UI"
        component_0.position = _gogo_value_0
        component_0.viewport_width_scale = _gogo_value_1
        var component_1: VBox = VBox.new()
        component_1.name = "Panel"
        component_1.fill_width = _gogo_value_2
        component_1.gap = _gogo_value_3
        var component_2: Rect = Rect.new()
        component_2.name = "Accent"
        component_2.height = _gogo_value_4
        component_2.fill_width = _gogo_value_5
        component_2.fill = _gogo_value_6
        component_1.add_child(component_2)
        var component_3: Text = Text.new()
        component_3.name = "Title"
        component_3.text = "Estragon native Gogo Counter"
        component_3.font_size = _gogo_value_7
        component_3.color = _gogo_value_8
        component_1.add_child(component_3)
        var component_4: Text = Text.new()
        component_4.name = "Count"
        component_4.text = "Count: 0"
        component_4.font_size = _gogo_value_9
        component_1.add_child(component_4)
        var component_5: HBox = HBox.new()
        component_5.name = "Actions"
        component_5.fill_width = _gogo_value_10
        component_5.gap = _gogo_value_11
        var component_6: UiButton = UiButton.new()
        component_6.name = "Increment"
        component_6.text = "+"
        component_6.fill_width = _gogo_value_12
        component_5.add_child(component_6)
        var component_7: UiButton = UiButton.new()
        component_7.name = "Reset"
        component_7.text = "Reset"
        component_7.fill_width = _gogo_value_14
        component_7.disabled = _gogo_value_15
        component_5.add_child(component_7)
        component_1.add_child(component_5)
        var component_8: VBox = VBox.new()
        component_8.name = "Details"
        component_8.fill_width = _gogo_value_17
        component_8.gap = _gogo_value_18
        var component_9: Text = Text.new()
        component_9.name = "Hint"
        component_9.text = "Click + to update retained Nodes."
        component_9.font_size = _gogo_value_19
        component_8.add_child(component_9)
        var component_10: Text = Text.new()
        component_10.name = "Resize"
        component_10.text = "Resize the window: nested native stacks reflow."
        component_10.font_size = _gogo_value_20
        component_8.add_child(component_10)
        component_1.add_child(component_8)
        component_0.add_child(component_1)
        component_2.owner = component_0
        component_3.owner = component_0
        component_4.owner = component_0
        component_6.owner = component_0
        component_7.owner = component_0
        component_5.owner = component_0
        component_9.owner = component_0
        component_10.owner = component_0
        component_8.owner = component_0
        component_1.owner = component_0
        if not _gogo_value_13.is_valid() or component_6.pressed.connect(_gogo_value_13, Object.CONNECT_PERSIST) != OK:
            push_error("examples/native_counter/Counter.gogo:27:79: Node GGX signal pressed requires a valid Callable/connection")
            component_0.free()
            return null
        if not _gogo_value_16.is_valid() or component_7.pressed.connect(_gogo_value_16, Object.CONNECT_PERSIST) != OK:
            push_error("examples/native_counter/Counter.gogo:28:95: Node GGX signal pressed requires a valid Callable/connection")
            component_0.free()
            return null
        return component_0
