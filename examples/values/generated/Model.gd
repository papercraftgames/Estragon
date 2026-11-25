
extends RefCounted
signal mode_changed(previous: String, value: String)
var mode: String = "explore":
	set(_gogo_incoming_mode):
		if is_same(mode, _gogo_incoming_mode): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_mode): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_mode: String = mode
		mode = _gogo_incoming_mode
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			mode_changed.emit(_gogo_previous_mode, _gogo_incoming_mode)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"mode_changed")
		return mode

signal volume_changed(previous: float, value: float)
var volume: float = 0.5:
	set(_gogo_incoming_volume):
		if is_same(volume, _gogo_incoming_volume): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_volume): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_volume: float = volume
		volume = _gogo_incoming_volume
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			volume_changed.emit(_gogo_previous_volume, _gogo_incoming_volume)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"volume_changed")
		return volume

signal lives_changed(previous: int, value: int)
var lives: int = 3:
	set(_gogo_incoming_lives):
		if is_same(lives, _gogo_incoming_lives): return
		if not preload("../../../addons/estragon/runtime/data/state.tres").can_attach(self, _gogo_incoming_lives): push_error("Cyclic Gogo data assignment"); return
		var _gogo_previous_lives: int = lives
		lives = _gogo_incoming_lives
		if not preload("../../../addons/estragon/runtime/data/state.tres").initializing(self):
			preload("../../../addons/estragon/runtime/data/state.tres").refresh(self)
			lives_changed.emit(_gogo_previous_lives, _gogo_incoming_lives)
			preload("../../../addons/estragon/runtime/data/state.tres").notify(self)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"lives_changed")
		return lives

signal _gogo_data_changed

const _GOGO_DATA_SHAPE_5fae0207052e7967 = true

func to_data():
	return preload("../../../addons/estragon/runtime/data/state.tres").to_data(self)

const _GOGO_DATA_TYPES_5fae0207052e7967 = {"mode": TYPE_STRING,"volume": TYPE_FLOAT,"lives": TYPE_INT,}

const _GOGO_RENDER_FUNCTIONS_5fae0207052e7967 = {
"ordinary": [],
"reactive": []
}
const _GOGO_BINDABLE_PROPERTIES_5fae0207052e7967 = {
"lives": "int",
"mode": "String",
"volume": "float"
}

func _notification(_gogo_what: int) -> void:
	if _gogo_what==NOTIFICATION_PREDELETE: preload("../../../addons/estragon/runtime/data/state.tres").prune()
