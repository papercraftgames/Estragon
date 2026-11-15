@tool
extends RefCounted
## Shared static/preflight/native validation for the delivered Box policy.
static func registered(script) -> bool:
	while script is Script:
		if script.get_script_constant_map().has("ESTRAGON_STACK_POLICY"): return true
		script = script.get_base_script()
	return false
static func preset(script) -> String:
	while script is Script:
		if script.get_script_constant_map().has("STACK_DIRECTION"): return script.get_script_constant_map().STACK_DIRECTION
		script = script.get_base_script()
	return ""
static func error(name: String, value, direction: String, fixed: String = "") -> String:
	if name=="direction":
		if value not in ["row","column"]: return "direction requires row or column"
		if not fixed.is_empty() and value!=fixed: return "HBox/VBox direction is fixed; use Box to change direction"
	elif name in ["horizontal_align","vertical_align"]:
		if value not in ["start","center","end","stretch"]: return name+" requires start, center, end or cross-axis stretch; distribution is deferred to #161"
		if value=="stretch" and name==("horizontal_align" if direction=="row" else "vertical_align"): return "stretch is cross-axis only; use grow for remaining main-axis space"
	return ""
