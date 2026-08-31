extends Node
## UNDE anume e peretele de umeri pe care il lovesc masinile pe elice, si de la
## ce INALTIME vine? Raza in fata, la mai multe cote peste asfalt.


func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(6)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene) \
		.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var space := track.get_world_3d().direct_space_state
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	for i in n:
		var f := r.frac_at(i)
		if f < 0.799 or f > 0.804:
			continue
		var p: Vector3 = r.baked[i]
		var fwd := (r.baked[(i + 1) % n] - p).normalized()
		print("--- frac %.4f  poz=(%.1f, %.2f, %.1f)" % [f, p.x, p.y, p.z])
		for h in [0.3, 0.6, 1.0, 1.5, 2.0, 3.0]:
			var q := PhysicsRayQueryParameters3D.create(
				p + Vector3.UP * h, p + Vector3.UP * h + fwd * 8.0)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				print("    h=%.1f  liber" % h)
			else:
				var hp: Vector3 = hit["position"]
				print("    h=%.1f  %s la %.2f m, y=%.2f (dy=%+.2f)" % [h,
					String((hit["collider"] as Node).name),
					hp.distance_to(p + Vector3.UP * h), hp.y, hp.y - p.y])
	get_tree().quit(0)
