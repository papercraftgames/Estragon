
extends RefCounted
signal text_changed(previous: String, value: String)
var text: String = "Hello":
	set(_gogo_incoming_text):
		if is_same(text, _gogo_incoming_text): return
		var _gogo_previous_text: String = text
		text = _gogo_incoming_text
		text_changed.emit(_gogo_previous_text, _gogo_incoming_text)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"text_changed")
		return text


const _GOGO_RENDER_FUNCTIONS_12f8e8714a7801b6 = {
"ordinary": [],
"reactive": []
}
const _GOGO_BINDABLE_PROPERTIES_12f8e8714a7801b6 = {
"text": "String"
}
