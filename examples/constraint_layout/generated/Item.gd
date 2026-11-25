
extends RefCounted
signal id_changed(previous: int, value: int)
var id: int:
	set(_gogo_incoming_id):
		if is_same(id, _gogo_incoming_id): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_id): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_id: int = id
		id = _gogo_incoming_id
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			id_changed.emit(_gogo_previous_id, _gogo_incoming_id)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"id_changed")
		return id

signal label_changed(previous: String, value: String)
var label: String = "Item":
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

signal _gogo_data_changed

const _GOGO_DATA_SHAPE_2d73bf10243b9257 = true

func to_data():
	return preload("../../../addons/estragon/runtime/data/state.tres").to_data(self)

const _GOGO_DATA_TYPES_2d73bf10243b9257 = {"id": TYPE_INT,"label": TYPE_STRING,}

const _GOGO_RENDER_FUNCTIONS_2d73bf10243b9257 = {
"ordinary": [],
"reactive": []
}
const _GOGO_BINDABLE_PROPERTIES_2d73bf10243b9257 = {
"id": "int",
"label": "String"
}

func _notification(_gogo_what: int) -> void:
	if _gogo_what==NOTIFICATION_PREDELETE: preload("../../../addons/estragon/runtime/data/state.tres").prune()
