@tool
extends "res://addons/estragon/runtime/node/box.gd"
## A foreground override must not suppress the shared native draw signal hook.
func _draw() -> void:
	if layout_size.x>4 and layout_size.y>4: draw_rect(Rect2(2,2,2,2),Color.RED)
