extends RefCounted
# Exported bindings belong to this ordinary value instance, never a global registry.
var _GogoLayout_2 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0, Callable(self, "_GogoLayout_2_defaults"), {
"areas": ["upper upper", "lowerLeft lowerRight"],
"columns": 2,
"direction": "grid",
"rows": null,
"template": ""
}, "examples/layouts/Library.gogo:3:22")
var _GogoLayout_4 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0_, Callable(self, "_GogoLayout_4_defaults"), {
"area": "upper"
}, "examples/layouts/Library.gogo:4:6")
var _GogoLayout_6 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0_, Callable(self, "_GogoLayout_6_defaults"), {
"area": "lowerLeft"
}, "examples/layouts/Library.gogo:5:6")
var _GogoLayout_7 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0_, Callable(self, "_GogoLayout_7_defaults"), {
"area": "lowerRight"
}, "examples/layouts/Library.gogo:5:47")


var Shared:
	get: return _GogoLayout_2

var upper:
	get: return _GogoLayout_4

var lowerLeft:
	get: return _GogoLayout_6

var lowerRight:
	get: return _GogoLayout_7

const _GogoLayout_0 = preload("../../../addons/estragon/runtime/node/grid.gd")

const _GogoLayout_0_ = preload("../../../addons/estragon/runtime/node/box.gd")

func _GogoLayout_2_defaults(): return [[["rows", ["1fr","1fr"], "examples/layouts/Library.gogo:3:29"], ["gap", "4px", "examples/layouts/Library.gogo:3:50"], ["padding", "4px", "examples/layouts/Library.gogo:3:60"], ["background_color", "#24364a", "examples/layouts/Library.gogo:3:74"]]]

func _GogoLayout_4_defaults(): return [[["background_color", "#385975", "examples/layouts/Library.gogo:4:12"]], []]

func _GogoLayout_6_defaults(): return [[["background_color", "#49754f", "examples/layouts/Library.gogo:5:16"]]]

func _GogoLayout_7_defaults(): return [[["background_color", "#735f48", "examples/layouts/Library.gogo:5:58"]]]
