extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Spacer = preload("../../../addons/estragon/runtime/node/spacer.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const Settings = preload("StyledSettings.gd")
const Rose = preload("StyledRose.gd")
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0(
		(1),
		(1),
		(Color("#ffcc66")),
		(1)
	)

const _GOGO_RENDER_FUNCTIONS_c7c09c729be4bdf0 = {
"ordinary": [],
"reactive": ["build_view"]
}

const _GogoProject_0 = preload("StyledSettings.gd")

const _GogoProject_1 = preload("StyledRose.gd")

func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(
		_gogo_value_0: float,
		_gogo_value_1: int,
		_gogo_value_2: Color,
		_gogo_value_3: float
	) -> _GogoElement_0:
		var _gogo_element_3 := _GogoElement_0.new(Text, {"name": "Title", "text": "Shared native styling", "color": _gogo_value_2}, {}, [], "examples/styling/StyleGallery.gogo:18:5", null, false)
		_gogo_element_3.resolve_bindings()
		var _gogo_element_2 := _GogoElement_0.new(HBox, {"name": "Header", "width": "50%", "padding": "8px", "background_color": "#45506b", "border_color": "#ffcc66", "border_width": "1px"}, {}, [_gogo_element_3], "examples/styling/StyleGallery.gogo:16:4", null, false)
		_gogo_element_2.resolve_bindings()
		var _gogo_element_4 := _GogoElement_0.new(Spacer, {"name": "Space", "grow": _gogo_value_3}, {}, [], "examples/styling/StyleGallery.gogo:20:4", null, false)
		_gogo_element_4.resolve_bindings()
		var _gogo_element_5 := _GogoElement_0.new(Text, {"name": "Plain", "text": "Local default Text stays white."}, {}, [], "examples/styling/StyleGallery.gogo:21:4", null, false)
		_gogo_element_5.resolve_bindings()
		var _gogo_element_6 := _GogoElement_0.new(_GogoProject_0, {"name": "Settings"}, {}, [], "examples/styling/StyleGallery.gogo:22:4", null, false)
		_gogo_element_6.resolve_bindings()
		var _gogo_element_7 := _GogoElement_0.new(_GogoProject_1, {"name": "Rose"}, {}, [], "examples/styling/StyleGallery.gogo:23:4", null, false)
		_gogo_element_7.resolve_bindings()
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Panel", "grow": _gogo_value_0, "stretch": _gogo_value_1, "margin": "8px", "padding": "16px", "padding_top": "24px", "padding_right": "20px", "padding_bottom": "12px", "gap": "12px", "background_color": "#252b38", "border_color": "#8295bc", "border_width": "2px", "border_left_width": "3px", "border_right_width": "4px", "border_bottom_width": "5px"}, {}, [_gogo_element_2, _gogo_element_4, _gogo_element_5, _gogo_element_6, _gogo_element_7], "examples/styling/StyleGallery.gogo:12:3", null, false)
		_gogo_element_1.resolve_bindings()
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "width": "100%", "height": "100%", "padding": "8px", "background_color": "#171b24"}, {}, [_gogo_element_1], "examples/styling/StyleGallery.gogo:11:9", null, false)
		_gogo_element_0.resolve_bindings()
		return _gogo_element_0
