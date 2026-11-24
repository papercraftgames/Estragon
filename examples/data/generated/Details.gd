
extends RefCounted
signal note_changed(previous: String, value: String)
var note: String = "Ready":
	set(_gogo_incoming_note):
		if is_same(note, _gogo_incoming_note): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_note): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_note: String = note
		note = _gogo_incoming_note
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			note_changed.emit(_gogo_previous_note, _gogo_incoming_note)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"note_changed")
		return note

signal tags_changed(previous: _GogoArrayCollection, value: _GogoArrayCollection)
var tags: _GogoArrayCollection = preload("../../../addons/estragon/runtime/data/state.tres").value([], [TYPE_STRING], null, "examples/data/Details.gogo:4:5"):
	set(_gogo_incoming_tags):
		if is_same(tags, _gogo_incoming_tags): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_tags): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_tags: _GogoArrayCollection = tags
		tags = _gogo_incoming_tags
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			tags_changed.emit(_gogo_previous_tags, _gogo_incoming_tags)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"tags_changed")
		return tags

const _GogoArrayCollection = preload("../../../addons/estragon/runtime/data/array_collection.gd")
signal _gogo_data_changed

const _GOGO_DATA_SHAPE_441c3ab3f91b8689 = true

func to_data():
	return preload("../../../addons/estragon/runtime/data/state.tres").to_data(self)

const _GOGO_DATA_TYPES_441c3ab3f91b8689 = {"note": TYPE_STRING,"tags": [TYPE_STRING],}

const _GOGO_RENDER_FUNCTIONS_441c3ab3f91b8689 = {
"ordinary": [],
"reactive": []
}
const _GOGO_BINDABLE_PROPERTIES_441c3ab3f91b8689 = {
"note": "String",
"tags": "ArrayCollection[String]"
}

func _notification(_gogo_what: int) -> void:
	if _gogo_what==NOTIFICATION_PREDELETE: preload("../../../addons/estragon/runtime/data/state.tres").prune()
