extends RefCounted
func run(host):
	var select_probe=preload("select_game.gd").new()
	var selection=await select_probe.run(host)
	var numeric_probe=preload("numeric_game.gd").new()
	var numeric=await numeric_probe.run(host)
	return {"ok":selection.ok and numeric.ok,"checks":selection.checks+numeric.checks}
