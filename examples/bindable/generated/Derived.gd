extends "Model.gd"
signal enabled_changed(previous: bool, value: bool)
var enabled: bool = true:
    set(_gogo_incoming_enabled):
        if is_same(enabled, _gogo_incoming_enabled): return
        var _gogo_previous_enabled: bool = enabled
        enabled = _gogo_incoming_enabled
        enabled_changed.emit(_gogo_previous_enabled, _gogo_incoming_enabled)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"enabled_changed")
        return enabled

func rename() -> void:
    title = "Derived"

const _GOGO_RENDER_FUNCTIONS_c956da5b693e401d = {
"ordinary": ["rename"],
"reactive": []
}
const _GOGO_BINDABLE_PROPERTIES_c956da5b693e401d = {
"enabled": "bool"
}
