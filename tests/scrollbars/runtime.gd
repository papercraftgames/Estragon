extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var result=await preload("game.gd").new().run(self)
	if result.ok: print("U03_NATIVE_OK checks=",result.checks)
	quit(0 if result.ok else 1)
