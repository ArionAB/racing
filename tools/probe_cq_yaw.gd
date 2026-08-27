extends Node
## Sanity: punctul de la frac 0.655 si vecinii lui, in coordonate LUME si in
## spatiul nodului asa cum e scris in .tscn. Daca modulul e bine asezat,
## soseaua trebuie sa treaca prin x_local ~ 0 pe zeci de metri.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 8:
		await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var span := track.find_child("PasajRotativ", false, false)
	print("n=%d  nod la %s" % [n, span.global_position])
	var i := int(round(0.655 * float(n))) % n
	print("index ancora %d, baked=%s" % [i, r.baked[i]])
	var inv := span.global_transform.affine_inverse()
	print(" k |  baked (lume)                | local (x,y,z)")
	for k in range(-24, 25, 2):
		var idx := ((i + k) % n + n) % n
		var w: Vector3 = r.baked[idx]
		var l: Vector3 = inv * w
		print("%+3d | (%8.2f,%7.2f,%8.2f) | (%7.2f,%6.2f,%8.2f)" % [k, w.x, w.y, w.z, l.x, l.y, l.z])
	get_tree().quit()
