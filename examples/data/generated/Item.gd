
extends RefCounted
const Details = preload("Details.gd")
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

signal name_changed(previous: String, value: String)
var name: String = "Unnamed":
	set(_gogo_incoming_name):
		if is_same(name, _gogo_incoming_name): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_name): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_name: String = name
		name = _gogo_incoming_name
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			name_changed.emit(_gogo_previous_name, _gogo_incoming_name)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"name_changed")
		return name

signal quantity_changed(previous: int, value: int)
var quantity: int = 1:
	set(_gogo_incoming_quantity):
		if is_same(quantity, _gogo_incoming_quantity): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_quantity): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_quantity: int = quantity
		quantity = _gogo_incoming_quantity
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			quantity_changed.emit(_gogo_previous_quantity, _gogo_incoming_quantity)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"quantity_changed")
		return quantity

signal details_changed(previous: Details, value: Details)
var details: Details = preload("../../../addons/estragon/runtime/data/state.tres").value({}, Details, null, "examples/data/Item.gogo:7:5"):
	set(_gogo_incoming_details):
		if is_same(details, _gogo_incoming_details): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_details): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_details: Details = details
		details = _gogo_incoming_details
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			details_changed.emit(_gogo_previous_details, _gogo_incoming_details)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"details_changed")
		return details

signal _gogo_data_changed

const _GOGO_DATA_SHAPE_63d0856de0232c53 = true

func to_data():
	return preload("../../../addons/estragon/runtime/data/state.tres").to_data(self)

const _GOGO_DATA_TYPES_63d0856de0232c53 = {"id": TYPE_INT,"name": TYPE_STRING,"quantity": TYPE_INT,"details": Details,}

const _GOGO_RENDER_FUNCTIONS_63d0856de0232c53 = {
"ordinary": [],
"reactive": []
}
const _GOGO_BINDABLE_PROPERTIES_63d0856de0232c53 = {
"details": "Details",
"id": "int",
"name": "String",
"quantity": "int"
}

func _notification(_gogo_what: int) -> void:
	if _gogo_what==NOTIFICATION_PREDELETE: preload("../../../addons/estragon/runtime/data/state.tres").prune()
