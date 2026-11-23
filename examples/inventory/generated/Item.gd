
extends RefCounted
signal id_changed(previous: int, value: int)
var id: int = 0:
    set(_gogo_incoming_id):
        if is_same(id, _gogo_incoming_id): return
        var _gogo_previous_id: int = id
        id = _gogo_incoming_id
        id_changed.emit(_gogo_previous_id, _gogo_incoming_id)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"id_changed")
        return id

signal title_changed(previous: String, value: String)
var title: String = "Item":
    set(_gogo_incoming_title):
        if is_same(title, _gogo_incoming_title): return
        var _gogo_previous_title: String = title
        title = _gogo_incoming_title
        title_changed.emit(_gogo_previous_title, _gogo_incoming_title)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"title_changed")
        return title

func _init(identity: int = 0, caption: String = "Item") -> void:
    id = identity
    title = caption

const _GOGO_RENDER_FUNCTIONS_2c9b42ea687a5496 = {
"ordinary": ["_init"],
"reactive": []
}
const _GOGO_BINDABLE_PROPERTIES_2c9b42ea687a5496 = {
"id": "int",
"title": "String"
}
