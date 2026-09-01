extends Node
const PATH := "res://assets/models/cappadocia/rocks/cliff_band_module.glb"
func _ready() -> void:
	var inst := (load(PATH) as PackedScene).instantiate()
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		print("  mesh node: '", mi.name, "'")
	get_tree().quit(0)
