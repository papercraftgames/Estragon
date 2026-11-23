
extends RefCounted
signal flag_changed(previous: bool, value: bool)
var flag: bool = false:
	set(_gogo_incoming_flag):
		if is_same(flag, _gogo_incoming_flag): return
		var _gogo_previous_flag: bool = flag
		flag = _gogo_incoming_flag
		flag_changed.emit(_gogo_previous_flag, _gogo_incoming_flag)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"flag_changed")
		return flag

signal label_changed(previous: String, value: String)
var label: String = "Observable Bool model":
	set(_gogo_incoming_label):
		if is_same(label, _gogo_incoming_label): return
		var _gogo_previous_label: String = label
		label = _gogo_incoming_label
		label_changed.emit(_gogo_previous_label, _gogo_incoming_label)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"label_changed")
		return label


const _GOGO_RENDER_FUNCTIONS_2080aff64a4f5acd = {
"ordinary": [],
"reactive": []
}
const _GOGO_BINDABLE_PROPERTIES_2080aff64a4f5acd = {
"flag": "bool",
"label": "String"
}
