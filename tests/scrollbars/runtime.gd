extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var probe=preload("game.gd").new()
	var result=await probe.run(self)
	print("U03_NATIVE_ASSERTIONS ",result.checks," ok=",result.ok)
	if result.ok: print("U03_NATIVE_OK")
	quit(0 if result.ok else 1)
