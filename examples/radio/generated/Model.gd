
extends RefCounted
signal choice_changed(previous: String, value: String)
var choice: String = "b":
	set(_gogo_incoming_choice):
		if is_same(choice, _gogo_incoming_choice): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_choice): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_choice: String = choice
		choice = _gogo_incoming_choice
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			choice_changed.emit(_gogo_previous_choice, _gogo_incoming_choice)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"choice_changed")
		return choice

signal _gogo_data_changed

const _GOGO_DATA_SHAPE_e6ca14c602960914 = true

func to_data():
	return preload("../../../addons/estragon/runtime/data/state.tres").to_data(self)

const _GOGO_DATA_TYPES_e6ca14c602960914 = {"choice": TYPE_STRING,}

const _GOGO_RENDER_FUNCTIONS_e6ca14c602960914 = {
"ordinary": [],
"reactive": []
}
const _GOGO_BINDABLE_PROPERTIES_e6ca14c602960914 = {
"choice": "String"
}

func _notification(_gogo_what: int) -> void:
	if _gogo_what==NOTIFICATION_PREDELETE: preload("../../../addons/estragon/runtime/data/state.tres").prune()
