@tool
extends RefCounted
## Shared GGX pixel domain, used before native description commits as well as
## by static validation. Ordinary native properties keep their own contracts.
const Participant = preload("../component_2d.gd")
const Box = preload("../box.gd")
static func _derives(type, base: Script) -> bool:
	if not type is Script: return false
	while type != null:
		if type == base: return true
		type = type.get_base_script()
	return false
static func kind(type, name: String) -> String:
	if not _derives(type,Participant): return ""
	if name in ["width","height"]: return "length"
	if name == "gap" or name in ["margin","margin_top","margin_right","margin_bottom","margin_left"]: return "inset"
	if name in ["padding","padding_top","padding_right","padding_bottom","padding_left"] and _derives(type,Box): return "inset"
	return ""
static func valid(value, domain: String) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and (value >= 0 or domain == "length" and value == -1)
