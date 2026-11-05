extends RefCounted
const State = preload("res://examples/reactive/generated/State.gd")
signal player_changed(previous: State, value: State)
var player: State = State.new():
	set(_gogo_incoming_player):
		if is_same(player, _gogo_incoming_player): return
		var _gogo_previous_player: State = player
		player = _gogo_incoming_player
		player_changed.emit(_gogo_previous_player, _gogo_incoming_player)
	get:
		preload("res://addons/estragon/runtime/composition/state.tres").observe(self, &"player_changed")
		return player


