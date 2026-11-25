
extends RefCounted
signal id_changed(previous: String, value: String)
var id: String = "":
	set(_gogo_incoming_id):
		if is_same(id, _gogo_incoming_id): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_id): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_id: String = id
		id = _gogo_incoming_id
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			id_changed.emit(_gogo_previous_id, _gogo_incoming_id)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"id_changed")
		return id

signal label_changed(previous: String, value: String)
var label: String = "":
	set(_gogo_incoming_label):
		if is_same(label, _gogo_incoming_label): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_label): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_label: String = label
		label = _gogo_incoming_label
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			label_changed.emit(_gogo_previous_label, _gogo_incoming_label)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"label_changed")
		return label

signal disabled_changed(previous: bool, value: bool)
var disabled: bool = false:
	set(_gogo_incoming_disabled):
		if is_same(disabled, _gogo_incoming_disabled): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_disabled): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_disabled: bool = disabled
		disabled = _gogo_incoming_disabled
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			disabled_changed.emit(_gogo_previous_disabled, _gogo_incoming_disabled)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"disabled_changed")
		return disabled

signal _gogo_data_changed

const _GOGO_DATA_SHAPE_471114c7d5c9a7c1 = true

func to_data():
	return preload("../../../addons/estragon/runtime/data/state.tres").to_data(self)

const _GOGO_DATA_TYPES_471114c7d5c9a7c1 = {"id": TYPE_STRING,"label": TYPE_STRING,"disabled": TYPE_BOOL,}

const _GOGO_RENDER_FUNCTIONS_471114c7d5c9a7c1 = {
"ordinary": [],
"reactive": []
}
const _GOGO_BINDABLE_PROPERTIES_471114c7d5c9a7c1 = {
"disabled": "bool",
"id": "String",
"label": "String"
}

func _notification(_gogo_what: int) -> void:
	if _gogo_what==NOTIFICATION_PREDELETE: preload("../../../addons/estragon/runtime/data/state.tres").prune()
