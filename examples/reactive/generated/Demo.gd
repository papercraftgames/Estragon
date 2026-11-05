extends Node2D
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const HBox = preload("res://addons/estragon/runtime/node/hbox.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Text = preload("res://addons/estragon/runtime/node/text.gd")
const UiButton = preload("res://addons/estragon/runtime/node/button.gd")
const Model = preload("res://examples/reactive/generated/Model.gd")
signal model_changed(previous: Model, value: Model)
var model: Model = Model.new():
    set(_gogo_incoming_model):
        if is_same(model, _gogo_incoming_model): return
        var _gogo_previous_model: Model = model
        model = _gogo_incoming_model
        model_changed.emit(_gogo_previous_model, _gogo_incoming_model)
    get:
        preload("res://addons/estragon/runtime/composition/state.tres").observe(self, &"model_changed")
        return model

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
var evaluations: int = 0
func independent() -> String:
    evaluations += 1
    return "Unaffected once-only expression"
func _ready() -> void:
    ui = get_node_or_null("UI")
    if ui == null:
        ui = build_view()
        add_child(ui)
        persist(ui)
    if OS.get_environment("ESTRAGON_REACTIVE_PROOF") == "1": write_proof.call_deferred()
func build_view() -> Node:
    return _GogoFactories_0._gogo_build_0(
        (Vector2(24,24)),
        (0.9),
        (true),
        _gogo_read_3(),
        _gogo_read_4(),
        _gogo_read_5(),
        (true),
        (12.0),
        _gogo_read_8(),
        (40.0),
        _gogo_read_10(),
        (80.0),
        (40.0),
        (Color(0.55,0.32,0.9)),
        _gogo_read_14(),
        (advance),
        (independent()), self
    )
func persist(node: Node) -> void:
    node.owner = self
    for child in node.get_children(): persist(child)
func advance() -> void:
    count += 1
    model.player.width += 40.0
    model.player.tint = Color(0.9,0.35,0.2)
    model.player.title = "Changed without rebuilding"
func write_proof() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    var file := FileAccess.open("res://.godot/reactive-play.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"count":count,"text":ui.get_node("Panel/Count").text}))

func _gogo_read_3() -> Array:
    var _gogo_result: float = (12.0 + self.count)
    return [_gogo_result]

func _gogo_read_3_sources() -> Array:
    var _gogo_sources: Array = []
    _gogo_sources.append(self.count_changed)
    return _gogo_sources

func _gogo_read_4() -> Array:
    if not (self.model != null and self.model.player != null): return []
    var _gogo_result: String = (self.model.player.title)
    return [_gogo_result]

func _gogo_read_4_sources() -> Array:
    var _gogo_sources: Array = []
    _gogo_sources.append(self.model_changed)
    if self.model != null:
        _gogo_sources.append(self.model.player_changed)
        if self.model.player != null:
            _gogo_sources.append(self.model.player.title_changed)
    return _gogo_sources

func _gogo_read_5() -> Array:
    if not (self.model != null and self.model.player != null): return []
    var _gogo_result: Color = (self.model.player.tint)
    return [_gogo_result]

func _gogo_read_5_sources() -> Array:
    var _gogo_sources: Array = []
    _gogo_sources.append(self.model_changed)
    if self.model != null:
        _gogo_sources.append(self.model.player_changed)
        if self.model.player != null:
            _gogo_sources.append(self.model.player.tint_changed)
    return _gogo_sources

func _gogo_read_8() -> Array:
    if not (self.model != null and self.model.player != null): return []
    var _gogo_result: float = (self.model.player.width)
    return [_gogo_result]

func _gogo_read_8_sources() -> Array:
    var _gogo_sources: Array = []
    _gogo_sources.append(self.model_changed)
    if self.model != null:
        _gogo_sources.append(self.model.player_changed)
        if self.model.player != null:
            _gogo_sources.append(self.model.player.width_changed)
    return _gogo_sources

func _gogo_read_10() -> Array:
    if not (self.model != null and self.model.player != null): return []
    var _gogo_result: Color = (self.model.player.tint)
    return [_gogo_result]

func _gogo_read_10_sources() -> Array:
    var _gogo_sources: Array = []
    _gogo_sources.append(self.model_changed)
    if self.model != null:
        _gogo_sources.append(self.model.player_changed)
        if self.model.player != null:
            _gogo_sources.append(self.model.player.tint_changed)
    return _gogo_sources

func _gogo_read_14() -> Array:
    var _gogo_result: String = ("Value: %d" % (self.count + self.count))
    return [_gogo_result]

func _gogo_read_14_sources() -> Array:
    var _gogo_sources: Array = []
    _gogo_sources.append(self.count_changed)
    return _gogo_sources



class _GogoFactories_0:

    static func _gogo_build_0(
        _gogo_value_0: Vector2,
        _gogo_value_1: float,
        _gogo_value_2: bool,
        _gogo_value_3: Array,
        _gogo_value_4: Array,
        _gogo_value_5: Array,
        _gogo_value_6: bool,
        _gogo_value_7: float,
        _gogo_value_8: Array,
        _gogo_value_9: float,
        _gogo_value_10: Array,
        _gogo_value_11: float,
        _gogo_value_12: float,
        _gogo_value_13: Color,
        _gogo_value_14: Array,
        _gogo_value_15: Callable,
        _gogo_value_16: String, _gogo_host: Node
    ) -> Entry:
        var component_0: Entry = Entry.new()
        component_0.name = "UI"
        component_0.position = _gogo_value_0
        component_0.viewport_width_scale = _gogo_value_1
        var component_1: VBox = VBox.new()
        component_1.name = "Panel"
        component_1.fill_width = _gogo_value_2
        if not _gogo_value_3.is_empty(): component_1.gap = _gogo_value_3[0]
        var binding_2: Node = preload("res://addons/estragon/runtime/node/internal/property_binding.gd").attach(component_1, _gogo_host, &"_gogo_read_3", &"_gogo_read_3_sources", &"gap", _gogo_value_3)
        var component_3: Text = Text.new()
        component_3.name = "Title"
        if not _gogo_value_4.is_empty(): component_3.text = _gogo_value_4[0]
        var binding_4: Node = preload("res://addons/estragon/runtime/node/internal/property_binding.gd").attach(component_3, _gogo_host, &"_gogo_read_4", &"_gogo_read_4_sources", &"text", _gogo_value_4)
        if not _gogo_value_5.is_empty(): component_3.color = _gogo_value_5[0]
        var binding_5: Node = preload("res://addons/estragon/runtime/node/internal/property_binding.gd").attach(component_3, _gogo_host, &"_gogo_read_5", &"_gogo_read_5_sources", &"color", _gogo_value_5)
        component_1.add_child(component_3)
        var component_6: HBox = HBox.new()
        component_6.name = "Row"
        component_6.fill_width = _gogo_value_6
        component_6.gap = _gogo_value_7
        var component_7: Rect = Rect.new()
        component_7.name = "Bar"
        if not _gogo_value_8.is_empty(): component_7.width = _gogo_value_8[0]
        var binding_8: Node = preload("res://addons/estragon/runtime/node/internal/property_binding.gd").attach(component_7, _gogo_host, &"_gogo_read_8", &"_gogo_read_8_sources", &"width", _gogo_value_8)
        component_7.height = _gogo_value_9
        if not _gogo_value_10.is_empty(): component_7.fill = _gogo_value_10[0]
        var binding_9: Node = preload("res://addons/estragon/runtime/node/internal/property_binding.gd").attach(component_7, _gogo_host, &"_gogo_read_10", &"_gogo_read_10_sources", &"fill", _gogo_value_10)
        component_6.add_child(component_7)
        var component_10: Rect = Rect.new()
        component_10.name = "Other"
        component_10.width = _gogo_value_11
        component_10.height = _gogo_value_12
        component_10.fill = _gogo_value_13
        component_6.add_child(component_10)
        component_1.add_child(component_6)
        var component_11: Text = Text.new()
        component_11.name = "Count"
        if not _gogo_value_14.is_empty(): component_11.text = _gogo_value_14[0]
        var binding_12: Node = preload("res://addons/estragon/runtime/node/internal/property_binding.gd").attach(component_11, _gogo_host, &"_gogo_read_14", &"_gogo_read_14_sources", &"text", _gogo_value_14)
        component_1.add_child(component_11)
        var component_13: UiButton = UiButton.new()
        component_13.name = "Advance"
        component_13.text = "Change model and layout"
        component_1.add_child(component_13)
        var component_14: Text = Text.new()
        component_14.name = "Independent"
        component_14.text = _gogo_value_16
        component_1.add_child(component_14)
        component_0.add_child(component_1)
        binding_2.owner = component_0
        binding_4.owner = component_0
        binding_5.owner = component_0
        component_3.owner = component_0
        binding_8.owner = component_0
        binding_9.owner = component_0
        component_7.owner = component_0
        component_10.owner = component_0
        component_6.owner = component_0
        binding_12.owner = component_0
        component_11.owner = component_0
        component_13.owner = component_0
        component_14.owner = component_0
        component_1.owner = component_0
        if not _gogo_value_15.is_valid() or component_13.pressed.connect(_gogo_value_15, Object.CONNECT_PERSIST) != OK:
            push_error("examples/reactive/Demo.gogo:32:77: Node GGX signal pressed requires a valid Callable/connection")
            component_0.free()
            return null
        return component_0
