@tool
extends RefCounted
## One finite native Range contract for setters, compiler and desired preflight.
const FIELDS := ["min_value","max_value","step","value"]
const INTEGER_LIMIT := 9007199254740991
static func marked(script) -> bool:
	while script is Script:
		if script.get_script_constant_map().has("ESTRAGON_NUMERIC"): return true
		script = script.get_base_script()
	return false
static func integer(script) -> bool:
	while script is Script:
		if script.get_script_constant_map().has("ESTRAGON_INTEGER"): return true
		script = script.get_base_script()
	return false
static func defaults(integral: bool) -> Dictionary:
	return {"min_value":0,"max_value":100,"step":1,"value":0} if integral else {"min_value":0.0,"max_value":100.0,"step":1.0,"value":0.0}
static func canonical(value: float, low: float, high: float, step: float) -> float:
	var result := clampf(value,low,high)
	if step>0: result = clampf(floor(result/step+0.5)*step,low,high)
	return result
static func configuration(values: Dictionary, integral: bool, strict: bool = true) -> Dictionary:
	var config := defaults(integral)
	for field in FIELDS:
		if values.has(field): config[field] = values[field]
	for field in FIELDS:
		var value = config[field]
		if typeof(value)!=(TYPE_INT if integral else TYPE_FLOAT): return {"field":field,"error":"requires exact "+("int" if integral else "float")+" value"}
		if not is_finite(float(value)): return {"field":field,"error":"requires finite numeric value"}
		if integral and absf(float(value))>INTEGER_LIMIT: return {"field":field,"error":"integer exceeds exact native Range precision (2^53-1)"}
	if config.min_value>config.max_value: return {"field":"min_value","error":"requires min_value <= max_value"}
	if config.step<(1 if integral else 0): return {"field":"step","error":"requires step >= "+("1" if integral else "0")}
	if config.step>0 and (not is_finite(float(config.min_value)/config.step) or not is_finite(float(config.max_value)/config.step)): return {"field":"step","error":"step/range exceeds finite native precision"}
	var normalized := canonical(float(config.value),float(config.min_value),float(config.max_value),float(config.step))
	if not is_finite(normalized): return {"field":"value","error":"canonical value must be finite"}
	var epsilon := maxf(absf(normalized)*2e-15,maxf(float(config.step)*1e-8,1e-300))
	if strict and (config.value<config.min_value or config.value>config.max_value or absf(float(config.value)-normalized)>(0.0 if integral else epsilon)):
		return {"field":"value","error":"source value must already be clamped and step-aligned; assign a canonical model value"}
	config.value = int(normalized) if integral else normalized
	return config
