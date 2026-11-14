@tool
extends RefCounted
## Sole length grammar, property domains, conversion and dependency contract.
## Numeric values preserve native units; explicit pixel/reference strings use
## pixels_per_unit in 3D. Percent always uses an immediate layout content axis.
const LIMIT := 1.0e12
const FACTORS := {"":1.0,"px":1.0,"in":96.0,"cm":96.0/2.54,"mm":96.0/25.4,"q":96.0/101.6,"pt":96.0/72.0,"pc":16.0}
const DIMENSIONS := ["width","height","depth"]
const OFFSETS := ["x","y","z"]
const EDGES := ["padding","padding_top","padding_right","padding_bottom","padding_left","margin","margin_top","margin_right","margin_bottom","margin_left"]
var specs: Dictionary = {}
var parse_count := 0
static func domain(name: String) -> String:
	if name in DIMENSIONS: return "extent"
	if name in OFFSETS: return "offset"
	if name in EDGES: return "edge" if name.contains("_") else "inset"
	return "inset" if name=="gap" else ""
static func registered(type, name: String) -> bool:
	if domain(name).is_empty() or not type is Script: return false
	while type != null:
		# A declared native bridge marker avoids loading either adapter here.
		if type.get_script_constant_map().get("ESTRAGON_LENGTHS",false): return true
		type = type.get_base_script()
	return false
static func parse(value, kind: String) -> Dictionary:
	if typeof(value) in [TYPE_INT,TYPE_FLOAT]:
		var number := float(value)
		if not is_finite(number) or absf(number)>LIMIT or number<0 and kind!="offset": return {"error":"Expected a finite nonnegative length (negative offsets are allowed)"}
		return {"unit":"native","value":number}
	if not value is String: return {"error":"Length requires int, float or a unit string"}
	var text: String = value.strip_edges()
	if text=="auto":
		return {"unit":"auto","value":0.0} if kind in ["extent","edge"] else {"error":"auto is only valid for dimensions and unset inset edges"}
	# This is a scalar value grammar, never a mixed Gogo/GGX syntax parser.
	var matcher := RegEx.new()
	matcher.compile("^([+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?)(px|%|vw|vh|vmin|vmax|in|cm|mm|q|pt|pc)?$")
	var found := matcher.search(text)
	if found==null: return {"error":"Invalid length: use a number, px, %, vw/vh/vmin/vmax, in/cm/mm/q/pt/pc or eligible auto; font units and calc are unsupported"}
	var number := float(found.get_string(1))
	var unit := found.get_string(2)
	if not is_finite(number) or absf(number)>LIMIT or number<0 and kind!="offset": return {"error":"Length is negative, nonfinite or outside the supported range"}
	if FACTORS.has(unit) and absf(number*FACTORS[unit])>LIMIT: return {"error":"Converted length exceeds supported range"}
	return {"unit":unit,"value":number}
static func valid(value, kind: String) -> bool:
	return not parse(value,kind).has("error")
func assign(name: String, value) -> bool:
	var parsed := parse(value,domain(name))
	parse_count += 1
	if parsed.has("error"):
		push_error("Estragon length '"+name+"': "+parsed.error)
		return false
	specs[name] = parsed
	return true
static func resolve(spec: Dictionary, reference: float, viewport: Vector2, pixels_per_unit: float = 1.0) -> float:
	var unit: String = spec.unit
	var value: float = spec.value
	if unit=="auto": return -1.0
	if unit=="native": return clampf(value/pixels_per_unit,-LIMIT,LIMIT)
	if unit=="%": return clampf(value*maxf(0,reference)/100.0,-LIMIT,LIMIT)
	var pixels: float
	match unit:
		"vw": pixels = viewport.x*value/100.0
		"vh": pixels = viewport.y*value/100.0
		"vmin": pixels = minf(viewport.x,viewport.y)*value/100.0
		"vmax": pixels = maxf(viewport.x,viewport.y)*value/100.0
		_: pixels = value*FACTORS[unit]
	return clampf(pixels/pixels_per_unit,-LIMIT,LIMIT)
static func dependencies(specs: Dictionary, stack_axis: int) -> Array:
	var parent_axes := Vector3.ZERO
	var viewport_axes := Vector2.ZERO
	for name in specs:
		var unit: String = specs[name].unit
		if unit=="%":
			if name in ["width","x","margin_left","margin_right","padding_left","padding_right"]: parent_axes.x = 1
			elif name in ["height","y","margin_top","margin_bottom","padding_top","padding_bottom"]: parent_axes.y = 1
			elif name in ["depth","z"]: parent_axes.z = 1
			elif name=="gap": parent_axes[stack_axis] = 1
			else: parent_axes = Vector3(1,1,parent_axes.z)
		elif unit=="vw": viewport_axes.x = 1
		elif unit=="vh": viewport_axes.y = 1
		elif unit in ["vmin","vmax"]: viewport_axes = Vector2.ONE
	return [parent_axes,viewport_axes]
static func properties(names: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for name in names: result.append({"name":name,"type":TYPE_NIL,"usage":PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_NIL_IS_VARIANT})
	return result
