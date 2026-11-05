extends RefCounted
var id: int = 0
signal title_changed(previous: String, value: String)
var title: String = "Item":
    set(_gogo_incoming_title):
        if is_same(title, _gogo_incoming_title): return
        var _gogo_previous_title: String = title
        title = _gogo_incoming_title
        title_changed.emit(_gogo_previous_title, _gogo_incoming_title)
    get:
        preload("res://addons/estragon/runtime/composition/state.tres").observe(self, &"title_changed")
        return title

func _init(identity: int = 0, caption: String = "Item") -> void:
    id = identity
    title = caption

