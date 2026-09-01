extends Node3D
## La ce RAND de pixeli incepe departarea. Nu mai ghicesc banda: o caut.
## Pe coloane din tot cadrul, cobor randul de la orizont in jos si raportez
## distanta pana la teren. Vreau randul unde distanta trece de 60 m.

const FRACS := [0.56, 0.60, 0.64]


func _ready() -> void:
	await get_tree().process_frame
	var track := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var cam := Camera3D.new()
	add_child(cam)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 68.0
	cam.far = 400.0
	cam.current = true
	var vp := get_viewport().get_visible_rect().size
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var space := get_world_3d().direct_space_state

	for f in FRACS:
		var idx := int(f * float(n)) % n
		var focus: Vector3 = pts[idx]
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir := (ahead - focus).normalized()
		cam.global_position = focus - dir * 7.5 + Vector3.UP * 3.2
		cam.look_at(focus + Vector3.UP * 1.2, Vector3.UP)
		await get_tree().process_frame
		print("")
		print("=== frac %.2f (randuri ca fractie din inaltimea cadrului) ===" % f)
		for colf in [0.08, 0.25, 0.5, 0.75, 0.92]:
			var line := "  col %.2f: " % colf
			for rowf in [0.20, 0.26, 0.30, 0.33, 0.36, 0.38, 0.40, 0.41]:
				var sp := Vector2(vp.x * colf, vp.y * rowf)
				var from := cam.project_ray_origin(sp)
				var rd := cam.project_ray_normal(sp)
				var q := PhysicsRayQueryParameters3D.create(from, from + rd * 350.0)
				var hit := space.intersect_ray(q)
				if hit.has("position"):
					var d: float = cam.global_position.distance_to(hit["position"])
					line += "%5.0f " % d
				else:
					line += "  cer "
			print(line)
		print("           (rand: 0.20 0.26 0.30 0.33 0.36 0.38 0.40 0.41)")
	get_tree().quit()
