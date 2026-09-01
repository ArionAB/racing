extends Node
## Cat spatiu LIBER ramane pe carosabil dupa ce s-au pus peretii. Nu se
## socoteste pe hartie: se plimba un raycast la inaltimea masinii, din ax spre
## fiecare parte, si se raporteaza prima izbitura.

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	for i in 8:
		await get_tree().process_frame
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var space := track.get_world_3d().direct_space_state
	print("frac   hw   liber_stanga  liber_dreapta   (m de la ax, la 0.8 m inaltime)")
	var f := 0.428
	while f < 0.536:
		var idx := int(f * float(n)) % n
		var p: Vector3 = pts[idx]
		var ahead: Vector3 = pts[(idx + 10) % n]
		var d := (ahead - p); d.y = 0.0; d = d.normalized()
		var sv := Vector3(d.z, 0.0, -d.x)
		var hw_pre: float = track.width_at(f)
		var origin := p + Vector3.UP * 0.8
		var res := []
		for sgn in [1.0, -1.0]:
			var q := PhysicsRayQueryParameters3D.create(origin, origin + sv * sgn * 30.0)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				res.append(30.0)
			else:
				res.append(origin.distance_to(hit["position"]))
				if origin.distance_to(hit["position"]) < hw_pre + 0.6:
					var col = hit.get("collider")
					print("      izbeste: ", col.get_parent().name if col != null and col.get_parent() != null else "?", " / ", col.name if col != null else "?")
		var hw: float = track.width_at(f)
		var flag := "  <-- STRAMT" if minf(res[0], res[1]) < hw + 0.6 else ""
		print("%.3f  %.1f   %8.1f      %8.1f%s" % [f, hw, res[0], res[1], flag])
		f += 0.004
	get_tree().quit(0)
