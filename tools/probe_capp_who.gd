extends Node
## CINE e aripa portocalie din captura larga? Tipareste, pentru fiecare panza de
## faleza, AABB-ul global si cota lui de sus/jos — ca sa se vada care sta cu
## coama PESTE cota drumului (43.8 la frac 0.20) si cat de subtire e.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	var root := _track.find_child("CliffFaces", true, false)
	if root == null:
		print("nu exista CliffFaces")
		get_tree().quit(0)
		return
	for ch in root.get_children():
		var mi := ch as MeshInstance3D
		if mi == null:
			continue
		var ab := mi.get_aabb()
		var o := mi.global_transform * ab.position
		var e := ab.size
		print("%-34s  y %7.1f .. %7.1f   x %7.1f..%7.1f  z %7.1f..%7.1f"
			% [mi.name, o.y, o.y + e.y, o.x, o.x + e.x, o.z, o.z + e.z])
	get_tree().quit(0)
