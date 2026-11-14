@tool
class_name EstragonPixels
extends RefCounted
## Opt-in ordinary numeric pixel helpers. Read during the child's build_view;
## the existing composition manager observes the parent core's native signal.
const State = preload("state.tres")
const Hosts = preload("../node/internal/composition_hosts.tres")
static func parent_width(context: Node, percent: float) -> float:
	return _parent_pixels(context,percent,0)
static func parent_height(context: Node, percent: float) -> float:
	return _parent_pixels(context,percent,1)
static func _parent_pixels(context: Node, percent: float, axis: int) -> float:
	if not is_finite(percent) or percent < 0:
		push_warning("EstragonPixels requires a finite nonnegative percentage; using 0 pixels")
		return 0.0
	if context == null or context != State.current_host():
		push_warning("EstragonPixels context must be self in the current Gogo build_view; using 0 pixels")
		return 0.0
	var layout = context._get_layout_coordinator() if context.has_method("_get_layout_coordinator") else Hosts.find(context)
	if layout == null or layout._dimension != 2: return 0.0
	State.observe(layout.model,&"parent_changed")
	if layout.scope_root() == null or layout._mode == layout.Mode.ENTRY: return 0.0
	var parent = layout.parent_coordinator()
	# Structural Gogo proxies add no content box; use the containing participant.
	while parent != null and parent._mode == parent.Mode.COMPOSITION:
		State.observe(parent.model,&"parent_changed")
		parent = parent.parent_coordinator()
	if parent == null or parent._mode == parent.Mode.CONTROL: return 0.0
	State.observe(parent.model,&"reference_changed")
	# Unarranged references bootstrap at zero. Intrinsic/auto parent axes stay
	# unavailable instead of repeatedly solving a child/parent fixed point.
	var extent: float = parent.model.content_reference[axis]
	if extent < 0: return 0.0
	var pixels: float = extent * (percent / 100.0)
	if not is_finite(pixels) or not is_finite(Vector2(pixels,0).x):
		push_warning("EstragonPixels result exceeds native finite pixel range; using 0 pixels")
		return 0.0
	return pixels
