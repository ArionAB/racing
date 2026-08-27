extends Node
## Harta malului prin RAZE (adevarul fizic), nu prin ground_y: pe partea
## rapei sampler-ul da o cota, dar colizor nu exista si piesa pluteste.
## Tiparim, pentru fiecare fractie si distanta, cota LOVITA sau "---".
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
	print("frac  | road_y | dy la 10/13/16 m STANGA | dy la 10/13/16 m DREAPTA  ('---' = gol)")
	var f := 0.595
	while f <= 0.832:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		var side := Vector3(fw.z, 0.0, -fw.x).normalized()
		var line := "%.3f | %6.2f |" % [f, c.y]
		for sgn: float in [-1.0, 1.0]:
			for d: float in [10.0, 13.0, 16.0]:
				var p := c + side * d * sgn
				var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 3.0, p + Vector3.DOWN * 8.0)
				var h := space.intersect_ray(q)
				line += ("  %+5.1f" % (h.position.y - c.y)) if not h.is_empty() else "   ----"
			line += " |"
		print(line)
		f += 0.004
	get_tree().quit()
