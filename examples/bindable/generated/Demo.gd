extends Node
const Model = preload("res://examples/bindable/generated/Derived.gd")
var model: RefCounted
var events: Array = []
func _ready() -> void:
    model = Model.new()
    var initial: int = model.count
    model.count_changed.connect(on_count_changed)
    model.increment()
    model.count += 1
    print("Bindable model initial=",initial," final=",model.count," observed=",events)
    if OS.get_environment("ESTRAGON_BINDABLE_PROOF") == "1":
        var file := FileAccess.open("res://.godot/bindable-play.json",FileAccess.WRITE)
        file.store_string(JSON.stringify({"initial":initial,"count":model.count,"events":events}))
func on_count_changed(previous: int, value: int) -> void:
    events.append([previous,value])

