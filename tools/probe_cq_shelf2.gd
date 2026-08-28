extends Node
## Cat de lata e podeaua reala pe felia 0.50-0.63, si la ce cota stau pilele?
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var r := track.routes[0]
	var n := r.count()
	print("frac  | hw  | y_axa | podea de la .. la .. | pila cea mai apropiata")
	var f := 0.500
	while f <= 0.632:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		var side := Vector3(fw.z, 0.0, -fw.x).normalized()
		var lo := 99.0
		var hi := -99.0
		var lat := -16.0
		while lat <= 16.0:
			var p := c + side * lat
			var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 5.0, p + Vector3.DOWN * 4.0)
			var h := space.intersect_ray(q)
			if not h.is_empty() and absf(h["position"].y - c.y) < 2.0:
				lo = minf(lo, lat)
				hi = maxf(hi, lat)
			lat += 0.5
		print("%.3f | %.1f | %5.1f | %+6.1f .. %+6.1f" % [f, track.width_at_index(i), c.y, lo, hi])
		f += 0.006
	get_tree().quit()
