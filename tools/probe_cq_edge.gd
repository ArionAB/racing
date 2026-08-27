extends Node
## Unde se termina PODEAUA lateral, in jurul modulului? Masinile cad la
## frac 0.638-0.646 la y~30 (deck la 31.8). Cautam buza: pe fiecare fractie,
## cat de departe de axa mai exista podea la cota drumului.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var r := track.routes[0]
	var n := r.count()
	print("frac  | hw | podea de la ... la ... (m fata de axa) | cine")
	var f := 0.630
	while f <= 0.672:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		var side := Vector3(fw.z, 0.0, -fw.x).normalized()
		var lo := 0.0
		var hi := 0.0
		var names := {}
		for lat: float in [-14.0, -12.0, -10.0, -8.0, -6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0]:
			var p := c + side * lat
			var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 4.0, p + Vector3.DOWN * 3.0)
			var h := space.intersect_ray(q)
			if not h.is_empty():
				lo = minf(lo, lat)
				hi = maxf(hi, lat)
				names[str(h.collider.name)] = true
		print("%.4f | %.1f | %+6.1f .. %+6.1f | %s" % [
			f, track.width_at_index(i), lo, hi, ", ".join(names.keys())])
		f += 0.002
	get_tree().quit()
