extends Node
## Cat de lat e canionul si unde urca malul de pe partea vaii (stanga).
## Fara asta, peretele din stanga s-ar aseza pe fundul rapei, sub nivelul
## drumului — adica invizibil din masina.

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	for fi in [43, 46, 49, 52]:
		var f := float(fi) / 100.0
		var idx := int(f * float(n)) % n
		var p: Vector3 = pts[idx]
		var ahead: Vector3 = pts[(idx + 10) % n]
		var d := (ahead - p); d.y = 0.0; d = d.normalized()
		var side := Vector3(d.z, 0.0, -d.x)
		var line := "frac %.2f road_y %.1f | STANGA:" % [f, p.y]
		for lat in [12, 16, 20, 25, 30, 35, 45, 55, 70]:
			var q: Vector3 = p - side * float(lat)
			line += " %d:%.1f" % [lat, track._sampler.ground_y(q.x, q.z)]
		print(line)
		var l2 := "                          DREAPTA:"
		for lat in [12, 16, 20, 25, 30, 35, 45, 55, 70]:
			var q2: Vector3 = p + side * float(lat)
			l2 += " %d:%.1f" % [lat, track._sampler.ground_y(q2.x, q2.z)]
		print(l2)
	get_tree().quit(0)
