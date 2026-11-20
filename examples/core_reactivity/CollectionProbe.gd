extends Resource
## Protocol probe for CORE-01 argument invalidation, not CORE-02 collections.
var value := 0
func change(next: int) -> void:
	if next==value: return
	value = next
	emit_changed()
