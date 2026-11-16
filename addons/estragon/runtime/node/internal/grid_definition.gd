@tool
extends RefCounted
## Pure canonical Grid configuration, template and placement normalization.
## Serializable dictionaries only. Track fractions never enter Length dimensions.
const Length = preload("length.gd")
static func tracks(values) -> Dictionary:
	if values is int:
		if values<1 or values>256: return {"error":"track count must be 1..256"}
		var result: Array = []
		for index in range(values): result.append({"unit":"fr","value":1.0})
		return {"tracks":result}
	if not values is Array or values.is_empty() or values.size()>256: return {"error":"tracks require a nonempty array or count (maximum 256)"}
	var result: Array = []
	for value in values:
		if value is String and value.ends_with("fr"):
			var number: String = value.trim_suffix("fr")
			if not number.is_valid_float() or not is_finite(float(number)) or float(number)<=0 or float(number)>Length.LIMIT: return {"error":"fr track weight must be finite and positive"}
			result.append({"unit":"fr","value":float(number)})
		else:
			var spec := Length.parse(value,"extent")
			if spec.has("error"): return {"error":"invalid track: "+spec.error}
			result.append(spec)
	return {"tracks":result}
static func normalize(columns, rows, areas: Array = [], placements: Array = []) -> Dictionary:
	var cols := tracks(columns)
	if cols.has("error"):
		cols.field = "columns"
		return cols
	var lines := tracks(rows)
	if lines.has("error"):
		lines.field = "rows"
		return lines
	var matrix: Array = []
	var bounds := {}
	if not areas.is_empty() and areas.size()!=lines.tracks.size(): return {"error":"area row count must match row tracks","field":"areas"}
	for row in range(areas.size()):
		if not areas[row] is String: return {"error":"each area row must be a space-separated string","field":"areas"}
		var cells: Array = []
		for cell in areas[row].replace("\t"," ").split(" ",false): cells.append(cell)
		if cells.size()!=cols.tracks.size(): return {"error":"uneven area row or column track count mismatch","field":"areas"}
		matrix.append(cells)
		for col in range(cells.size()):
			var name: String = cells[col]
			if name==".": continue
			if not name.is_valid_identifier(): return {"error":"area names must be identifiers or .","field":"areas"}
			if not bounds.has(name): bounds[name] = {"row":row,"column":col,"row_span":1,"column_span":1}
			var rect: Dictionary = bounds[name]
			rect.row_span = row-rect.row+1
			var end: int = maxi(rect.column+rect.column_span,col+1)
			rect.column = mini(rect.column,col)
			rect.column_span = end-rect.column
	for name in bounds:
		var rect: Dictionary = bounds[name]
		for row in range(rect.row,rect.row+rect.row_span):
			for col in range(rect.column,rect.column+rect.column_span):
				if matrix[row][col]!=name: return {"error":"area '"+name+"' must form one rectangle","field":"areas"}
	var positioned := place(placements,cols.tracks.size(),lines.tracks.size(),bounds,false)
	if positioned.has("error"): return positioned
	return {"columns":cols.tracks,"rows":lines.tracks,"areas":matrix,"bounds":bounds,"placements":positioned.placements}

const PLACEMENT := ["area","row","column","row_span","column_span"]
static func marked(script) -> bool:
	while script is Script:
		if script.get_script_constant_map().get("ESTRAGON_GRID",false): return true
		script = script.get_base_script()
	return false

static func template(value: String) -> Dictionary:
	var columns = null
	var rows: Array = []
	var areas: Array = []
	for raw in value.split("\n"):
		var line: String = raw.strip_edges()
		if line.is_empty(): continue
		if line.begins_with("\\"):
			if columns!=null: return {"error":"template has more than one column declaration"}
			columns = Array(line.substr(1).replace("\t"," ").split(" ",false))
		else:
			var pair := line.split(",")
			if pair.size()>2: return {"error":"template row requires area names, optionally followed by one track"}
			areas.append(pair[0].strip_edges())
			rows.append(pair[1].strip_edges() if pair.size()==2 else "auto")
	if columns==null or areas.is_empty(): return {"error":"template requires area rows and one backslash column declaration"}
	return {"columns":columns,"rows":rows,"areas":areas}

static func resolve(columns = null, rows = null, areas: Array = [], text: String = "", placements: Array = []) -> Dictionary:
	if not text.is_empty():
		if columns!=null or rows!=null or not areas.is_empty(): return {"error":"template conflicts with explicit columns/rows/areas","field":"template"}
		var parsed := template(text)
		if parsed.has("error"):
			parsed.field = "template"
			return parsed
		return resolve(parsed.columns,parsed.rows,parsed.areas,"",placements)
	var cols := tracks(1 if columns==null else columns)
	if cols.has("error"): return cols
	var implicit := rows==null
	var row_values = rows
	if implicit:
		row_values = []
		for index in range(maxi(1,areas.size())): row_values.append("auto")
	var canonical := normalize(columns if columns!=null else 1,row_values,areas,[])
	if canonical.has("error"): return canonical
	var positioned := place(placements,canonical.columns.size(),canonical.rows.size(),canonical.bounds,implicit)
	if positioned.has("error"): return positioned
	while canonical.rows.size()<positioned.row_count: canonical.rows.append({"unit":"auto","value":0.0})
	canonical.placements = positioned.placements
	canonical.implicit_rows = implicit
	return canonical

static func place(values: Array, columns: int, rows: int, bounds: Dictionary, implicit: bool) -> Dictionary:
	var normalized: Array = []
	normalized.resize(values.size())
	var occupied := {}
	var row_count := rows
	for index in range(values.size()):
		var placement = values[index]
		if not placement is Dictionary: return {"error":"placement must be a dictionary","item":index}
		for key in placement:
			if key not in PLACEMENT: return {"error":"unknown placement field: "+str(key),"item":index}
		var rect := {"row":placement.get("row",0),"column":placement.get("column",0),"row_span":placement.get("row_span",1),"column_span":placement.get("column_span",1)}
		if placement.has("area"):
			if placement.size()!=1: return {"error":"area conflicts with explicit row/column placement","item":index}
			if not placement.area is String or not bounds.has(placement.area): return {"error":"unknown placement area: "+str(placement.area),"item":index}
			rect = bounds[placement.area].duplicate()
		for key in rect:
			if not rect[key] is int or rect[key]<(1 if key.ends_with("span") else 0) or rect[key]>256: return {"error":"placement indexes must be nonnegative integers and spans positive (maximum 256)","item":index}
		if rect.column_span>columns: return {"error":"column span exceeds tracks","item":index}
		if placement.has("area") or placement.has("row") or placement.has("column"):
			if rect.column+rect.column_span>columns or rect.row+rect.row_span>256 or not implicit and rect.row+rect.row_span>rows: return {"error":"placement exceeds finite tracks","item":index}
			if not _reserve(rect,occupied): return {"error":"Grid cells overlap","item":index}
			normalized[index] = rect
			row_count = maxi(row_count,rect.row+rect.row_span)
	# All authored cells are reserved before any automatic item is considered.
	for index in range(values.size()):
		if normalized[index]!=null: continue
		var rect := {"row":0,"column":0,"row_span":values[index].get("row_span",1),"column_span":values[index].get("column_span",1)}
		var found := false
		for row in range(256 if implicit else rows):
			if row+rect.row_span>(256 if implicit else rows): break
			rect.row = row
			for col in range(columns-rect.column_span+1):
				rect.column = col
				if _reserve(rect,occupied):
					found = true
					break
			if found: break
		if not found: return {"error":"automatic placement exceeds finite tracks","item":index}
		normalized[index] = rect
		row_count = maxi(row_count,rect.row+rect.row_span)
	return {"placements":normalized,"row_count":row_count}

static func _reserve(rect: Dictionary, occupied: Dictionary) -> bool:
	for row in range(rect.row,rect.row+rect.row_span):
		for col in range(rect.column,rect.column+rect.column_span):
			if occupied.has(Vector2i(col,row)): return false
	for row in range(rect.row,rect.row+rect.row_span):
		for col in range(rect.column,rect.column+rect.column_span): occupied[Vector2i(col,row)] = true
	return true

static func configuration(values: Dictionary, placements: Array = []) -> Dictionary:
	for key in ["horizontal_align","vertical_align"]:
		if values.get(key,"stretch") not in ["start","center","end","stretch"]: return {"error":key+" requires start, center, end or stretch","field":key}
	if not values.get("areas",[]) is Array or not values.get("template","") is String: return {"error":"areas requires Array and template requires String"}
	return resolve(values.get("columns"),values.get("rows"),values.get("areas",[]),values.get("template",""),placements)

static func component(script) -> bool:
	while script is Script:
		for method in script.get_script_method_list():
			if method.name=="build_view": return true
		script = script.get_base_script()
	return false

static func control_error(values: Dictionary) -> String:
	for key in ["anchor_left","anchor_right","anchor_top","anchor_bottom","rotation"]:
		if values.get(key,0)!=0: return "Grid Control requires zero anchors and rotation"
	if values.get("scale",Vector2.ONE)!=Vector2.ONE or values.get("pivot_offset",Vector2.ZERO)!=Vector2.ZERO or values.get("top_level",false): return "Grid Control requires native parent coordinates and an untransformed outer rectangle"
	return ""
