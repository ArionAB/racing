extends Node
## Se VEDE golul? Trag raze din ochiul camerei prin coloana de pixeli din
## dreapta si raportez, pentru fiecare, cat de jos ajunge prima lovitura.
## Daca razele care ar trebui sa cada in rapa lovesc parapetul sau un turn la
## cota drumului, jucatorul nu vede caderea — indiferent cate turnuri exista.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var c: Curve3D = (track.get_node("Path") as Path3D).curve
	var L := c.get_baked_length()
	for f in [0.005, 0.012, 0.020, 0.030]:
		var p := c.sample_baked(f * L)
		var p2 := c.sample_baked(fmod(f * L + 3.0, L))
		var fwd := (p2 - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		var eye: Vector3 = p - fwd * 12.5 + Vector3.UP * 10.0
		var jos := 0
		var sus := 0
		var tot := 0
		# evantai spre dreapta-jos, ca o coloana de pixeli din cadru
		for a in range(6, 40, 2):
			for dd in [20.0, 35.0, 55.0, 80.0]:
				var dir: Vector3 = (right * cos(deg_to_rad(float(a)))
					- Vector3.UP * sin(deg_to_rad(float(a)))).normalized()
				var q := PhysicsRayQueryParameters3D.create(eye, eye + dir * dd)
				q.collide_with_areas = false
				var h := space.intersect_ray(q)
				if h.is_empty():
					continue
				tot += 1
				if h.position.y < p.y - 8.0:
					jos += 1
				else:
					sus += 1
		print("frac=%.3f  lovituri_jos(<sosea-8)=%d  lovituri_la_cota=%d  total=%d  %s"
			% [f, jos, sus, tot,
				("golul se vede" if jos >= sus else "GOLUL E ASTUPAT")])
	get_tree().quit()
