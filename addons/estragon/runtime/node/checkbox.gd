@tool
class_name EstragonCheckbox
extends "toggle.gd"
## Square/checkmark and label on the shared observable Bool/focus/input path.
func _init() -> void:
	super._init()
	background_color = "transparent"
func _square_size() -> float:
	return maxf(16.0,float(font_size))
func _measure_native() -> Vector2:
	var label := _measure_label() if not text.is_empty() else Vector2.ZERO
	return Vector2(_square_size()+(8.0+label.x if not text.is_empty() else 0.0),maxf(_square_size(),label.y))
func get_label_origin() -> Vector2:
	var content := get_content_rect()
	return content.position+Vector2(_square_size()+8.0,maxf(0.0,(content.size.y-_measure_label().y)*0.5))
func get_background_color() -> Color:
	# Checkbox is distinct from Toggle's checked full-surface fill/underline.
	if disabled: return _visual_style.colors.disabled_background_color
	if _held and _hovered or _keyboard_held: return _visual_style.colors.pressed_background_color
	return _visual_style.colors.hover_background_color if _hovered else _visual_style.colors.background_color
func _draw() -> void:
	var content := get_content_rect()
	if content.size.x<=0 or content.size.y<=0: return
	var side := minf(_square_size(),minf(content.size.x,content.size.y))
	var square := Rect2(content.position+Vector2(0,maxf(0,(content.size.y-side)*0.5)),Vector2(side,side))
	var tint := Color(1,1,1,0.5) if disabled else Color.WHITE
	draw_rect(square,_visual_style.colors.disabled_background_color if disabled else _visual_style.colors.checked_background_color if value else Color("#252525"))
	draw_rect(square,Color("#c5d4df")*tint,false,1.5)
	if value and side>=8:
		draw_polyline(PackedVector2Array([square.position+Vector2(side*0.2,side*0.52),square.position+Vector2(side*0.43,side*0.76),square.position+Vector2(side*0.82,side*0.25)]),tint,2.0,true)
	_draw_label(get_label_origin(),tint)
	if has_focus() and layout_size.x>4 and layout_size.y>4:
		draw_rect(Rect2(Vector2(2,2),layout_size-Vector2(4,4)),Color("#9cdcff"),false,2)
