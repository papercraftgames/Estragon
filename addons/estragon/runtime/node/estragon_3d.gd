@tool
class_name Estragon3D
extends "component_3d.gd"
## Explicit independent layout scope; does not assign native scene owner.
func _is_layout_entry() -> bool:
	return true
