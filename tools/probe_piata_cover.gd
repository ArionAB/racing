extends Node
## Cat din ecran ocupa ACOPERISUL blocurilor si cat FATADA? Raycast pe o grila
## deasa prin cadru, clasificand dupa normala suprafetei lovite.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var route := track.route_at(0)
	var pts: PackedVector3Array = route.baked
	var n := pts.size()
	for f: float in [0.005, 0.012, 0.020]:
		var idx: int = int(f * float(n)) % n
		var focus: Vector3 = pts[idx]
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir := (ahead - focus).normalized()
		var eye: Vector3 = focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
		var target: Vector3 = focus + dir * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT
		var cam := Camera3D.new()
		add_child(cam)
		cam.fov = ChaseCamera.BASE_FOV
		cam.far = 400.0
		cam.global_position = eye
		cam.look_at(target, Vector3.UP)
		await get_tree().process_frame
		var vp := get_viewport().get_visible_rect().size
		var roof := 0
		var facade := 0
		var total := 0
		for iy in range(0, 72):
			for ix in range(0, 128):
				var sp := Vector2(float(ix) / 128.0 * vp.x, float(iy) / 72.0 * vp.y)
				var from := cam.project_ray_origin(sp)
				var to := from + cam.project_ray_normal(sp) * 400.0
				var q := PhysicsRayQueryParameters3D.create(from, to)
				var h := space.intersect_ray(q)
				total += 1
				if h.is_empty(): continue
				# numele colliderului e generat de world_prop; urcam in arbore
				# pana gasim (sau nu) nodul blocului
				var a: Node = h.collider as Node
				var found := false
				while a != null:
					if str(a.name).begins_with("bloc_sub_piata"):
						found = true
						break
					a = a.get_parent()
				if not found: continue
				var nrm: Vector3 = h.normal
				if absf(nrm.y) > 0.7: roof += 1
				else: facade += 1
		print("frac %.3f: pixeli bloc = acoperis %d, fatada %d (din %d esantioane)"
			% [f, roof, facade, total])
		cam.queue_free()
	get_tree().quit()
