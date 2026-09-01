extends Node3D
## CE e masa rosie care ocupa 19.2% din cadrul de la 0.56 cu o deviatie de
## luminanta de doar 11.8/255 (adica plata). Trag raze prin pixelii ei si
## raportez ce lovesc — nu ghicesc din nume de noduri.


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
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var idx := int(0.56 * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	cam.global_position = focus - dir * 7.5 + Vector3.UP * 3.2
	cam.look_at(focus + Vector3.UP * 1.2, Vector3.UP)
	await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	var space := get_world_3d().direct_space_state
	var tally := {}
	for gx in range(18, 30):
		for gy in range(1, 12):
			var sp := Vector2(vp.x * float(gx) / 30.0, vp.y * float(gy) / 28.0)
			var from := cam.project_ray_origin(sp)
			var rd := cam.project_ray_normal(sp)
			var q := PhysicsRayQueryParameters3D.create(from, from + rd * 400.0)
			var hit := space.intersect_ray(q)
			if not hit.has("position"):
				continue
			var nm := String((hit["collider"] as Node).name)
			var d: float = cam.global_position.distance_to(hit["position"])
			if not tally.has(nm):
				tally[nm] = [0, 1e9, 0.0]
			tally[nm][0] += 1
			tally[nm][1] = minf(tally[nm][1], d)
			tally[nm][2] = maxf(tally[nm][2], d)
	print("")
	print("=== ce e in treimea dreapta-sus la 0.56 ===")
	for k in tally:
		print("  %-24s raze %3d   %6.1f .. %6.1f m" % [k, tally[k][0], tally[k][1], tally[k][2]])
	get_tree().quit()
