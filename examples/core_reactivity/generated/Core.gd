extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("../../../addons/estragon/runtime/node/box.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
const Leaf = preload("Leaf.gd")
const Model = preload("Model.gd")
const Ordinary = preload("../../core_reactivity/ordinary.gd")
const CollectionProbe = preload("../../core_reactivity/CollectionProbe.gd")
signal model_changed(previous: Model, value: Model)
var model: Model = Model.new():
    set(_gogo_incoming_model):
        if is_same(model, _gogo_incoming_model): return
        var _gogo_previous_model: Model = model
        model = _gogo_incoming_model
        model_changed.emit(_gogo_previous_model, _gogo_incoming_model)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"model_changed")
        return model

signal replacement_changed(previous: Model, value: Model)
var replacement: Model = Model.new():
    set(_gogo_incoming_replacement):
        if is_same(replacement, _gogo_incoming_replacement): return
        var _gogo_previous_replacement: Model = replacement
        replacement = _gogo_incoming_replacement
        replacement_changed.emit(_gogo_previous_replacement, _gogo_incoming_replacement)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"replacement_changed")
        return replacement

signal items_changed(previous: Array, value: Array)
var items: Array = []:
    set(_gogo_incoming_items):
        if is_same(items, _gogo_incoming_items): return
        var _gogo_previous_items: Array = items
        items = _gogo_incoming_items
        items_changed.emit(_gogo_previous_items, _gogo_incoming_items)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"items_changed")
        return items

signal disposable_changed(previous: Node, value: Node)
var disposable: Node = null:
    set(_gogo_incoming_disposable):
        if is_same(disposable, _gogo_incoming_disposable): return
        var _gogo_previous_disposable: Node = disposable
        disposable = _gogo_incoming_disposable
        disposable_changed.emit(_gogo_previous_disposable, _gogo_incoming_disposable)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"disposable_changed")
        return disposable

signal plain_values_changed(previous: Array, value: Array)
var plain_values: Array = [1]:
    set(_gogo_incoming_plain_values):
        if is_same(plain_values, _gogo_incoming_plain_values): return
        var _gogo_previous_plain_values: Array = plain_values
        plain_values = _gogo_incoming_plain_values
        plain_values_changed.emit(_gogo_previous_plain_values, _gogo_incoming_plain_values)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"plain_values_changed")
        return plain_values

signal tick_changed(previous: int, value: int)
var tick: int = 0:
    set(_gogo_incoming_tick):
        if is_same(tick, _gogo_incoming_tick): return
        var _gogo_previous_tick: int = tick
        tick = _gogo_incoming_tick
        tick_changed.emit(_gogo_previous_tick, _gogo_incoming_tick)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"tick_changed")
        return tick

signal show_changed(previous: bool, value: bool)
var show: bool = true:
    set(_gogo_incoming_show):
        if is_same(show, _gogo_incoming_show): return
        var _gogo_previous_show: bool = show
        show = _gogo_incoming_show
        show_changed.emit(_gogo_previous_show, _gogo_incoming_show)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"show_changed")
        return show

signal invalid_changed(previous: bool, value: bool)
var invalid: bool = false:
    set(_gogo_incoming_invalid):
        if is_same(invalid, _gogo_incoming_invalid): return
        var _gogo_previous_invalid: bool = invalid
        invalid = _gogo_incoming_invalid
        invalid_changed.emit(_gogo_previous_invalid, _gogo_incoming_invalid)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"invalid_changed")
        return invalid

signal choose_changed(previous: bool, value: bool)
var choose: bool = false:
    set(_gogo_incoming_choose):
        if is_same(choose, _gogo_incoming_choose): return
        var _gogo_previous_choose: bool = choose
        choose = _gogo_incoming_choose
        choose_changed.emit(_gogo_previous_choose, _gogo_incoming_choose)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"choose_changed")
        return choose

var ordinary = Ordinary.new()
var collection = CollectionProbe.new()
var counts: Dictionary = {"root":0,"badge":0,"zero":0,"wrapper":0,"manual":0,"collection":0,"branch":0,"nested":0,"row":0,"mutate":0,"group":0,"lambda":0,"lambda_body":0,"array":0,"callable":0}
var row_counts: Dictionary = {}
var callable_label: Callable = func(value: String) -> String:
    counts.callable += 1
    return value.to_upper()
var edits: int = 0
var mutate_once: bool = false
func pressed() -> void:
    edits += 1
    if self.model != null: self.model.value += 1
func zero() -> String:
    counts.zero += 1
    return "null" if self.model == null else self.model.label
func manual() -> Element:
    counts.manual += 1
    return Element.new(Text, {"text":zero()}, {}, [], "manual")
func wrapper() -> Element:
    counts.wrapper += 1
    return badge()
func observed_argument(source) -> String:
    counts.collection += 1
    return str(source.value)
func array_label(values: Array) -> String:
    counts.array += 1
    return str(values[0])
func badge() -> Element:
    counts.badge += 1
    var current: String = "null" if self.model == null else self.model.label
    return _GogoFactories_0._gogo_build_0((_GogoFactories_0._gogo_build_1((self.pressed)) if current=="other" else _GogoFactories_0._gogo_build_2(((preload("../../../addons/estragon/runtime/composition/state.tres").method_at("examples/core_reactivity/Core.gogo:2257", ordinary, "label", [current], func(_gogo_receiver, _gogo_arguments): return _gogo_receiver.label(_gogo_arguments[0]), func(): ordinary.label(current)) as String)))))
func nested() -> Element:
    counts.nested += 1
    return _GogoFactories_0._gogo_build_3(((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:2363", badge, [], func(): badge()) as Element)))
func branch() -> Element:
    counts.branch += 1
    var current: Model = self.replacement if self.choose else self.model
    var label: String = "null" if current==null else current.label
    return _GogoFactories_0._gogo_build_4((label), ("bad-length" if self.invalid and label!="Repair source" else "180px"))
func row(item: Model) -> Element:
    counts.row += 1
    if item.id not in row_counts: row_counts[item.id] = 0
    row_counts[item.id] += 1
    var label: String = item.label+":"+str(item.value)
    return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/core_reactivity/Core.gogo:2898", item.id, func(_gogo_mount_key): return _GogoFactories_0._gogo_build_5((_gogo_mount_key), ("Row"+str(item.id)), (label)))
func mutating() -> Element:
    counts.mutate += 1
    var current: int = self.model.value if self.model!=null else -1
    if mutate_once and self.model!=null:
        mutate_once = false
        self.model.value = current+1
    return _GogoFactories_0._gogo_build_6((str(current)))
func disposable_view(source) -> Element:
    var label: String = "gone" if not is_instance_valid(source) else source.name
    return _GogoFactories_0._gogo_build_7((label))
func lambda_container() -> Element:
    counts.lambda += 1
    var part = func():
        counts.lambda_body += 1
        var label: String = "null" if self.model==null else self.model.label
        return _GogoFactories_0._gogo_build_8((label))
    return _GogoFactories_0._gogo_build_9((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:3712", part, [], func(): part.call(), true)), (preload("../../../addons/estragon/runtime/composition/state.tres").method_at("examples/core_reactivity/Core.gogo:3720", part, "call", [], func(_gogo_receiver, _gogo_arguments): return _gogo_receiver.call(), func(): part.call(), true)))
func keyed_group() -> Element:
    counts.group += 1
    return _GogoFactories_0._gogo_build_10((self.items.map(func(item): return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/core_reactivity/Core.gogo:3879", item.id, func(_gogo_mount_key): return _GogoFactories_0._gogo_build_11((_gogo_mount_key), ("Key"+str(item.id)), ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:3925", badge, [], func(): badge()) as Element)))))))
func build_view() -> Element:
    counts.root += 1
    var shared: Element = (preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:4025", manual, [], func(): manual()) as Element)
    return _GogoFactories_0._gogo_build_12(
        ("Core reactive calls "+str(self.tick)),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:4298", badge, [], func(): badge()) as Element)),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:4307", badge, [], func(): badge()) as Element)),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:4316", nested, [], func(): nested()) as Element)),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:4401", zero, [], func(): zero()) as String)),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:4412", wrapper, [], func(): wrapper()) as Element)),
        (shared),
        (shared),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:4468", observed_argument, [collection], func(): observed_argument(collection)) as String)),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:4521", branch, [], func(): branch()) as Element)),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:4544", mutating, [], func(): mutating()) as Element)),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:4569", disposable_view, [self.disposable], func(): disposable_view(self.disposable)) as Element)),
        (preload("../../../addons/estragon/runtime/composition/state.tres").method_at("examples/core_reactivity/Core.gogo:4643", callable_label, "call", ["fixed"], func(_gogo_receiver, _gogo_arguments): return _gogo_receiver.call(_gogo_arguments[0]), func(): callable_label.call("fixed"))),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").method_at("examples/core_reactivity/Core.gogo:4720", Ordinary, "static_label", ["static import"], func(_gogo_receiver, _gogo_arguments): return _gogo_receiver.static_label(_gogo_arguments[0]), func(): Ordinary.static_label("static import")) as String)),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:4800", array_label, [self.plain_values], func(): array_label(self.plain_values)) as String)),
        (self.pressed),
        (self.model),
        (_GogoFactories_0._gogo_build_13((self.model)) if self.show else null),
        (self.items.map(func(item): return (preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:5144", row, [item], func(): row(item)) as Element))),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:5175", keyed_group, [], func(): keyed_group()) as Element)),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Core.gogo:5203", lambda_container, [], func(): lambda_container()) as Element))
    )

const _GOGO_RENDER_FUNCTIONS_b94a7b53a36fbd28 = {
"ordinary": ["pressed", "zero", "manual", "wrapper", "observed_argument", "array_label"],
"reactive": ["badge", "nested", "branch", "row", "mutating", "disposable_view", "lambda_container", "keyed_group", "build_view"]
}

const _GogoProject_0 = preload("Leaf.gd")

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Box, {"direction": "column", "width": "180px", "height": "32px"}, {}, [_gogo_value_0], "examples/core_reactivity/Core.gogo:50:12", null, false)
        return _gogo_element_0


    static func _gogo_build_1(_gogo_value_0: Callable) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoImport_0, {"name": "Alternate", "text": "Other"}, {"pressed": _gogo_value_0}, [], "examples/core_reactivity/Core.gogo:51:10", null, false)
        return _gogo_element_0


    static func _gogo_build_2(_gogo_value_0: String) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Label", "text": _gogo_value_0}, {}, [], "examples/core_reactivity/Core.gogo:51:99", null, false)
        return _gogo_element_0


    static func _gogo_build_3(_gogo_value_0: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Box, {}, {}, [_gogo_value_0], "examples/core_reactivity/Core.gogo:55:12", null, false)
        return _gogo_element_0


    static func _gogo_build_4(_gogo_value_0: String, _gogo_value_1: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Branch", "text": _gogo_value_0, "width": _gogo_value_1}, {}, [], "examples/core_reactivity/Core.gogo:60:12", null, false)
        return _gogo_element_0


    static func _gogo_build_5(_gogo_value_0: Variant, _gogo_value_1: StringName, _gogo_value_2: String) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": _gogo_value_2}, {}, [], "examples/core_reactivity/Core.gogo:66:85", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Box, {"name": _gogo_value_1, "width": "180px", "height": "20px"}, {}, [_gogo_element_1], "examples/core_reactivity/Core.gogo:66:12", _gogo_value_0, true)
        return _gogo_element_0


    static func _gogo_build_6(_gogo_value_0: String) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Mutation", "text": _gogo_value_0}, {}, [], "examples/core_reactivity/Core.gogo:73:12", null, false)
        return _gogo_element_0


    static func _gogo_build_7(_gogo_value_0: String) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Disposable", "text": _gogo_value_0}, {}, [], "examples/core_reactivity/Core.gogo:76:12", null, false)
        return _gogo_element_0


    static func _gogo_build_8(_gogo_value_0: String) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"text": _gogo_value_0}, {}, [], "examples/core_reactivity/Core.gogo:82:16", null, false)
        return _gogo_element_0


    static func _gogo_build_9(_gogo_value_0: Variant, _gogo_value_1: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Box, {"name": "Lambda"}, {}, [_gogo_value_0, _gogo_value_1], "examples/core_reactivity/Core.gogo:83:12", null, false)
        return _gogo_element_0


    static func _gogo_build_10(_gogo_value_0: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Box, {"name": "KeyedZero", "direction": "column"}, {}, [_gogo_value_0], "examples/core_reactivity/Core.gogo:86:12", null, false)
        return _gogo_element_0


    static func _gogo_build_11(_gogo_value_0: Variant, _gogo_value_1: StringName, _gogo_value_2: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Box, {"name": _gogo_value_1}, {}, [_gogo_value_2], "examples/core_reactivity/Core.gogo:86:88", _gogo_value_0, true)
        return _gogo_element_0


    static func _gogo_build_12(
        _gogo_value_0: String,
        _gogo_value_1: Variant,
        _gogo_value_2: Variant,
        _gogo_value_3: Variant,
        _gogo_value_4: String,
        _gogo_value_5: Variant,
        _gogo_value_6: Variant,
        _gogo_value_7: Variant,
        _gogo_value_8: String,
        _gogo_value_9: Variant,
        _gogo_value_10: Variant,
        _gogo_value_11: Variant,
        _gogo_value_12: String,
        _gogo_value_13: String,
        _gogo_value_14: String,
        _gogo_value_15: Callable,
        _gogo_value_16: _GogoProject_0.Model,
        _gogo_value_17: Variant,
        _gogo_value_18: Variant,
        _gogo_value_19: Variant,
        _gogo_value_20: Variant
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(Text, {"text": _gogo_value_0}, {}, [], "examples/core_reactivity/Core.gogo:92:13", null, false)
        var _gogo_element_3 := _GogoElement_0.new(Box, {"name": "Badges", "gap": "4px"}, {}, [_gogo_value_1, _gogo_value_2, _gogo_value_3], "examples/core_reactivity/Core.gogo:93:13", null, false)
        var _gogo_element_5 := _GogoElement_0.new(Text, {"name": "Static", "text": _gogo_value_4}, {}, [], "examples/core_reactivity/Core.gogo:94:44", null, false)
        var _gogo_element_6 := _GogoElement_0.new(Text, {"name": "Collection", "text": _gogo_value_8}, {}, [], "examples/core_reactivity/Core.gogo:94:107", null, false)
        var _gogo_element_4 := _GogoElement_0.new(Box, {"name": "Ordinary", "gap": "4px"}, {}, [_gogo_element_5, _gogo_value_5, _gogo_value_6, _gogo_value_7, _gogo_element_6], "examples/core_reactivity/Core.gogo:94:13", null, false)
        var _gogo_element_7 := _GogoElement_0.new(Text, {"name": "Callable", "text": _gogo_value_12}, {}, [], "examples/core_reactivity/Core.gogo:98:13", null, false)
        var _gogo_element_8 := _GogoElement_0.new(Text, {"name": "StaticImport", "text": _gogo_value_13}, {}, [], "examples/core_reactivity/Core.gogo:99:13", null, false)
        var _gogo_element_9 := _GogoElement_0.new(Text, {"name": "Plain", "text": _gogo_value_14}, {}, [], "examples/core_reactivity/Core.gogo:100:13", null, false)
        var _gogo_element_10 := _GogoElement_0.new(_GogoImport_0, {"name": "Action", "text": "Native event", "width": "180px"}, {"pressed": _gogo_value_15}, [], "examples/core_reactivity/Core.gogo:101:13", null, false)
        var _gogo_element_11 := _GogoElement_0.new(_GogoProject_0, {"name": "First", "model": _gogo_value_16}, {}, [], "examples/core_reactivity/Core.gogo:102:13", null, false)
        var _gogo_element_12 := _GogoElement_0.new(Box, {"name": "Rows", "direction": "column"}, {}, [_gogo_value_18], "examples/core_reactivity/Core.gogo:104:13", null, false)
        var _gogo_element_1 := _GogoElement_0.new(Box, {"name": "Column", "direction": "column", "gap": "2px"}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_value_9, _gogo_value_10, _gogo_value_11, _gogo_element_7, _gogo_element_8, _gogo_element_9, _gogo_element_10, _gogo_element_11, _gogo_value_17, _gogo_element_12, _gogo_value_19, _gogo_value_20], "examples/core_reactivity/Core.gogo:91:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "width": "640px", "height": "480px", "padding": "8px", "background_color": "#172332"}, {}, [_gogo_element_1], "examples/core_reactivity/Core.gogo:90:12", null, false)
        return _gogo_element_0


    static func _gogo_build_13(_gogo_value_0: _GogoProject_0.Model) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoProject_0, {"name": "Second", "model": _gogo_value_0}, {}, [], "examples/core_reactivity/Core.gogo:103:14", null, false)
        return _gogo_element_0
