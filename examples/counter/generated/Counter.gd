extends Node2D
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const HBox = preload("res://addons/estragon/runtime/node/hbox.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Text = preload("res://addons/estragon/runtime/node/text.gd")
const UiButton = preload("res://addons/estragon/runtime/node/button.gd")
signal count_changed(previous: int, value: int)
var count: int = 0:
    set(_gogo_incoming_count):
        if is_same(count, _gogo_incoming_count): return
        var _gogo_previous_count: int = count
        count = _gogo_incoming_count
        count_changed.emit(_gogo_previous_count, _gogo_incoming_count)
    get:
        preload("res://addons/estragon/runtime/composition/state.tres").observe(self, &"count_changed")
        return count

var ui: Node

func _ready() -> void:
    ui = get_node_or_null("UI")
    if ui == null:
        ui = build_view()
        add_child(ui)
        persist(ui)
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
        _gogo_read_9(),
        (26),
        (true),
        (12.0),
        (true),
        (increment),
        (true),
        _gogo_read_16(),
        (reset_count),
        (true),
        (6.0),
        (18),
        (18), self
    )

func persist(node: Node) -> void:
    node.owner = self
    for child in node.get_children(): persist(child)

func increment() -> void:
    count += 1

func reset_count() -> void:
    count = 0

func write_proof() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    var file := FileAccess.open("res://.godot/c3-play.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"count":count,"text":ui.get_node("Panel/Count").text,"native":ui.get_layout_root()==ui}))

func _gogo_read_9() -> Array:
    var _gogo_result: String = ("Count: %d" % self.count)
    return [_gogo_result]

func _gogo_read_9_sources() -> Array:
    var _gogo_sources: Array = []
    _gogo_sources.append(self.count_changed)
    return _gogo_sources

func _gogo_read_16() -> Array:
    var _gogo_result: bool = (self.count == 0)
    return [_gogo_result]

func _gogo_read_16_sources() -> Array:
    var _gogo_sources: Array = []
    _gogo_sources.append(self.count_changed)
    return _gogo_sources



class _GogoFactories_0:
    const _Element = preload("res://addons/estragon/runtime/composition/element.gd")


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
        _gogo_value_9: Array,
        _gogo_value_10: int,
        _gogo_value_11: bool,
        _gogo_value_12: float,
        _gogo_value_13: bool,
        _gogo_value_14: Callable,
        _gogo_value_15: bool,
        _gogo_value_16: Array,
        _gogo_value_17: Callable,
        _gogo_value_18: bool,
        _gogo_value_19: float,
        _gogo_value_20: int,
        _gogo_value_21: int, _gogo_host: Node
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
        if not _gogo_value_9.is_empty(): component_4.text = _gogo_value_9[0]
        var binding_5: Node = preload("res://addons/estragon/runtime/node/internal/property_binding.gd").attach(component_4, _gogo_host, &"_gogo_read_9", &"_gogo_read_9_sources", &"text", _gogo_value_9)
        component_4.font_size = _gogo_value_10
        component_1.add_child(component_4)
        var component_6: HBox = HBox.new()
        component_6.name = "Actions"
        component_6.fill_width = _gogo_value_11
        component_6.gap = _gogo_value_12
        var component_7: UiButton = UiButton.new()
        component_7.name = "Increment"
        component_7.text = "+"
        component_7.fill_width = _gogo_value_13
        component_6.add_child(component_7)
        var component_8: UiButton = UiButton.new()
        component_8.name = "Reset"
        component_8.text = "Reset"
        component_8.fill_width = _gogo_value_15
        if not _gogo_value_16.is_empty(): component_8.disabled = _gogo_value_16[0]
        var binding_9: Node = preload("res://addons/estragon/runtime/node/internal/property_binding.gd").attach(component_8, _gogo_host, &"_gogo_read_16", &"_gogo_read_16_sources", &"disabled", _gogo_value_16)
        component_6.add_child(component_8)
        component_1.add_child(component_6)
        var component_10: VBox = VBox.new()
        component_10.name = "Details"
        component_10.fill_width = _gogo_value_18
        component_10.gap = _gogo_value_19
        var component_11: Text = Text.new()
        component_11.name = "Hint"
        component_11.text = "Click + to update retained Nodes."
        component_11.font_size = _gogo_value_20
        component_10.add_child(component_11)
        var component_12: Text = Text.new()
        component_12.name = "Resize"
        component_12.text = "Resize the window: nested native stacks reflow."
        component_12.font_size = _gogo_value_21
        component_10.add_child(component_12)
        component_1.add_child(component_10)
        component_0.add_child(component_1)
        component_2.owner = component_0
        component_3.owner = component_0
        binding_5.owner = component_0
        component_4.owner = component_0
        component_7.owner = component_0
        binding_9.owner = component_0
        component_8.owner = component_0
        component_6.owner = component_0
        component_11.owner = component_0
        component_12.owner = component_0
        component_10.owner = component_0
        component_1.owner = component_0
        if not _gogo_value_14.is_valid() or component_7.pressed.connect(_gogo_value_14, Object.CONNECT_PERSIST) != OK:
            push_error("examples/counter/Counter.gogo:26:79: Node GGX signal pressed requires a valid Callable/connection")
            component_0.free()
            return null
        if not _gogo_value_17.is_valid() or component_8.pressed.connect(_gogo_value_17, Object.CONNECT_PERSIST) != OK:
            push_error("examples/counter/Counter.gogo:27:106: Node GGX signal pressed requires a valid Callable/connection")
            component_0.free()
            return null
        return component_0
