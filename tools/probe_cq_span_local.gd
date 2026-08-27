extends Node
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame
	var haz := track.get_node_or_null("PasajRotativ") as Node3D
	var inv := haz.global_transform.affine_inverse()
	print("nod la %s" % haz.global_position)
	for p in [Vector3(131,6,191), Vector3(132,6,190), Vector3(58,8,196), Vector3(60,8,204)]:
		print("  lume %s -> local %s" % [p, inv * p])
	var r := track.routes[0]
	var n := r.count()
	# cota soselei si a tablierului la fiecare 10 m local Z
	print("localZ | sosea y | tablier y | rampa y")
	for lz in range(-72, 73, 6):
		var w := haz.global_transform * Vector3(0, 0, float(lz))
		var best := INF; var by := 0.0
		for j in n:
			var d := Vector2(r.baked[j].x - w.x, r.baked[j].z - w.z).length()
			if d < best: best = d; by = r.baked[j].y
		print("%6d | %7.2f | dist axa %.1f" % [lz, by, best])
	get_tree().quit()
