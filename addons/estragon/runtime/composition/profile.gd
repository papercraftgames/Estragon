@tool
extends Resource
## Opt-in bounded evidence hook. No application state or per-frame work.
var enabled := false
var counts: Dictionary = {}
var timings: Dictionary = {}
const SAMPLE_LIMIT := 4096
func reset() -> void:
	counts.clear()
	timings.clear()
func add(key: String, amount: int = 1) -> void:
	counts[key] = int(counts.get(key,0))+amount
func elapsed(key: String, start: int) -> void:
	if not timings.has(key): timings[key] = []
	if timings[key].size()<SAMPLE_LIMIT: timings[key].append(Time.get_ticks_usec()-start)
func snapshot() -> Dictionary:
	return {"counts":counts.duplicate(),"timings_us":timings.duplicate(true)}
