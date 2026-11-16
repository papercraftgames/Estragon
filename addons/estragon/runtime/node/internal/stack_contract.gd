@tool
extends RefCounted
const DISTRIBUTION := ["space-between","space-around","space-evenly"]
const SELF := ["auto","start","center","end","stretch"]
static func self_registered(script) -> bool:
	while script is Script:
		if script.get_script_constant_map().has("ESTRAGON_ALIGN_SELF_2D"): return true
		script = script.get_base_script()
	return false
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
	if name=="align_self":
		if value not in SELF: return "align_self requires auto, start, center, end or stretch"
	elif name=="direction":
		if value not in ["row","column"]: return "direction requires row or column"
		if not fixed.is_empty() and value!=fixed: return "HBox/VBox direction is fixed; use Box to change direction"
	elif name in ["horizontal_align","vertical_align"]:
		if value not in ["start","center","end","stretch"]+DISTRIBUTION: return name+" requires start, center, end, main-axis space-between/around/evenly or cross-axis stretch"
		if direction in ["row","column"]:
			var main := name==("horizontal_align" if direction=="row" else "vertical_align")
			if main and value=="stretch": return "stretch is cross-axis only; use grow for remaining main-axis space"
			if not main and value in DISTRIBUTION: return name+": space distribution is main-axis only"
	return ""
