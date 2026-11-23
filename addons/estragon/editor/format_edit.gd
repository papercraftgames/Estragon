@tool
extends RefCounted
## Apply only leading-whitespace patches through the native undo history.
static func _column(row: int, column: int, edits: Array) -> int:
	for edit in edits:
		if edit.line==row:
			return column+edit.new.length()-edit.old.length() if column>=edit.old.length() else mini(column,edit.new.length())
	return column
static func apply(code: CodeEdit, report: Dictionary) -> bool:
	if not report.ok or report.edits.is_empty(): return report.ok
	var carets: Array = []
	var positions: Array = []
	for index in range(code.get_caret_count()):
		var row := code.get_caret_line(index)
		var column := _column(row,code.get_caret_column(index),report.edits)
		var point := Vector2i(row,column)
		if positions.has(point): return false # Never silently merge native carets.
		positions.append(point)
		var item := {"row":row,"column":column,"selected":code.has_selection(index)}
		if item.selected:
			var from_row := code.get_selection_from_line(index)
			var from_column := code.get_selection_from_column(index)
			var to_row := code.get_selection_to_line(index)
			var to_column := code.get_selection_to_column(index)
			item.from_row = from_row
			item.from_column = _column(from_row,from_column,report.edits)
			item.to_row = to_row
			item.to_column = _column(to_row,to_column,report.edits)
			item.reverse = row==from_row and code.get_caret_column(index)==from_column
		carets.append(item)
	var vertical := code.scroll_vertical
	var horizontal := code.scroll_horizontal
	code.cancel_code_completion()
	code.begin_complex_operation()
	code.deselect()
	code.remove_secondary_carets()
	for index in range(report.edits.size()-1,-1,-1):
		var edit: Dictionary = report.edits[index]
		if not edit.old.is_empty(): code.remove_text(edit.line,0,edit.line,edit.old.length())
		code.set_caret_line(edit.line,false)
		code.set_caret_column(0,false)
		code.insert_text_at_caret(edit.new,0)
	for index in range(carets.size()):
		var item: Dictionary = carets[index]
		var caret := 0 if index==0 else code.add_caret(item.row,item.column)
		code.set_caret_line(item.row,false,true,0,caret)
		code.set_caret_column(item.column,false,caret)
		if item.selected:
			if item.reverse: code.select(item.to_row,item.to_column,item.from_row,item.from_column,caret)
			else: code.select(item.from_row,item.from_column,item.to_row,item.to_column,caret)
	code.end_complex_operation()
	code.scroll_vertical = vertical
	code.scroll_horizontal = horizontal
	return true
