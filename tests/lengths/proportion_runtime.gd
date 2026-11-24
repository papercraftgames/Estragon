extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var probe=preload("proportion_game.gd").new()
 var result=await probe.run(self)
 quit(0 if result.ok else 1)
