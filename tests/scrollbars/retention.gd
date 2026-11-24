extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var probe=preload("retention_game.gd").new()
	var result=await probe.run(self)
	print("U03_RETAIN_ASSERTIONS ",result.checks," ok=",result.ok)
	if result.ok: print("U03_RETAIN_OK")
	quit(0 if result.ok else 1)
