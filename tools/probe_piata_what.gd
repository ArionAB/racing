extends Node
## Ce este suprafata palida din dreapta parapetilor? Raycast din CAMERA prin
## pixelii cadrului, ca sa numim exact nodurile care ocupa ecranul.
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
	var f := 0.012
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
	print("cam eye=%v target=%v" % [eye, target])
	var vp := get_viewport().get_visible_rect().size
	print("viewport=%v" % vp)
	# esantionam o grila de pixeli in jumatatea dreapta
	for py in [300, 400, 500, 600, 680]:
		var line := "y=%4d:" % py
		for px in [700, 800, 900, 1000, 1100, 1200]:
			var sp := Vector2(float(px) / 1280.0 * vp.x, float(py) / 720.0 * vp.y)
			var from := cam.project_ray_origin(sp)
			var to := from + cam.project_ray_normal(sp) * 400.0
			var q := PhysicsRayQueryParameters3D.create(from, to)
			var h := space.intersect_ray(q)
			if h.is_empty():
				line += "  %d:--" % px
			else:
				var nm := str((h.collider as Node).name)
				var hp: Vector3 = h.position
				var rr := dir.cross(Vector3.UP).normalized()
				var lat: float = (hp - focus).dot(rr)
				line += "  %d:%s y%.0f d%.0f" % [px, nm.substr(0, 10), hp.y, lat]
		print(line)
	get_tree().quit()
