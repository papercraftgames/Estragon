extends SceneTree
const Proof = preload("res://addons/estragon/compiler/node_proof/compiler.gd")
const Publisher = preload("res://examples/node_proof/build.gd")
const TYPES := {
	"Entry2D": preload("res://addons/estragon/layout_proof/entry_2d.gd"),
	"Entry3D": preload("res://addons/estragon/layout_proof/entry_3d.gd"),
}
const INPUT := "res://examples/layout_proof/.proof/Layout.gogo"
const OUTPUT := "res://examples/layout_proof/generated/Layout.gd"
static func build() -> Dictionary:
	return Publisher.publish(Proof.compile(FileAccess.get_file_as_string(INPUT), INPUT, TYPES), OUTPUT)

func _initialize() -> void:
	var result := build()
	if not result.ok:
		printerr(result)
		quit(1)
	else:
		print("GGX_B2_BUILD_OK")
		quit()
