extends Node
## Ce e in cadru la fractiile 0.56/0.60/0.64: pozitia camerei, directia, si ce
## noduri de decor cad in frustum, cu distanta. Sondele care masoara LATERAL au
## costat proiectul 8 runde de "sonda verde, poza goala" — asta masoara INAINTE.

const FRACS := [0.56, 0.60, 0.64]


func _ready() -> void:
	await get_tree().process_frame
	var track := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var curve := track.get_node("Path").curve as Curve3D
	var L := curve.get_baked_length()
	var space := track.get_world_3d().direct_space_state
	for f in FRACS:
		var p: Vector3 = curve.sample_baked(L * f)
		var ahead: Vector3 = curve.sample_baked(fmod(L * f + 12.0, L))
		var fwd := (ahead - p).normalized()
		var eye := p + Vector3.UP * 2.2
		print("")
		print("=== frac %.2f: ochi (%.1f, %.1f, %.1f) priveste spre (%.2f, %.2f)"
			% [f, eye.x, eye.y, eye.z, fwd.x, fwd.z])
		# ce e in fata, pe raze, in evantai +-35 grade
		for off in [-35, -20, -8, 0, 8, 20, 35]:
			var d := fwd.rotated(Vector3.UP, deg_to_rad(float(off)))
			var q := PhysicsRayQueryParameters3D.create(eye, eye + d * 300.0)
			var hit := space.intersect_ray(q)
			if hit.has("position"):
				var hp: Vector3 = hit["position"]
				var col: Node = hit["collider"]
				print("   %+3d gr: %6.1f m  cota %6.2f  <- %s"
					% [off, eye.distance_to(hp), hp.y, col.name])
			else:
				print("   %+3d gr: (cer/nimic la 300 m)" % off)
	get_tree().quit()
