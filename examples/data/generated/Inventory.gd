
extends RefCounted
const Item = preload("Item.gd")
signal title_changed(previous: String, value: String)
var title: String = "Inventory":
	set(_gogo_incoming_title):
		if is_same(title, _gogo_incoming_title): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_title): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_title: String = title
		title = _gogo_incoming_title
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			title_changed.emit(_gogo_previous_title, _gogo_incoming_title)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"title_changed")
		return title

signal items_changed(previous: _GogoArrayCollection, value: _GogoArrayCollection)
var items: _GogoArrayCollection = preload("../../../addons/estragon/runtime/data/state.tres").value([], [Item], null, "examples/data/Inventory.gogo:5:5"):
	set(_gogo_incoming_items):
		if is_same(items, _gogo_incoming_items): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_items): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_items: _GogoArrayCollection = items
		items = _gogo_incoming_items
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			items_changed.emit(_gogo_previous_items, _gogo_incoming_items)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"items_changed")
		return items

signal selected_changed(previous: Item, value: Item)
var selected: Item:
	set(_gogo_incoming_selected):
		if is_same(selected, _gogo_incoming_selected): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_selected): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_selected: Item = selected
		selected = _gogo_incoming_selected
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			selected_changed.emit(_gogo_previous_selected, _gogo_incoming_selected)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"selected_changed")
		return selected

const _GogoArrayCollection = preload("../../../addons/estragon/runtime/data/array_collection.gd")
signal _gogo_data_changed

const _GOGO_DATA_SHAPE_ca4e55a4ac7cf9c0 = true

func to_data():
	return preload("../../../addons/estragon/runtime/data/state.tres").to_data(self)

const _GOGO_DATA_TYPES_ca4e55a4ac7cf9c0 = {"title": TYPE_STRING,"items": [Item],"selected": Item,}

const _GOGO_RENDER_FUNCTIONS_ca4e55a4ac7cf9c0 = {
"ordinary": [],
"reactive": []
}
const _GOGO_BINDABLE_PROPERTIES_ca4e55a4ac7cf9c0 = {
"items": "ArrayCollection[Item]",
"selected": "Item",
"title": "String"
}

func _notification(_gogo_what: int) -> void:
	if _gogo_what==NOTIFICATION_PREDELETE: preload("../../../addons/estragon/runtime/data/state.tres").prune()
