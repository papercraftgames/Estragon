extends "Model.gd"
signal enabled_changed(previous: bool, value: bool)
var enabled: bool = true:
    set(_gogo_incoming_enabled):
        if is_same(enabled, _gogo_incoming_enabled): return
        var _gogo_previous_enabled: bool = enabled
        enabled = _gogo_incoming_enabled
        enabled_changed.emit(_gogo_previous_enabled, _gogo_incoming_enabled)

func rename() -> void:
    title = "Derived"

