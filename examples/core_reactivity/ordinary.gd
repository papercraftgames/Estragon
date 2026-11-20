extends RefCounted
var calls := 0
func label(value: String) -> String:
	calls += 1
	return value.to_upper()
func hidden(model) -> String:
	calls += 1
	return model.label
func map(value: String) -> String:
	return label(value)

static func static_label(value: String) -> String:
	return value.to_upper()
