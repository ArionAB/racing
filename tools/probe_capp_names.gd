extends Node
const PATHS := ["res://assets/models/rocks/rock_medium.glb", "res://assets/models/rocks/rock_small.glb"]
func _ready() -> void:
	for pth in PATHS:
		var inst := (load(pth) as PackedScene).instantiate()
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			print("  ", pth.get_file(), " mesh node: '", mi.name, "'")
	get_tree().quit(0)
