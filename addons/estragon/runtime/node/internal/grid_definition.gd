@tool
extends RefCounted
## Pure future Grid input normalization, not an executable layout component.
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
	if cols.has("error"): return cols
	var lines := tracks(rows)
	if lines.has("error"): return lines
	var matrix: Array = []
	var bounds := {}
	if not areas.is_empty() and areas.size()!=lines.tracks.size(): return {"error":"area row count must match row tracks"}
	for row in range(areas.size()):
		if not areas[row] is String: return {"error":"each area row must be a space-separated string"}
		var cells: Array = []
		for cell in areas[row].replace("\t"," ").split(" ",false): cells.append(cell)
		if cells.size()!=cols.tracks.size(): return {"error":"uneven area row or column track count mismatch"}
		matrix.append(cells)
		for col in range(cells.size()):
			var name: String = cells[col]
			if name==".": continue
			if not name.is_valid_identifier(): return {"error":"area names must be identifiers or ."}
			if not bounds.has(name): bounds[name] = {"row":row,"column":col,"row_span":1,"column_span":1}
			var rect: Dictionary = bounds[name]
			rect.row_span = row-rect.row+1
			rect.column_span = maxi(rect.column_span,col-rect.column+1)
	for name in bounds:
		var rect: Dictionary = bounds[name]
		for row in range(rect.row,rect.row+rect.row_span):
			for col in range(rect.column,rect.column+rect.column_span):
				if matrix[row][col]!=name: return {"error":"area '"+name+"' must form one rectangle"}
	var normalized: Array = []
	var occupied := {}
	for placement in placements:
		if not placement is Dictionary: return {"error":"placement must be a dictionary"}
		var rect: Dictionary
		if placement.has("area"):
			if placement.size()!=1: return {"error":"area conflicts with explicit row/column placement"}
			if not bounds.has(placement.area): return {"error":"unknown placement area: "+str(placement.area)}
			rect = bounds[placement.area].duplicate()
		else:
			for key in placement:
				if key not in ["row","column","row_span","column_span"]: return {"error":"unknown placement field: "+str(key)}
			rect = {"row":placement.get("row",0),"column":placement.get("column",0),"row_span":placement.get("row_span",1),"column_span":placement.get("column_span",1)}
			for key in rect:
				if not rect[key] is int or rect[key]<(1 if key.ends_with("span") else 0): return {"error":"placement indices must be nonnegative integers and spans positive"}
		if rect.row+rect.row_span>lines.tracks.size() or rect.column+rect.column_span>cols.tracks.size(): return {"error":"placement exceeds track bounds"}
		for row in range(rect.row,rect.row+rect.row_span):
			for col in range(rect.column,rect.column+rect.column_span):
				var key := str(row)+":"+str(col)
				if occupied.has(key): return {"error":"duplicate/conflicting child placement at "+key}
				occupied[key] = true
		normalized.append(rect)
	return {"columns":cols.tracks,"rows":lines.tracks,"areas":matrix,"bounds":bounds,"placements":normalized}
