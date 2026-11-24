extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var probe=preload("game.gd").new()
	var result=await probe.run(self)
	if result.ok: print("U03_NATIVE_OK checks=",result.checks)
	quit(0 if result.ok else 1)
